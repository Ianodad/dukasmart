import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/database/enums.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/numeric_input_field.dart';
import '../../core/widgets/payment_method_selector.dart';
import '../../core/widgets/primary_button.dart';
import 'cart_notifier.dart';
import 'sale_submit_controller.dart';

/// Renders a cents value as plain digits (no "KES" prefix, no thousands
/// separators) suitable for prefilling a [NumericInputField.money] — the
/// field's own `parseKesToCents` regex rejects grouping commas.
String _centsToPlainInputText(int cents) {
  final shillings = cents ~/ 100;
  final remainder = cents % 100;
  return remainder == 0 ? '$shillings' : '$shillings.${remainder.toString().padLeft(2, '0')}';
}

/// Payment (route `/sell/payment`).
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.cash;
  final _amountController = TextEditingController();
  final _mpesaCodeController = TextEditingController();
  bool _mpesaPrefilled = false;

  @override
  void dispose() {
    _amountController.dispose();
    _mpesaCodeController.dispose();
    super.dispose();
  }

  void _onMethodChanged(PaymentMethod method, int totalCents) {
    setState(() {
      _method = method;
      if (method == PaymentMethod.mpesa) {
        _amountController.text = _centsToPlainInputText(totalCents);
        _mpesaPrefilled = true;
      } else {
        _amountController.clear();
        _mpesaPrefilled = false;
      }
    });
  }

  /// Codex fix: a rebuild (e.g. the cart total changing while M-PESA is
  /// selected) used to overwrite whatever the user had typed, because
  /// [_mpesaPrefilled] only ever got cleared by switching methods — never
  /// by the user actually editing the field. Any user edit now clears it
  /// immediately, so the build-time "keep prefill in sync" block below
  /// stops touching the field once the owner has typed their own amount.
  void _onAmountEdited(String _) {
    setState(() => _mpesaPrefilled = false);
  }

  /// `null` when the field's text is invalid/empty for the current method's
  /// rule (design D3 (e)); the parsed cents value otherwise.
  int? _parsedAmount() => NumericInputField.parseValue(_amountController.text, NumericInputMode.money);

  String? _amountError(int totalCents) {
    final amount = _parsedAmount();
    if (_amountController.text.trim().isEmpty) return 'Enter the amount received.';
    if (amount == null) return 'Enter a valid amount.';
    if (_method == PaymentMethod.cash) {
      if (amount < totalCents) return 'Amount received is less than the total.';
    } else {
      if (amount != totalCents) return 'M-PESA amount must equal the total.';
    }
    return null;
  }

  Future<void> _submit(int totalCents) async {
    final amount = _parsedAmount();
    final error = _amountError(totalCents);
    if (amount == null || error != null) {
      setState(() {}); // surface the validation error
      return;
    }

    final lines = ref.read(cartProvider.notifier).toLines();
    final mpesaCode = _mpesaCodeController.text.trim();

    final saleId = await ref.read(saleSubmitProvider.notifier).submit(
          lines: lines,
          method: _method,
          amountReceivedCents: amount,
          mpesaCode: _method == PaymentMethod.mpesa && mpesaCode.isNotEmpty ? mpesaCode : null,
        );

    if (!mounted) return;
    if (saleId != null) {
      context.goNamed('sale-success', pathParameters: {'saleId': saleId.toString()});
      return;
    }

    final failure = ref.read(saleSubmitProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$failure')));
  }

  @override
  Widget build(BuildContext context) {
    final totalCents = ref.watch(cartTotalCentsProvider);
    final cartLines = ref.watch(cartLinesProvider);
    final submitting = ref.watch(saleSubmitProvider).isLoading;

    if (cartLines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: EmptyState(
          title: 'Cart is empty. Add products to sell.',
          actionLabel: 'New Sale',
          onAction: () => context.goNamed('sell'),
        ),
      );
    }

    // Keep the M-PESA prefill in sync if the cart total changes while the
    // user hasn't typed their own value yet.
    if (_method == PaymentMethod.mpesa && _mpesaPrefilled) {
      final expected = _centsToPlainInputText(totalCents);
      if (_amountController.text != expected) {
        _amountController.text = expected;
      }
    }

    final amount = _parsedAmount();
    final changeDue = (_method == PaymentMethod.cash && amount != null && amount >= totalCents)
        ? amount - totalCents
        : 0;
    final insufficientCash = _method == PaymentMethod.cash &&
        _amountController.text.isNotEmpty &&
        amount != null &&
        amount < totalCents;

    // Confirm is disabled whenever the current amount fails design D3(e)'s
    // rule (empty, unparsable, short cash, or mismatched M-PESA) — DESIGN.md
    // Payment note: "disabled confirm when insufficient".
    final amountValidationError = _amountError(totalCents);
    final canSubmit = !submitting && amountValidationError == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Text('TOTAL DUE', style: AppTextStyles.overline),
                  const SizedBox(height: 4),
                  MoneyText(totalCents, style: AppTextStyles.moneyDisplay),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PaymentMethodSelector(
              value: _method,
              onChanged: submitting ? (_) {} : (method) => _onMethodChanged(method, totalCents),
            ),
            const SizedBox(height: 24),
            NumericInputField.money(
              key: const Key('payment-amount-field'),
              label: _method == PaymentMethod.cash ? 'Amount received' : 'Amount received (M-PESA)',
              controller: _amountController,
              enabled: !submitting,
              onChanged: _onAmountEdited,
              errorText: _amountController.text.isEmpty ? null : amountValidationError,
            ),
            if (_method == PaymentMethod.cash) ...[
              const SizedBox(height: 16),
              _ChangeDueBlock(changeDueCents: changeDue, insufficient: insufficientCash),
            ],
            if (_method == PaymentMethod.mpesa) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _mpesaCodeController,
                enabled: !submitting,
                decoration: const InputDecoration(labelText: 'M-PESA transaction code (optional)'),
              ),
            ],
            const SizedBox(height: 32),
            PrimaryButton(
              label: _method == PaymentMethod.cash ? 'Confirm Cash Payment' : 'Confirm M-PESA Payment',
              loading: submitting,
              onPressed: canSubmit ? () => _submit(totalCents) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// DESIGN.md Payment note: "change due in emeraldContainer block with
/// emeraldDeep moneyMedium" — recolors to the red pair while the cash
/// received so far is short of the total.
class _ChangeDueBlock extends StatelessWidget {
  const _ChangeDueBlock({required this.changeDueCents, required this.insufficient});

  final int changeDueCents;
  final bool insufficient;

  @override
  Widget build(BuildContext context) {
    final background = insufficient ? AppTokens.redContainer : AppTokens.emeraldContainer;
    final foreground = insufficient ? AppTokens.red : AppTokens.emeraldDeep;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Change due', style: AppTextStyles.bodyStrong.copyWith(color: foreground)),
          MoneyText(changeDueCents, style: AppTextStyles.moneyMedium.copyWith(color: foreground)),
        ],
      ),
    );
  }
}
