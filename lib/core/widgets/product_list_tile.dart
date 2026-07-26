import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'money_text.dart';
import 'stock_status_chip.dart';

/// A single Product List / search-result row: name, selling price (or
/// "No price" when null — design D5), quantity + unit label, and stock
/// status chip. DESIGN.md tile look: surface fill + hairline border, name
/// bodyStrong, price moneySmall, quantity caption.
class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.name,
    required this.sellingPriceCents,
    required this.quantity,
    required this.unitLabel,
    required this.threshold,
    this.onTap,
  });

  final String name;
  final int? sellingPriceCents;
  final int quantity;
  final String unitLabel;
  final int threshold;
  final VoidCallback? onTap;

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
                      Text(name, style: AppTextStyles.bodyStrong),
                      const SizedBox(height: 2),
                      Text('$quantity $unitLabel', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    sellingPriceCents != null
                        ? MoneyText(sellingPriceCents!)
                        : Text(
                            'No price',
                            style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                          ),
                    const SizedBox(height: 4),
                    StockStatusChip(quantity: quantity, threshold: threshold),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
