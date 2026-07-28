import 'ai_gateway.dart';

/// Units offered on the notebook-catalog extraction schema. Receipt line
/// items instead carry a free-text `unit` string (whatever a supplier
/// receipt prints), so this enum is notebook-only.
enum ProductUnit {
  piece,
  packet,
  bottle,
  kilogram,
  litre,
  crate,
  carton,
  tray,
  other,
}

class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.quantity,
    this.unit,
    this.unitPriceCents,
    this.lineTotalCents,
  });

  final String name;
  final int quantity;
  final String? unit;
  final int? unitPriceCents;
  final int? lineTotalCents;
}

class ReceiptExtraction {
  const ReceiptExtraction({
    required this.items,
    required this.skippedRows,
    required this.truncated,
    this.receiptTotalCents,
    this.supplierName,
    this.date,
  });

  final List<ReceiptItem> items;
  final int? receiptTotalCents;
  final String? supplierName;

  /// Strict `YYYY-MM-DD`, or null if the model's value didn't round-trip.
  final String? date;

  /// Rows dropped because a required field (`name`/`quantity`) was invalid.
  final int skippedRows;

  /// True when the model returned more than [maxItems] items and the tail
  /// was dropped.
  final bool truncated;

  static const int maxItems = 50;

  static final ExtractionSpec<ReceiptExtraction> spec =
      ExtractionSpec<ReceiptExtraction>(
    toolName: 'record_receipt',
    description: 'Record every line item visible on a supplier receipt '
        'photo, plus the receipt total, supplier name, and date if '
        'legible. Money values are integer cents. Omit lines you cannot '
        'read rather than guessing.',
    inputSchema: const {
      'type': 'object',
      'required': ['items'],
      'properties': {
        'items': {
          'type': 'array',
          'items': {
            'type': 'object',
            'required': ['name', 'quantity'],
            'properties': {
              'name': {'type': 'string'},
              'quantity': {'type': 'integer'},
              'unit': {'type': 'string'},
              'unit_price_cents': {'type': 'integer'},
              'line_total_cents': {'type': 'integer'},
            },
          },
        },
        'receipt_total_cents': {'type': 'integer'},
        'supplier_name': {'type': 'string'},
        'date': {'type': 'string', 'description': 'YYYY-MM-DD'},
      },
    },
    parse: _parseReceipt,
  );
}

class NotebookProduct {
  const NotebookProduct({
    required this.name,
    this.unit,
    this.sellingPriceCents,
    this.buyingPriceCents,
  });

  final String name;
  final ProductUnit? unit;
  final int? sellingPriceCents;
  final int? buyingPriceCents;
}

class NotebookPage {
  const NotebookPage({
    required this.products,
    required this.skippedRows,
    required this.truncated,
  });

  final List<NotebookProduct> products;

  /// Rows dropped because the required `name` field was invalid.
  final int skippedRows;

  /// True when the model returned more than [maxProducts] products and
  /// the tail was dropped.
  final bool truncated;

  static const int maxProducts = 60;

  static final ExtractionSpec<NotebookPage> spec = ExtractionSpec<NotebookPage>(
    toolName: 'record_notebook_page',
    description: 'Record every product visible on a handwritten notebook '
        'catalog page, with unit and prices where legible. Money values '
        'are integer cents. Omit lines you cannot read rather than '
        'guessing.',
    inputSchema: const {
      'type': 'object',
      'required': ['products'],
      'properties': {
        'products': {
          'type': 'array',
          'items': {
            'type': 'object',
            'required': ['name'],
            'properties': {
              'name': {'type': 'string'},
              'unit': {
                'type': 'string',
                'enum': [
                  'piece',
                  'packet',
                  'bottle',
                  'kilogram',
                  'litre',
                  'crate',
                  'carton',
                  'tray',
                  'other',
                ],
              },
              'selling_price_cents': {'type': 'integer'},
              'buying_price_cents': {'type': 'integer'},
            },
          },
        },
      },
    },
    parse: _parseNotebookPage,
  );
}

