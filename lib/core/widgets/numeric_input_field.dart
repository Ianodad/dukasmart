import 'package:flutter/material.dart';

import '../formatting/money.dart';

/// What a [NumericInputField] parses its text into.
enum NumericInputMode {
  /// KES amount text ("55.50") -> integer cents via [parseKesToCents].
  money,

  /// Plain non-negative integer quantity ("12") -> `int`, NEVER routed
  /// through [parseKesToCents].
  quantity,
}

/// The app's single numeric text field, with two frozen entry points
/// (design D2 amendment): [NumericInputField.money] returns cents via
/// [parseKesToCents]; [NumericInputField.quantity] returns a plain
/// non-negative `int` via digits-only validation.
class NumericInputField extends StatelessWidget {
  const NumericInputField.money({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
  }) : mode = NumericInputMode.money;

  const NumericInputField.quantity({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
  }) : mode = NumericInputMode.quantity;

  final String label;
  final NumericInputMode mode;

  /// Seed with `controller.text = '...'` before building if a starting
  /// value is needed (e.g. Add Stock's prefilled current buying price).
  final TextEditingController? controller;

  /// Called with the raw text on every change; parse it yourself via
  /// [parseValue] to get the validated cents/int.
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  /// Parses [text] according to [mode]. Money mode uses
  /// [parseKesToCents]; quantity mode accepts non-negative integers only
  /// and NEVER goes through [parseKesToCents].
  static int? parseValue(String text, NumericInputMode mode) {
    if (mode == NumericInputMode.money) {
      return parseKesToCents(text);
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final value = int.tryParse(trimmed);
    if (value == null || value < 0) return null;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.numberWithOptions(
        decimal: mode == NumericInputMode.money,
      ),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixText: mode == NumericInputMode.money ? 'KES ' : null,
      ),
      onChanged: onChanged,
    );
  }
}
