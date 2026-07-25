import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../core/database/database.dart';
import '../../core/database/enums.dart';
import '../../core/database/errors.dart';
import '../../core/providers.dart';
import '../../core/widgets/barcode_field.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/numeric_input_field.dart';
import '../../core/widgets/primary_button.dart';
import 'image_storage/image_storage.dart';

/// Pure helper (testable): profit per unit in cents, or `null` when either
/// price is unset (requirements #4: "Show profit/unit = selling − buying").
int? computeProfitPerUnitCents({required int? buyingPriceCents, required int? sellingPriceCents}) {
  if (buyingPriceCents == null || sellingPriceCents == null) return null;
  return sellingPriceCents - buyingPriceCents;
}

/// Add Product (route `/products/add`).
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '5');

  ProductUnit _unit = ProductUnit.piece;
  String? _imagePath;
  bool _submitting = false;

  String? _nameError;
  String? _barcodeError;
  String? _buyingPriceError;
  String? _sellingPriceError;
  String? _quantityError;
  String? _thresholdError;

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final path = await pickAndStoreProductImage();
    if (path == null) return;
    setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    if (_submitting) return;

    final name = _nameController.text.trim();
    final barcode = _barcodeController.text.trim();

    int? buyingPrice;
    int? sellingPrice;
    int? quantity;
    int? threshold;

    setState(() {
      _nameError = name.isEmpty ? 'Name is required' : null;

      _buyingPriceError = null;
      buyingPrice = null;
      if (_buyingPriceController.text.trim().isNotEmpty) {
        buyingPrice = NumericInputField.parseValue(_buyingPriceController.text, NumericInputMode.money);
        if (buyingPrice == null) _buyingPriceError = 'Enter a valid amount';
      }

      _sellingPriceError = null;
      sellingPrice = null;
      if (_sellingPriceController.text.trim().isNotEmpty) {
        sellingPrice = NumericInputField.parseValue(_sellingPriceController.text, NumericInputMode.money);
        if (sellingPrice == null) _sellingPriceError = 'Enter a valid amount';
      }

      final qtyText = _quantityController.text.trim().isEmpty ? '0' : _quantityController.text;
      quantity = NumericInputField.parseValue(qtyText, NumericInputMode.quantity);
      _quantityError = quantity == null ? 'Enter a whole number of 0 or more' : null;

      final thresholdText = _thresholdController.text.trim().isEmpty ? '5' : _thresholdController.text;
      threshold = NumericInputField.parseValue(thresholdText, NumericInputMode.quantity);
      _thresholdError = threshold == null ? 'Enter a whole number of 0 or more' : null;
    });

    if (_nameError != null ||
        _buyingPriceError != null ||
        _sellingPriceError != null ||
        _quantityError != null ||
        _thresholdError != null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final companion = ProductsCompanion.insert(
        name: name,
        barcode: Value(barcode.isEmpty ? null : barcode),
        imagePath: Value(_imagePath),
        buyingPrice: Value(buyingPrice),
        sellingPrice: Value(sellingPrice),
        unit: _unit,
        lowStockThreshold: Value(threshold!),
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(productsDaoProvider).createProduct(companion, openingQty: quantity!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name added')));
      context.pop();
    } on DukaError catch (e) {
      if (e.message.toLowerCase().contains('barcode')) {
        setState(() => _barcodeError = e.message);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profit = computeProfitPerUnitCents(
      buyingPriceCents: NumericInputField.parseValue(_buyingPriceController.text, NumericInputMode.money),
      sellingPriceCents: NumericInputField.parseValue(_sellingPriceController.text, NumericInputMode.money),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name', errorText: _nameError),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          BarcodeField(controller: _barcodeController, label: 'Barcode (optional)'),
          if (_barcodeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                _barcodeError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          if (!kIsWeb)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _imagePath == null ? 'No image selected' : 'Image: ${p.basename(_imagePath!)}',
                  ),
                ),
                TextButton(
                  onPressed: _pickImage,
                  child: Text(_imagePath == null ? 'Add Image' : 'Change'),
                ),
                if (_imagePath != null)
                  TextButton(
                    onPressed: () => setState(() => _imagePath = null),
                    child: const Text('Remove'),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          NumericInputField.money(
            label: 'Buying price (optional)',
            controller: _buyingPriceController,
            errorText: _buyingPriceError,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          NumericInputField.money(
            label: 'Selling price (optional)',
            controller: _sellingPriceController,
            errorText: _sellingPriceError,
            onChanged: (_) => setState(() {}),
          ),
          if (profit != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Profit per unit: '),
                if (profit < 0) const Text('-'),
                MoneyText(profit.abs()),
              ],
            ),
          ],
          const SizedBox(height: 12),
          NumericInputField.quantity(
            label: 'Opening stock',
            controller: _quantityController,
            errorText: _quantityError,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ProductUnit>(
            initialValue: _unit,
            decoration: const InputDecoration(labelText: 'Unit'),
            items: ProductUnit.values
                .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _unit = value);
            },
          ),
          const SizedBox(height: 12),
          NumericInputField.quantity(
            label: 'Low-stock threshold',
            controller: _thresholdController,
            errorText: _thresholdError,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Save',
                  loading: _submitting,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
