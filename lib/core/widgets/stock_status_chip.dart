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

/// Pill status chip — tint container + deep text (DESIGN.md color rule:
/// tint containers always pair with their deep text, never with ink). In
/// Stock uses the neutral surfaceMuted/inkSecondary pair rather than a
/// semantic tint, since it isn't an attention state.
class StockStatusChip extends StatelessWidget {
  const StockStatusChip({super.key, required this.quantity, required this.threshold});

  final int quantity;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    final status = stockStatusFor(quantity: quantity, threshold: threshold);
    final (label, background, foreground) = switch (status) {
      StockStatus.outOfStock => ('Out of Stock', AppTokens.redContainer, AppTokens.red),
      StockStatus.lowStock => ('Low Stock', AppTokens.amberContainer, AppTokens.amber),
      StockStatus.inStock => ('In Stock', AppTokens.surfaceMuted, AppTokens.inkSecondary),
    };

    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(color: foreground, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
