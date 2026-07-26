import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/database/database.dart';
import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/stock_status_chip.dart';

/// Feature-local: products at or below their low-stock threshold (design
/// D5), sourced from the frozen `ProductsDao.watchProducts(lowStockOnly:
/// true)` contract. Does not touch the frozen `lib/core/providers.dart`.
final _lowStockProductsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(productsDaoProvider).watchProducts(lowStockOnly: true);
});

/// Low Stock (route `/home/low-stock`).
class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  void _openProductSheet(BuildContext context, Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductDetailsSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(_lowStockProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Low Stock')),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const EmptyState(
              title: 'All stocked up',
              message: 'No products are low on stock right now.',
              icon: Icons.check_circle_outline,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = products[index];
              return _LowStockRow(
                product: p,
                onTap: () => _openProductSheet(context, p),
                onAddStock: () => context.pushNamed('add-stock', extra: p.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

/// A single Low Stock row: bordered card in the [ProductListTile] visual
/// language, plus the quantity/threshold that put it here in amber
/// emphasis, the [StockStatusChip] (already amber/red pair styled), and a
/// quick-restock icon (inkMuted -> emerald on press, matching the Product
/// List row pattern).
class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.product, required this.onTap, required this.onAddStock});

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(product.name, style: AppTextStyles.bodyStrong),
                      const SizedBox(height: 2),
                      Text(
                        'Qty ${product.quantity} · Threshold ${product.lowStockThreshold}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTokens.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StockStatusChip(quantity: product.quantity, threshold: product.lowStockThreshold),
                    const SizedBox(height: 4),
                    product.sellingPrice != null
                        ? MoneyText(product.sellingPrice!)
                        : Text(
                            'No price',
                            style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                          ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_box_outlined),
                  tooltip: 'Add Stock',
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          states.contains(WidgetState.pressed) ? AppTokens.emerald : AppTokens.inkMuted,
                    ),
                  ),
                  onPressed: onAddStock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "View Product" bottom sheet (design D5): product details + an Add
/// Stock action.
class _ProductDetailsSheet extends StatelessWidget {
  const _ProductDetailsSheet({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: AppTextStyles.title),
            const SizedBox(height: 12),
            Text('Barcode: ${product.barcode ?? '—'}'),
            Text('Unit: ${product.unit.label}'),
            Text('Quantity: ${product.quantity}'),
            Text('Low-stock threshold: ${product.lowStockThreshold}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Buying price: '),
                product.buyingPrice != null
                    ? MoneyText(product.buyingPrice!)
                    : Text('Not set', style: AppTextStyles.body.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
            Row(
              children: [
                const Text('Selling price: '),
                product.sellingPrice != null
                    ? MoneyText(product.sellingPrice!)
                    : Text('Not set', style: AppTextStyles.body.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add Stock',
              onPressed: () {
                Navigator.of(context).pop();
                context.pushNamed('add-stock', extra: product.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
