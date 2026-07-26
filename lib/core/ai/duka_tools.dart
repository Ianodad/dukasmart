import 'dart:convert';

import '../database/day_bounds.dart';
import 'ai_query_service.dart';
import 'projection_service.dart';

/// The 6 read-only tools the model may call (spec: "the AI can never
/// write to the database"). Definitions follow the Anthropic Messages
/// API tool shape: name, description, input_schema (JSON Schema).
///
/// Descriptions are prescriptive about WHEN to call each tool, and tool
/// results carry pre-formatted `*_display` KES strings the model is told
/// to quote verbatim.
class DukaToolDispatcher {
  DukaToolDispatcher(this._queries);

  final AiQueryService _queries;

  static const List<Map<String, Object?>> toolDefinitions = [
    {
      'name': 'get_sales_summary',
      'description':
          'Call this for questions about sales totals, revenue, or the cash '
              'vs M-PESA split over a date range. Returns totals in cents plus '
              'pre-formatted KES display strings.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Start date, local, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'End date inclusive, local, YYYY-MM-DD'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': 'get_top_products',
      'description':
          'Call this for questions about best or worst selling products over '
              'a date range. Returns products ranked by quantity sold with '
              'revenue.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Start date, local, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'End date inclusive, local, YYYY-MM-DD'},
          'limit': {'type': 'integer', 'description': 'Max products to return (default 5)'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': 'get_expenses',
      'description':
          'Call this for questions about spending or expenses over a date '
              'range. Returns the total plus two breakdowns: by category '
              '(Stock transport, Stock purchase, Electricity, Airtime, Food, '
              'Rent, Repairs, Personal withdrawal, Other) and by reason (the '
              'free-text note recorded with each expense, or "Unspecified" '
              'when none was given). Always aggregated totals and counts — '
              'never individual expense rows.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Start date, local, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'End date inclusive, local, YYYY-MM-DD'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': 'get_stock_levels',
      'description':
          'Call this for questions about current stock, what is running low, '
              'or what is out of stock. Set low_only=true to return only '
              'low/out-of-stock products.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'low_only': {
            'type': 'boolean',
            'description': 'Return only low/out-of-stock products (default false)',
          },
        },
        'required': <String>[],
      },
    },
    {
      'name': 'get_daily_closes',
      'description':
          'Call this for questions about past closed days: daily totals, net '
              'results, or cash differences (drawer short/over).',
      'input_schema': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Start date, local, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'End date inclusive, local, YYYY-MM-DD'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': 'get_projections',
      'description':
          'Call this for questions about the future: when a product will run '
              'out of stock, or the projected cash flow for the next 7 days. '
              'Figures are computed locally by the app, not estimated by you.',
      'input_schema': {
        'type': 'object',
        'properties': <String, Object?>{},
        'required': <String>[],
      },
    },
  ];

  /// Executes [name] and returns a JSON string for the tool_result block.
  /// Never throws on bad model input — returns `{"error": ...}` instead
  /// so the model can correct itself on the next round.
  Future<String> execute(String name, Map<String, Object?> input) async {
    try {
      switch (name) {
        case 'get_sales_summary':
          final range = _dateRange(input);
          return jsonEncode(
              await _queries.salesSummary(range.from, range.to));
        case 'get_top_products':
          final range = _dateRange(input);
          final limit = (_intOrNull(input, 'limit') ?? 5).clamp(1, 20);
          return jsonEncode(await _queries.topProducts(
              range.from, range.to,
              limit: limit));
        case 'get_expenses':
          final range = _dateRange(input);
          return jsonEncode(
              await _queries.expensesSummary(range.from, range.to));
        case 'get_stock_levels':
          return jsonEncode(
              await _queries.stockLevels(lowOnly: _boolOrNull(input, 'low_only') ?? false));
        case 'get_daily_closes':
          final range = _dateRange(input);
          return jsonEncode(
              await _queries.dailyCloses(range.from, range.to));
        case 'get_projections':
          final now = DateTime.now();
          final velocities = await _queries.productVelocities(asOf: now);
          final net30 = await _queries.netCentsBetween(
              now.subtract(const Duration(days: 29)), now);
          // Clamp the averaging window to actual history — same principle
          // as snapshot_builder.dart's cash-flow projection: a shop with
          // only a few days of data shouldn't have its real net divided
          // by a fixed 30, which would silently under-estimate the
          // avg/projected figures the AI narrates back to the shopkeeper.
          final earliestActivity =
              await _queries.earliestActivityBetween(null, now);
          final daysOfData = earliestActivity == null
              ? 0
              : (localMidnight(now)
                          .difference(localMidnight(earliestActivity))
                          .inDays +
                      1)
                  .clamp(1, 30);
          return jsonEncode({
            'stock_projections': [
              for (final p in projectStockRunOut(velocities)) p.toJson(),
            ],
            'cash_flow': projectCashFlow(
                    netCentsInWindow: net30, daysOfData: daysOfData)
                .toJson(),
          });
        default:
          return jsonEncode({'error': 'Unknown tool: $name'});
      }
    } on FormatException catch (e) {
      return jsonEncode({'error': e.message});
    }
  }

  /// Reads an optional integer input. Model tool calls sometimes emit
  /// numbers as JSON strings despite an integer schema — accept those too.
  /// Never throws a raw TypeError; bad shapes become FormatException so
  /// they're caught by [execute]'s error handling, same as [_date].
  /// Non-integer numbers (e.g. `2.5`) are rejected — silently truncating
  /// them would hide a malformed model call.
  static int? _intOrNull(Map<String, Object?> input, String key) {
    final raw = input[key];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) {
      if (raw != raw.truncateToDouble()) {
        throw FormatException('Invalid "$key" (expected integer, got "$raw").');
      }
      return raw.toInt();
    }
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid "$key" (expected integer, got "$raw").');
  }

  /// Reads an optional boolean input. Rejects any non-bool shape (numbers,
  /// strings like "true", null-ish sentinels) rather than silently
  /// coercing — a truthy-looking string must not be treated as false.
  static bool? _boolOrNull(Map<String, Object?> input, String key) {
    final raw = input[key];
    if (raw == null) return null;
    if (raw is bool) return raw;
    throw FormatException('Invalid "$key" (expected boolean, got "$raw").');
  }

  static final RegExp _strictDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Parses a strict `YYYY-MM-DD` date. Rejects anything that doesn't
  /// match the pattern exactly, and anything that parses but doesn't
  /// round-trip back to the same string (e.g. "2024-02-30" is normalized
  /// by [DateTime.parse] to March 2 — that's a silent corruption, not a
  /// valid date, from the model's point of view).
  static DateTime _date(Map<String, Object?> input, String key) {
    final raw = input[key];
    if (raw is! String) {
      throw FormatException('Missing or non-string "$key" (expected YYYY-MM-DD).');
    }
    if (!_strictDatePattern.hasMatch(raw)) {
      throw FormatException('Invalid "$key" date "$raw" (expected YYYY-MM-DD).');
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('Invalid "$key" date "$raw" (expected YYYY-MM-DD).');
    }
    final roundTrip = '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    if (roundTrip != raw) {
      throw FormatException('Invalid "$key" date "$raw" (expected YYYY-MM-DD).');
    }
    return parsed;
  }

  /// Parses `from`/`to` together and rejects an inverted range
  /// (`from > to`) as a single error, instead of letting each tool query
  /// silently run on a nonsensical window.
  static ({DateTime from, DateTime to}) _dateRange(Map<String, Object?> input) {
    final from = _date(input, 'from');
    final to = _date(input, 'to');
    if (from.isAfter(to)) {
      throw FormatException(
          'Invalid range: "from" (${input['from']}) is after "to" (${input['to']}).');
    }
    return (from: from, to: to);
  }
}
