import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../database/enums.dart';

/// Cash vs M-PESA toggle used on the Payment and Record Expense screens.
///
/// DESIGN.md Component vocabulary: segmented pills — Cash goes solid
/// emerald when selected (money-positive/primary weight); M-PESA goes
/// blueContainer/blue (a tint pair, info-only, never M-PESA branding).
/// Both are the neutral surfaceMuted/inkSecondary pill when unselected.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({super.key, required this.value, required this.onChanged});

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final cashSelected = value == PaymentMethod.cash;
    final mpesaSelected = value == PaymentMethod.mpesa;

    return Row(
      children: [
        Expanded(
          child: _MethodPill(
            label: PaymentMethod.cash.label,
            icon: Icons.payments_outlined,
            background: cashSelected ? AppTokens.emerald : AppTokens.surfaceMuted,
            foreground: cashSelected ? AppTokens.onEmerald : AppTokens.inkSecondary,
            onTap: () => onChanged(PaymentMethod.cash),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MethodPill(
            label: PaymentMethod.mpesa.label,
            icon: Icons.phone_iphone_outlined,
            background: mpesaSelected ? AppTokens.blueContainer : AppTokens.surfaceMuted,
            foreground: mpesaSelected ? AppTokens.blue : AppTokens.inkSecondary,
            onTap: () => onChanged(PaymentMethod.mpesa),
          ),
        ),
      ],
    );
  }
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.bodyStrong.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
