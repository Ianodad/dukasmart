import 'package:flutter/material.dart';

/// The app's single primary call-to-action button style. [onPressed] is
/// disabled automatically while [loading] is true, satisfying the
/// design D3 "disabled while an async submit is in flight" rule.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(icon), const SizedBox(width: 8), Text(label)],
              );

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: child,
    );
  }
}
