import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The app's single primary call-to-action button style: emerald pill,
/// full-width, 52dp tall, press feedback (AnimatedScale to 0.97), and a
/// loading spinner state. [onPressed] is disabled automatically while
/// [loading] is true, satisfying the design D3 "disabled while an async
/// submit is in flight" rule.
class PrimaryButton extends StatefulWidget {
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
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  double _scale = 1;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool pressed) {
    if (!_enabled) return;
    setState(() => _scale = pressed ? 0.97 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTokens.onEmerald),
          )
        : widget.icon == null
            ? Text(widget.label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon),
                  const SizedBox(width: 8),
                  Text(widget.label),
                ],
              );

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.loading ? null : widget.onPressed,
            child: child,
          ),
        ),
      ),
    );
  }
}
