import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/database/database.dart';
import '../../core/providers.dart';
import '../../core/widgets/barcode_field.dart';
import '../../core/widgets/cart_item_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/product_list_tile.dart';
import '../../core/widgets/stock_status_chip.dart';
import 'cart_notifier.dart';

/// New Sale / POS (route `/sell`).
class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _tryAddToCart(Product product) {
    if (product.sellingPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} has no selling price set and cannot be sold.')),
      );
      return;
    }
    final added = ref.read(cartProvider.notifier).add(product);
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No more ${product.name} in stock.')),
      );
    }
  }

  Future<void> _onBarcodeScanned(String barcode) async {
    final product = await ref.read(productsDaoProvider).getByBarcode(barcode);
    if (!mounted) return;
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found.')),
      );
      return;
    }
    _tryAddToCart(product);
    _barcodeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cartLines = ref.watch(cartLinesProvider);
    final totalCents = ref.watch(cartTotalCentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search products',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: BarcodeField(
              controller: _barcodeController,
              onScanned: _onBarcodeScanned,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: productsAsync.when(
              data: (products) {
                final filtered = _query.trim().isEmpty
                    ? products
                    : products
                        .where((p) => p.name.toLowerCase().contains(_query.trim().toLowerCase()))
                        .toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'No products match your search.',
                    icon: Icons.search_off,
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    // Dim tiles the owner can't actually sell right now —
                    // no price set, or nothing left on the shelf (DESIGN.md
                    // POS/Sell: "out-of-stock tiles dimmed + red-pair
                    // chip" — the chip itself comes from ProductListTile's
                    // StockStatusChip).
                    final outOfStock = stockStatusFor(
                          quantity: product.quantity,
                          threshold: product.lowStockThreshold,
                        ) ==
                        StockStatus.outOfStock;
                    final disabled = product.sellingPrice == null || outOfStock;
                    return Opacity(
                      opacity: disabled ? 0.5 : 1,
                      child: ProductListTile(
                        name: product.name,
                        sellingPriceCents: product.sellingPrice,
                        quantity: product.quantity,
                        unitLabel: product.unit.label,
                        threshold: product.lowStockThreshold,
                        onTap: () => _tryAddToCart(product),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Failed to load products: $error')),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text('Cart', style: AppTextStyles.title),
                ),
                Expanded(
                  child: cartLines.isEmpty
                      ? const EmptyState(title: 'Cart is empty. Tap a product to add it.')
                      : ListView.builder(
                          itemCount: cartLines.length,
                          itemBuilder: (context, index) {
                            final line = cartLines[index];
                            return CartItemTile(
                              name: line.product.name,
                              quantity: line.quantity,
                              lineTotalCents: line.lineTotalCents,
                              onIncrement: () => ref.read(cartProvider.notifier).increment(line.product),
                              onDecrement: () =>
                                  ref.read(cartProvider.notifier).decrement(line.product.id),
                              onRemove: () => ref.read(cartProvider.notifier).remove(line.product.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      // DESIGN.md POS/Sell: "Cart bar: dark slate strip with onDark total +
      // emerald Proceed button." — the second committed dark element this
      // screen note explicitly calls for, alongside the app bar band.
      bottomNavigationBar: ColoredBox(
        color: AppTokens.surfaceDark,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total', style: AppTextStyles.caption.copyWith(color: AppTokens.onDark)),
                      MoneyText(
                        totalCents,
                        style: AppTextStyles.moneySmall.copyWith(color: AppTokens.onDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: 'Proceed to Payment',
                    onPressed: cartLines.isEmpty ? null : () => context.pushNamed('sale-payment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
