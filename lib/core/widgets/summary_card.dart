import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A dashboard/close-day metric card: overline label + moneyMedium value
/// (DESIGN.md Component vocabulary). No icon-gradient decor — [icon], if
/// given, renders as a small plain glyph beside the label.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final Widget value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: color ?? AppTokens.inkMuted),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: AppTextStyles.overline,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DefaultTextStyle.merge(
                style: AppTextStyles.moneyMedium.copyWith(color: color),
                child: value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
