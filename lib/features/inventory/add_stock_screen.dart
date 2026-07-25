import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/providers.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/numeric_input_field.dart';
import '../../core/widgets/primary_button.dart';

/// Renders integer cents as an editable KES string ("5500" -> "55",
/// "5550" -> "55.50") without ever going through double math (design
/// D2) — used only to prefill [NumericInputField.money]'s controller, as
/// its own doc comment suggests for this exact screen.
String centsToInputString(int cents) {
  final shillings = cents ~/ 100;
  final remainder = cents % 100;
  if (remainder == 0) return '$shillings';
  return '$shillings.${remainder.toString().padLeft(2, '0')}';
}

/// Prefill for the "Amount paid from till" field (Amendment A1): `qty ×
/// price`, preferring the entered buying price over the product's current
/// buying price. Returns `null` when there's nothing sensible to prefill
/// (no known price, or a non-positive quantity) — the field then starts
/// empty and the user must enter an amount themselves.
int? computeTillPrefillCents(
  int qty,
  int? enteredBuyingPriceCents,
  int? productBuyingPriceCents,
) {
  if (qty <= 0) return null;
  final price = enteredBuyingPriceCents ?? productBuyingPriceCents;
  if (price == null) return null;
  return qty * price;
}

/// Add Stock (route `/home/add-stock`).
class AddStockScreen extends ConsumerStatefulWidget {
  const AddStockScreen({super.key, this.productId});

  /// Optional preselected product id, passed via `extra`.
  final int? productId;

  @override
  ConsumerState<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends ConsumerState<AddStockScreen> {
  int? _selectedProductId;
  int? _priceInitializedForProductId;
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final _tillCashOutController = TextEditingController();

  bool _submitting = false;
  bool _paidFromTill = false;
  String? _qtyError;
  String? _priceError;
  String? _tillCashOutError;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.productId;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _tillCashOutController.dispose();
    super.dispose();
  }

  Product? _findSelected(List<Product> products) {
    for (final product in products) {
      if (product.id == _selectedProductId) return product;
    }
    return null;
  }

  Future<void> _submit(Product product) async {
    if (_submitting) return;

    final qty = NumericInputField.parseValue(_qtyController.text, NumericInputMode.quantity);
    final priceText = _priceController.text.trim();
    int? newPrice;
    if (priceText.isNotEmpty) {
      newPrice = NumericInputField.parseValue(priceText, NumericInputMode.money);
    }

    int? tillCashOutCents;
    if (_paidFromTill) {
      final tillText = _tillCashOutController.text.trim();
      tillCashOutCents = tillText.isEmpty
          ? null
          : NumericInputField.parseValue(tillText, NumericInputMode.money);
    }

    setState(() {
      _qtyError = (qty == null || qty <= 0) ? 'Enter a quantity greater than zero' : null;
      _priceError = (priceText.isNotEmpty && newPrice == null) ? 'Enter a valid amount' : null;
      _tillCashOutError = _paidFromTill && (tillCashOutCents == null || tillCashOutCents <= 0)
          ? 'Enter an amount greater than zero'
          : null;
    });
    if (_qtyError != null || _priceError != null || _tillCashOutError != null) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Confirm Stock Receipt',
      message: 'Add $qty ${product.unit.label} to "${product.name}"?'
          '${newPrice != null ? '\nNew buying price: ${centsToInputString(newPrice)} KES' : ''}'
          '${_paidFromTill ? '\nPaid from till: ${centsToInputString(tillCashOutCents!)} KES' : ''}'
          '${_noteController.text.trim().isNotEmpty ? '\nNote: ${_noteController.text.trim()}' : ''}',
    );
    if (!confirmed) return;

    setState(() => _submitting = true);
    try {
      await ref.read(stockDaoProvider).receiveStock(
            productId: product.id,
            qty: qty!,
            newBuyingPriceCents: newPrice,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            tillCashOutCents: tillCashOutCents,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock updated for ${product.name}')),
      );
      context.pop();
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
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Stock')),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const EmptyState(title: 'No products yet. Add a product first.');
          }

          final selected = _findSelected(products);
          if (selected != null && _priceInitializedForProductId != selected.id) {
            _priceController.text =
                selected.buyingPrice != null ? centsToInputString(selected.buyingPrice!) : '';
            _priceInitializedForProductId = selected.id;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<int>(
                initialValue: _selectedProductId,
                decoration: const InputDecoration(labelText: 'Product'),
                items: products
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProductId = value;
                    _priceInitializedForProductId = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              NumericInputField.quantity(
                label: 'Quantity received',
                controller: _qtyController,
                errorText: _qtyError,
              ),
              const SizedBox(height: 12),
              NumericInputField.money(
                label: 'Latest buying price (optional)',
                controller: _priceController,
                errorText: _priceError,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Paid from till (cash)'),
                value: _paidFromTill,
                onChanged: (value) {
                  setState(() {
                    _paidFromTill = value;
                    if (value) {
                      final qty = NumericInputField.parseValue(
                        _qtyController.text,
                        NumericInputMode.quantity,
                      );
                      final enteredPrice = NumericInputField.parseValue(
                        _priceController.text,
                        NumericInputMode.money,
                      );
                      final prefill = computeTillPrefillCents(
                        qty ?? 0,
                        enteredPrice,
                        selected?.buyingPrice,
                      );
                      _tillCashOutController.text =
                          prefill != null ? centsToInputString(prefill) : '';
                    }
                    _tillCashOutError = null;
                  });
                },
              ),
              if (_paidFromTill) ...[
                const SizedBox(height: 12),
                NumericInputField.money(
                  label: 'Amount paid from till (KES)',
                  controller: _tillCashOutController,
                  errorText: _tillCashOutError,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Reduces expected cash at close. Profit is not affected — '
                  'stock cost counts when items sell.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Receive Stock',
                loading: _submitting,
                onPressed: selected == null ? null : () => _submit(selected),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
