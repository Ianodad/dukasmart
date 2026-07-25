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
import '../../core/widgets/summary_card.dart';

/// Close Day (route `/home/close-day`). Renders a live preview of today's
/// [dailyMetricsProvider] figures, takes the actual cash count + an
/// optional note, and on confirm calls the frozen `DailyCloseDao.closeDay`
/// (design D4), then routes to the Daily Report.
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Today\'s figures'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              SummaryCard(label: 'Total sales', value: MoneyText(metrics.totalSales)),
              SummaryCard(label: 'Cash sales', value: MoneyText(metrics.cashSales)),
              SummaryCard(label: 'M-PESA sales', value: MoneyText(metrics.mpesaSales)),
              SummaryCard(label: 'Expenses', value: MoneyText(metrics.expensesTotal)),
              SummaryCard(label: 'Cost of goods', value: MoneyText(metrics.cogs)),
              SummaryCard(label: 'Gross profit', value: MoneyText(metrics.grossProfit)),
              SummaryCard(label: 'Net result', value: MoneyText(metrics.netResult)),
              SummaryCard(label: 'Transactions', value: Text('${metrics.txCount}')),
              SummaryCard(label: 'Low stock', value: Text('${metrics.lowStockCount}')),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SummaryCard(label: 'Expected cash', value: MoneyText(expectedCash)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryCard(
                  label: 'Difference',
                  value: difference == null
                      ? const Text('—')
                      : MoneyText(
                          difference,
                          style: TextStyle(
                            color: difference >= 0 ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
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
