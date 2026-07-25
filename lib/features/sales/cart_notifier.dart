import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/database/daos/sales_dao.dart';
import '../../core/providers.dart';

/// The POS cart (design D1/D6: feature-local, in-memory, T2-owned).
///
/// Holds `productId -> quantity`. The DAO (`SalesDao.completeSale`) is the
/// real backstop for stock limits; this notifier only applies an advisory
/// guard so the UI can't visibly walk past on-hand stock.
class CartNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => const {};

  /// Adds one unit of [product] to the cart, capped at its current stock.
  /// Returns `false` when the cart was already at the stock limit (no-op).
  bool add(Product product, {int quantity = 1}) {
    final current = state[product.id] ?? 0;
    final next = current + quantity;
    if (current >= product.quantity) return false;
    final capped = next > product.quantity ? product.quantity : next;
    state = {...state, product.id: capped};
    return true;
  }

  void increment(Product product) => add(product);

  void decrement(int productId) {
    final current = state[productId] ?? 0;
    if (current <= 1) {
      remove(productId);
      return;
    }
    final next = {...state};
    next[productId] = current - 1;
    state = next;
  }

  void remove(int productId) {
    final next = {...state}..remove(productId);
    state = next;
  }

  void clear() => state = const {};

  List<CartLine> toLines() =>
      state.entries.map((e) => (productId: e.key, quantity: e.value)).toList(growable: false);
}

final cartProvider = NotifierProvider<CartNotifier, Map<int, int>>(CartNotifier.new);

/// A cart row resolved against its current [Product] record, so the UI can
/// show the name/price/stock without a second lookup.
class CartLineView {
  const CartLineView({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get lineTotalCents => (product.sellingPrice ?? 0) * quantity;
}

/// Cart quantities resolved against the live product list (design D2: totals
/// are computed from product selling prices, never cached from the UI).
final cartLinesProvider = Provider<List<CartLineView>>((ref) {
  final cart = ref.watch(cartProvider);
  if (cart.isEmpty) return const [];
  final products = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
  final byId = {for (final p in products) p.id: p};
  final lines = <CartLineView>[];
  for (final entry in cart.entries) {
    final product = byId[entry.key];
    if (product == null) continue;
    lines.add(CartLineView(product: product, quantity: entry.value));
  }
  return lines;
});

/// Cart total in cents, summed from [cartLinesProvider] (design D2: int math
/// only, `sellingPriceSnapshot * quantity` per line).
final cartTotalCentsProvider = Provider<int>((ref) {
  final lines = ref.watch(cartLinesProvider);
  var total = 0;
  for (final line in lines) {
    total += line.lineTotalCents;
  }
  return total;
});
