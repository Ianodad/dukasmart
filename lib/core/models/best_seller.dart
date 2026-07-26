/// A day's best-selling product (design D4).
///
/// Tie-break order when two products sell the same quantity: higher
/// revenue wins; if still tied, alphabetically-first product name wins.
class BestSeller {
  const BestSeller({
    required this.productId,
    required this.name,
    required this.qtySold,
    required this.revenue,
  });

  final int productId;
  final String name;
  final int qtySold;
  final int revenue; // cents

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BestSeller &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          name == other.name &&
          qtySold == other.qtySold &&
          revenue == other.revenue;

  @override
  int get hashCode => Object.hash(productId, name, qtySold, revenue);

  @override
  String toString() =>
      'BestSeller(productId: $productId, name: $name, qtySold: $qtySold, revenue: $revenue)';
}
