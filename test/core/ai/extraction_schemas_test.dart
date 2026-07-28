import 'package:dukasmart/core/ai/extraction_schemas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptExtraction', () {
    ReceiptExtraction parse(Map<String, Object?> input) =>
        ReceiptExtraction.spec.parse(input);

    test('golden parse: full receipt with every field populated', () {
      final result = parse({
        'items': [
          {
            'name': 'Sugar 2kg',
            'quantity': 3,
            'unit': 'packet',
            'unit_price_cents': 25000,
            'line_total_cents': 75000,
          },
        ],
        'receipt_total_cents': 75000,
        'supplier_name': 'Highland Wholesalers',
        'date': '2026-07-20',
      });

      expect(result.items, hasLength(1));
      expect(result.items.single.name, 'Sugar 2kg');
      expect(result.items.single.quantity, 3);
      expect(result.items.single.unit, 'packet');
      expect(result.items.single.unitPriceCents, 25000);
      expect(result.items.single.lineTotalCents, 75000);
      expect(result.receiptTotalCents, 75000);
      expect(result.supplierName, 'Highland Wholesalers');
      expect(result.date, '2026-07-20');
      expect(result.skippedRows, 0);
      expect(result.truncated, false);
    });

    test('integral doubles are coerced via .toInt()', () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 2.0, 'unit_price_cents': 1200.0},
        ],
        'receipt_total_cents': 2400.0,
      });

      expect(result.items.single.quantity, 2);
      expect(result.items.single.unitPriceCents, 1200);
      expect(result.receiptTotalCents, 2400);
    });

    test('zero quantity drops the row', () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 0},
          {'name': 'Sugar', 'quantity': 1},
        ],
      });

      expect(result.items, hasLength(1));
      expect(result.items.single.name, 'Sugar');
      expect(result.skippedRows, 1);
    });

    test('a bad date becomes null, row/receipt otherwise unaffected', () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 1},
        ],
        'date': '20-07-2026',
      });

      expect(result.date, isNull);
    });

    test('a 5-digit year is rejected even though DateTime.parse accepts it',
        () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 1},
        ],
        'date': '12345-01-01',
      });

      expect(result.date, isNull);
    });

    test('a valid calendar date round-trips unchanged', () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 1},
        ],
        'date': '2026-07-27',
      });

      expect(result.date, '2026-07-27');
    });

    test('a well-formed but nonexistent calendar date becomes null', () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 1},
        ],
        'date': '2026-02-31',
      });

      expect(result.date, isNull);
    });

    test('caps items at 50 and sets truncated', () {
      final result = parse({
        'items': [
          for (var i = 0; i < 55; i++) {'name': 'Item $i', 'quantity': 1},
        ],
      });

      expect(result.items, hasLength(50));
      expect(result.truncated, true);
    });

    test('missing top-level items throws FormatException', () {
      expect(() => parse({'receipt_total_cents': 100}),
          throwsFormatException);
    });

    test('non-list top-level items throws FormatException', () {
      expect(() => parse({'items': 'not a list'}), throwsFormatException);
    });

    test('non-integral, negative, and wrong-type receipt_total_cents -> null',
        () {
      expect(
        parse({
          'items': [
            {'name': 'Rice', 'quantity': 1},
          ],
          'receipt_total_cents': 100.5,
        }).receiptTotalCents,
        isNull,
      );
      expect(
        parse({
          'items': [
            {'name': 'Rice', 'quantity': 1},
          ],
          'receipt_total_cents': -100,
        }).receiptTotalCents,
        isNull,
      );
      expect(
        parse({
          'items': [
            {'name': 'Rice', 'quantity': 1},
          ],
          'receipt_total_cents': '100',
        }).receiptTotalCents,
        isNull,
      );
    });

    test('non-string and blank supplier_name -> null', () {
      expect(
        parse({
          'items': [
            {'name': 'Rice', 'quantity': 1},
          ],
          'supplier_name': 42,
        }).supplierName,
        isNull,
      );
      expect(
        parse({
          'items': [
            {'name': 'Rice', 'quantity': 1},
          ],
          'supplier_name': '   ',
        }).supplierName,
        isNull,
      );
    });

    test('unknown top-level key is ignored silently', () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 1},
        ],
        'currency': 'KES',
      });

      expect(result.items, hasLength(1));
    });

    test('wrong-type optional item field -> that field null, row survives',
        () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 1, 'unit': 42},
        ],
      });

      expect(result.items, hasLength(1));
      expect(result.items.single.unit, isNull);
    });

    test('negative optional item price -> field null, row survives', () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 1, 'unit_price_cents': -100},
        ],
      });

      expect(result.items, hasLength(1));
      expect(result.items.single.unitPriceCents, isNull);
    });

    test('non-integral optional item price -> field null, row survives', () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 1, 'unit_price_cents': 150.5},
        ],
      });

      expect(result.items, hasLength(1));
      expect(result.items.single.unitPriceCents, isNull);
    });

    test('string optional item price -> field null, row survives', () {
      final result = parse({
        'items': [
          {'name': 'Rice', 'quantity': 1, 'unit_price_cents': '150'},
        ],
      });

      expect(result.items, hasLength(1));
      expect(result.items.single.unitPriceCents, isNull);
    });
  });

  group('NotebookPage', () {
    NotebookPage parse(Map<String, Object?> input) =>
        NotebookPage.spec.parse(input);

    test('golden parse: full product with every field populated', () {
      final result = parse({
        'products': [
          {
            'name': 'Cooking oil 1L',
            'unit': 'bottle',
            'selling_price_cents': 35000,
            'buying_price_cents': 28000,
          },
        ],
      });

      expect(result.products, hasLength(1));
      expect(result.products.single.name, 'Cooking oil 1L');
      expect(result.products.single.unit, ProductUnit.bottle);
      expect(result.products.single.sellingPriceCents, 35000);
      expect(result.products.single.buyingPriceCents, 28000);
      expect(result.skippedRows, 0);
      expect(result.truncated, false);
    });

    test('missing required name drops the row', () {
      final result = parse({
        'products': [
          {'unit': 'piece'},
          {'name': 'Sugar'},
        ],
      });

      expect(result.products, hasLength(1));
      expect(result.products.single.name, 'Sugar');
      expect(result.skippedRows, 1);
    });

    test('unknown unit string -> null', () {
      final result = parse({
        'products': [
          {'name': 'Sugar', 'unit': 'sack'},
        ],
      });

      expect(result.products.single.unit, isNull);
    });

    test('caps products at 60 and sets truncated', () {
      final result = parse({
        'products': [
          for (var i = 0; i < 65; i++) {'name': 'Product $i'},
        ],
      });

      expect(result.products, hasLength(60));
      expect(result.truncated, true);
    });

    test('missing top-level products throws FormatException', () {
      expect(() => parse({}), throwsFormatException);
    });

    test('negative optional product price -> field null, row survives', () {
      final result = parse({
        'products': [
          {'name': 'Sugar', 'selling_price_cents': -100},
        ],
      });

      expect(result.products.single.sellingPriceCents, isNull);
    });

    test('non-integral optional product price -> field null, row survives',
        () {
      final result = parse({
        'products': [
          {'name': 'Sugar', 'selling_price_cents': 150.5},
        ],
      });

      expect(result.products.single.sellingPriceCents, isNull);
    });

    test('string optional product price -> field null, row survives', () {
      final result = parse({
        'products': [
          {'name': 'Sugar', 'selling_price_cents': '150'},
        ],
      });

      expect(result.products.single.sellingPriceCents, isNull);
    });
  });
}
