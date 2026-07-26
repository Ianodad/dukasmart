import 'dart:convert';

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
              'range. Returns the total plus a per-category breakdown '
              '(categories: Stock transport, Stock purchase, Electricity, '
              'Airtime, Food, Rent, Repairs, Personal withdrawal, Other).',
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
          return jsonEncode(
              await _queries.salesSummary(_date(input, 'from'), _date(input, 'to')));
        case 'get_top_products':
          final limit = (_intOrNull(input, 'limit') ?? 5).clamp(1, 20);
          return jsonEncode(await _queries.topProducts(
              _date(input, 'from'), _date(input, 'to'),
              limit: limit));
        case 'get_expenses':
          return jsonEncode(await _queries.expensesSummary(
              _date(input, 'from'), _date(input, 'to')));
        case 'get_stock_levels':
          return jsonEncode(
              await _queries.stockLevels(lowOnly: input['low_only'] == true));
        case 'get_daily_closes':
          return jsonEncode(await _queries.dailyCloses(
              _date(input, 'from'), _date(input, 'to')));
        case 'get_projections':
          final now = DateTime.now();
          final velocities = await _queries.productVelocities(asOf: now);
          final net30 = await _queries.netCentsBetween(
              now.subtract(const Duration(days: 29)), now);
          return jsonEncode({
            'stock_projections': [
              for (final p in projectStockRunOut(velocities)) p.toJson(),
            ],
            'cash_flow':
                projectCashFlow(netCentsInWindow: net30, daysOfData: 30).toJson(),
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
  static int? _intOrNull(Map<String, Object?> input, String key) {
    final raw = input[key];
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid "$key" (expected integer, got "$raw").');
  }

  static DateTime _date(Map<String, Object?> input, String key) {
    final raw = input[key];
    if (raw is! String) {
      throw FormatException('Missing or non-string "$key" (expected YYYY-MM-DD).');
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('Invalid "$key" date "$raw" (expected YYYY-MM-DD).');
    }
    return parsed;
  }
}
