import 'package:flutter/material.dart';

import '../database/enums.dart';

/// Cash vs M-PESA toggle used on the Payment and Record Expense screens.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({super.key, required this.value, required this.onChanged});

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PaymentMethod>(
      segments: [
        ButtonSegment(
          value: PaymentMethod.cash,
          label: Text(PaymentMethod.cash.label),
          icon: const Icon(Icons.payments_outlined),
        ),
        ButtonSegment(
          value: PaymentMethod.mpesa,
          label: Text(PaymentMethod.mpesa.label),
          icon: const Icon(Icons.phone_iphone_outlined),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
