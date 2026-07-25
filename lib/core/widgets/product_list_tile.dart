import 'package:flutter/material.dart';

import 'money_text.dart';
import 'stock_status_chip.dart';

/// A single Product List / search-result row: name, selling price (or
/// "No price" when null — design D5), quantity + unit label, and stock
/// status chip.
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
    return ListTile(
      onTap: onTap,
      title: Text(name),
      subtitle: Text('$quantity $unitLabel'),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          sellingPriceCents != null
              ? MoneyText(sellingPriceCents!)
              : const Text('No price', style: TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          StockStatusChip(quantity: quantity, threshold: threshold),
        ],
      ),
    );
  }
}
