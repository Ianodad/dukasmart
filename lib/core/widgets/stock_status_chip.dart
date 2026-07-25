import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Stock status rule (design D5): `qty == 0` -> Out of Stock; else
/// `qty <= threshold` -> Low Stock; else -> In Stock.
enum StockStatus { inStock, lowStock, outOfStock }

StockStatus stockStatusFor({required int quantity, required int threshold}) {
  if (quantity == 0) return StockStatus.outOfStock;
  if (quantity <= threshold) return StockStatus.lowStock;
  return StockStatus.inStock;
}

class StockStatusChip extends StatelessWidget {
  const StockStatusChip({super.key, required this.quantity, required this.threshold});

  final int quantity;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    final status = stockStatusFor(quantity: quantity, threshold: threshold);
    final (label, color) = switch (status) {
      StockStatus.outOfStock => ('Out of Stock', AppColors.error),
      StockStatus.lowStock => ('Low Stock', AppColors.warning),
      StockStatus.inStock => ('In Stock', AppColors.success),
    };

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
