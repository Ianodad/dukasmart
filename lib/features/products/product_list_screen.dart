import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/providers.dart';
import '../../core/widgets/barcode_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/product_list_tile.dart';

/// Feature-local search text (name contains, case-insensitive per the
/// frozen `ProductsDao.watchProducts` contract).
final _searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Feature-local low-stock filter toggle.
final _lowStockOnlyProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Combines the frozen `ProductsDao.watchProducts` stream with this
/// screen's search + filter state. Feature-local — does not touch the
/// frozen `lib/core/providers.dart` registrations.
final _filteredProductsProvider = StreamProvider.autoDispose<List<Product>>((
  ref,
) {
  final dao = ref.watch(productsDaoProvider);
  final query = ref.watch(_searchQueryProvider).trim();
  final lowStockOnly = ref.watch(_lowStockOnlyProvider);
  return dao.watchProducts(
    query: query.isEmpty ? null : query,
    lowStockOnly: lowStockOnly,
  );
});

/// Product List (route `/products`).
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeScanned(String code) async {
    final product = await ref.read(productsDaoProvider).getByBarcode(code);
    if (!mounted) return;
    if (product == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product not found')));
      return;
    }
    _searchController.text = product.name;
    ref.read(_searchQueryProvider.notifier).state = product.name;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(_filteredProductsProvider);
    final lowStockOnly = ref.watch(_lowStockOnlyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('product-add'),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search products',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(_searchQueryProvider.notifier).state = value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: BarcodeField(
              controller: _barcodeController,
              label: 'Scan barcode to find product',
              onScanned: _onBarcodeScanned,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Low stock only'),
                selected: lowStockOnly,
                onSelected: (value) =>
                    ref.read(_lowStockOnlyProvider.notifier).state = value,
              ),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const EmptyState(title: 'No products found.');
                }
                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return Row(
                      children: [
                        Expanded(
                          child: ProductListTile(
                            name: p.name,
                            sellingPriceCents: p.sellingPrice,
                            quantity: p.quantity,
                            unitLabel: p.unit.label,
                            threshold: p.lowStockThreshold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_box_outlined),
                          tooltip: 'Add stock',
                          onPressed: () =>
                              context.pushNamed('add-stock', extra: p.id),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
