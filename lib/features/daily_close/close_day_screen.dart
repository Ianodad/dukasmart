import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models/daily_metrics.dart';
import '../../core/providers.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/numeric_input_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';

/// Close Day (route `/home/close-day`). Renders a live preview of today's
/// [dailyMetricsProvider] figures, takes the actual cash count + an
/// optional note, and on confirm calls the frozen `DailyCloseDao.closeDay`
/// (design D4), then routes to the Daily Report.
///
/// DESIGN.md "Screen notes -> Close day / Report": figures render as a
/// clean two-column ledger list (label inkSecondary / value moneySmall
/// ink) — never a card grid; gross/net are emphasized moneyMedium; cash
/// difference is an emerald pair when at/over expected, a red pair when
/// short.
class CloseDayScreen extends ConsumerStatefulWidget {
  const CloseDayScreen({super.key});

  @override
  ConsumerState<CloseDayScreen> createState() => _CloseDayScreenState();
}

class _CloseDayScreenState extends ConsumerState<CloseDayScreen> {
  final _actualCashController = TextEditingController();
  final _noteController = TextEditingController();
  int? _actualCashCents;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _actualCashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _completeDay() async {
    final actualCash = _actualCashCents;
    if (_isSubmitting || actualCash == null) return;

    setState(() => _isSubmitting = true);
    try {
      final today = DateTime.now();
      final existing = await ref.read(dailyCloseDaoProvider).getClose(today);
      if (!mounted) return;

      final message = existing != null
          ? 'This will replace today\'s earlier close with these updated figures.'
          : 'This will record today\'s close. You can keep selling and re-close later — '
              'it will simply refresh the figures.';

      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'Complete Day',
        message: message,
        confirmLabel: 'Complete Day',
      );
      if (!confirmed) return;

      final note = _noteController.text.trim();
      await ref.read(dailyCloseDaoProvider).closeDay(
            date: today,
            actualCashCents: actualCash,
            note: note.isEmpty ? null : note,
          );

      if (!mounted) return;
      context.go('/home/report');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(dailyMetricsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Close Day')),
      body: metricsAsync.when(
        data: (metrics) => _buildBody(context, metrics),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load today\'s figures: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DailyMetrics metrics) {
    final expectedCash = metrics.cashSales - metrics.cashExpenses;
    final difference = _actualCashCents == null ? null : _actualCashCents! - expectedCash;
    final diffColor = (difference ?? 0) >= 0 ? AppTokens.emerald : AppTokens.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Today\'s figures'),
          _MoneyLedgerRow(label: 'Total sales', cents: metrics.totalSales),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Cash sales', cents: metrics.cashSales),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'M-PESA sales', cents: metrics.mpesaSales),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Expenses', cents: metrics.expensesTotal),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Cost of goods', cents: metrics.cogs),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Gross profit', cents: metrics.grossProfit, emphasize: true),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Net result', cents: metrics.netResult, emphasize: true),
          const Divider(height: 1),
          _TextLedgerRow(label: 'Transactions', value: '${metrics.txCount}'),
          const Divider(height: 1),
          _TextLedgerRow(label: 'Low stock', value: '${metrics.lowStockCount}'),
          const SectionHeader('Cash count'),
          NumericInputField.money(
            label: 'Actual cash counted',
            controller: _actualCashController,
            enabled: !_isSubmitting,
            onChanged: (text) => setState(() {
              _actualCashCents = NumericInputField.parseValue(text, NumericInputMode.money);
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            enabled: !_isSubmitting,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 8),
          _MoneyLedgerRow(label: 'Expected cash', cents: expectedCash, emphasize: true),
          const Divider(height: 1),
          difference == null
              ? const _TextLedgerRow(label: 'Difference', value: '—')
              : _MoneyLedgerRow(
                  label: 'Difference',
                  cents: difference,
                  emphasize: true,
                  color: diffColor,
                ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Complete Day',
            loading: _isSubmitting,
            onPressed: _actualCashCents == null || _isSubmitting ? null : _completeDay,
          ),
        ],
      ),
    );
  }
}

/// A ledger row for a money figure: label inkSecondary on the left, value
/// on the right via [MoneyText] (design D2 — the sole KES renderer).
/// [emphasize] bumps the value to moneyMedium (gross/net/expected/
/// difference); [color] recolors both label and value as one pair
/// (emerald when the cash difference is at/over expected, red when
/// short) — never applied to plain ink figures.
class _MoneyLedgerRow extends StatelessWidget {
  const _MoneyLedgerRow({
    required this.label,
    required this.cents,
    this.emphasize = false,
    this.color,
  });

  final String label;
  final int cents;
  final bool emphasize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final valueStyle =
        (emphasize ? AppTextStyles.moneyMedium : AppTextStyles.moneySmall).copyWith(
      color: color ?? AppTokens.ink,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(color: color ?? AppTokens.inkSecondary)),
          MoneyText(cents, style: valueStyle),
        ],
      ),
    );
  }
}

/// A ledger row for a non-money value (transaction/low-stock counts).
class _TextLedgerRow extends StatelessWidget {
  const _TextLedgerRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(color: AppTokens.inkSecondary)),
          Text(value, style: AppTextStyles.moneySmall),
        ],
      ),
    );
  }
}
