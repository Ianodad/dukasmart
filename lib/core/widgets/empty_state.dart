import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'primary_button.dart';

/// Every list/screen with nothing to show renders this (design D8: "Every
/// list has an EmptyState"). Also used verbatim by Foundation stub
/// screens: `EmptyState(title: '<Screen> — under construction')`.
///
/// DESIGN.md Component vocabulary: icon in a surfaceMuted circle, title +
/// an optional one-line [message] hint, optional action — teaches the
/// screen, never just "nothing here".
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// Optional one-line hint shown under [title].
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppTokens.surfaceMuted, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AppTokens.inkSecondary),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.title),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(message!, textAlign: TextAlign.center, style: AppTextStyles.caption),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              PrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