ReceiptExtraction _parseReceipt(Map<String, Object?> input) {
  final rawItems = input['items'];
  if (rawItems is! List) {
    throw const FormatException('items missing or not a list');
  }

  var items = rawItems;
  var truncated = false;
  if (items.length > ReceiptExtraction.maxItems) {
    items = items.sublist(0, ReceiptExtraction.maxItems);
    truncated = true;
  }

  var skippedRows = 0;
  final parsed = <ReceiptItem>[];
  for (final raw in items) {
    if (raw is! Map) {
      skippedRows++;
      continue;
    }
    final name = _requiredString(raw['name']);
    final quantity = _coercePositiveInt(raw['quantity']);
    if (name == null || quantity == null) {
      skippedRows++;
      continue;
    }
    parsed.add(ReceiptItem(
      name: name,
      quantity: quantity,
      unit: _optionalString(raw['unit']),
      unitPriceCents: _optionalNonNegativeInt(raw['unit_price_cents']),
      lineTotalCents: _optionalNonNegativeInt(raw['line_total_cents']),
    ));
  }

  return ReceiptExtraction(
    items: parsed,
    skippedRows: skippedRows,
    truncated: truncated,
    receiptTotalCents: _optionalNonNegativeInt(input['receipt_total_cents']),
    supplierName: _optionalString(input['supplier_name']),
    date: _optionalDate(input['date']),
  );
}

NotebookPage _parseNotebookPage(Map<String, Object?> input) {
  final rawProducts = input['products'];
  if (rawProducts is! List) {
    throw const FormatException('products missing or not a list');
  }

  var products = rawProducts;
  var truncated = false;
  if (products.length > NotebookPage.maxProducts) {
    products = products.sublist(0, NotebookPage.maxProducts);
    truncated = true;
  }

  var skippedRows = 0;
  final parsed = <NotebookProduct>[];
  for (final raw in products) {
    if (raw is! Map) {
      skippedRows++;
      continue;
    }
    final name = _requiredString(raw['name']);
    if (name == null) {
      skippedRows++;
      continue;
    }
    parsed.add(NotebookProduct(
      name: name,
      unit: _optionalUnit(raw['unit']),
      sellingPriceCents: _optionalNonNegativeInt(raw['selling_price_cents']),
      buyingPriceCents: _optionalNonNegativeInt(raw['buying_price_cents']),
    ));
  }

  return NotebookPage(
    products: parsed,
    skippedRows: skippedRows,
    truncated: truncated,
  );
}

/// Accepts `int` and integral `double` (models genuinely emit `1200.0` for
/// integer schema fields; the coercion is lossless). Rejects non-integral
/// doubles and every other type.
int? _coerceInt(Object? v) {
  if (v is int) return v;
  if (v is double && v.isFinite && v == v.roundToDouble()) return v.toInt();
  return null;
}

int? _coercePositiveInt(Object? v) {
  final n = _coerceInt(v);
  if (n == null || n <= 0) return null;
  return n;
}

int? _optionalNonNegativeInt(Object? v) {
  final n = _coerceInt(v);
  if (n == null || n < 0) return null;
  return n;
}

String? _requiredString(Object? v) {
  if (v is! String) return null;
  final trimmed = v.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _optionalString(Object? v) {
  if (v is! String) return null;
  final trimmed = v.trim();
  return trimmed.isEmpty ? null : trimmed;
}

final RegExp _isoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

String? _optionalDate(Object? v) {
  if (v is! String) return null;
  if (!_isoDatePattern.hasMatch(v)) return null;
  try {
    final parsed = DateTime.parse(v);
    final year = parsed.year.toString().padLeft(4, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '$year-$month-$day' == v ? v : null;
  } catch (_) {
    return null;
  }
}

ProductUnit? _optionalUnit(Object? v) {
  if (v is! String) return null;
  for (final unit in ProductUnit.values) {
    if (unit.name == v) return unit;
  }
  return null;
}
