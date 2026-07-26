import 'package:intl/intl.dart';

/// DukaSmart money handling — integer cents everywhere.
///
/// `double * 100` is banned (design D2): all parsing goes straight from the
/// input string to an `int` cents value, and all formatting goes straight
/// from an `int` cents value to a display string. No floating point money
/// math anywhere in this app.

final NumberFormat _shillingsFormat = NumberFormat('#,##0');

/// Parses a KES amount string ("55", "55.5", "55.50") into integer cents.
///
/// Returns `null` on invalid input (empty, negative, malformed, or more
/// than two decimal digits).
int? parseKesToCents(String input) {
  final t = input.trim();
  if (t.isEmpty) return null;
  final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(t);
  if (m == null) return null;
  final shillings = int.parse(m.group(1)!);
  final frac = m.group(2);
  final cents = frac == null ? 0 : int.parse(frac.padRight(2, '0'));
  return shillings * 100 + cents;
}

/// Formats integer cents as a KES display string.
///
/// `1245000` -> `"KES 12,450"`; `1245050` -> `"KES 12,450.50"`.
String formatCents(int cents) {
  final shillings = cents ~/ 100;
  final remainder = cents % 100;
  final wholePart = _shillingsFormat.format(shillings);
  if (remainder == 0) {
    return 'KES $wholePart';
  }
  final centsPart = remainder.toString().padLeft(2, '0');
  return 'KES $wholePart.$centsPart';
}
