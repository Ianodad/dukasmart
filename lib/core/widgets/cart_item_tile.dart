import 'package:flutter/material.dart';

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
    return ListTile(
      title: Text(name),
      subtitle: MoneyText(lineTotalCents),
      leading: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onRemove,
        tooltip: 'Remove',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onDecrement,
            tooltip: 'Decrease quantity',
          ),
          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onIncrement,
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}
