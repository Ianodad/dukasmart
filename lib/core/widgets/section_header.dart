import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A section label with an optional trailing action (e.g. "Attention
/// Needed" on the Home Dashboard). 24dp top space per DESIGN.md spacing.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.title),
          ?trailing,
        ],
      ),
    );
  }
}
