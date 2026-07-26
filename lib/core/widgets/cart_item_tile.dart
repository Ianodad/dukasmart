import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'money_text.dart';

/// A single POS cart row with +/-/remove controls and a line total.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.name,
    required this.quantity,
    required this.lineTotalCents,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final String name;
  final int quantity;
  final int lineTotalCents;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppTokens.red,
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 2),
                MoneyText(lineTotalCents),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: AppTokens.inkSecondary,
            onPressed: onDecrement,
            tooltip: 'Decrease quantity',
          ),
          Text('$quantity', style: AppTextStyles.bodyStrong),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppTokens.emerald,
            onPressed: onIncrement,
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}
