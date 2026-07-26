import 'package:flutter/widgets.dart';

import '../../app/theme.dart';
import '../formatting/money.dart';

/// The sole KES amount renderer in the app (design D2). Every displayed
/// money value must go through this widget — never through ad hoc
/// string formatting.
///
/// Defaults to [AppTextStyles.moneySmall] (tabular figures, ink) when no
/// [style] is given; emerald is only ever applied by a caller passing an
/// explicitly positive-delta style — this widget never auto-colors.
class MoneyText extends StatelessWidget {
  const MoneyText(this.cents, {super.key, this.style});

  final int cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(formatCents(cents), style: style ?? AppTextStyles.moneySmall);
  }
}
