import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/primary_button.dart';

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
              title: 'No low-stock products. Well stocked!',
              icon: Icons.check_circle_outline,
            );
          }
          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = products[index];
              return ListTile(
                onTap: () => _openProductSheet(context, p),
                title: Text(p.name),
                subtitle: Text('Qty: ${p.quantity}  •  Threshold: ${p.lowStockThreshold}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    p.sellingPrice != null
                        ? MoneyText(p.sellingPrice!)
                        : const Text('No price', style: TextStyle(fontStyle: FontStyle.italic)),
                    IconButton(
                      icon: const Icon(Icons.add_box_outlined),
                      tooltip: 'Add Stock',
                      onPressed: () => context.pushNamed('add-stock', extra: p.id),
                    ),
                  ],
                ),
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
            Text(product.name, style: Theme.of(context).textTheme.titleLarge),
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
                    : const Text('Not set'),
              ],
            ),
            Row(
              children: [
                const Text('Selling price: '),
                product.sellingPrice != null
                    ? MoneyText(product.sellingPrice!)
                    : const Text('Not set'),
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
