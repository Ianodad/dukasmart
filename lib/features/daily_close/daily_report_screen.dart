import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/database/day_bounds.dart';
import '../../core/models/closed_day_report.dart';
import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/product_list_tile.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/summary_card.dart';
import 'insight_generator.dart';

/// Daily Report (route `/home/report`, optional `?date=`). Reads the
/// frozen `closedDayReportProvider` (design D4): stored financials are
/// labeled "as at close", the best-seller is derived fresh "for the day",
/// and the low-stock list reflects "current" stock levels. Shows an
/// EmptyState with a Close Day shortcut when the day has not been closed.
class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({super.key, this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedDate = localMidnight(date ?? DateTime.now());
    final reportAsync = ref.watch(closedDayReportProvider(normalizedDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Report')),
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return EmptyState(
              title: 'Day not closed yet',
              icon: Icons.fact_check_outlined,
              actionLabel: 'Close Day',
              onAction: () => context.push('/home/close-day'),
            );
          }
          return _ReportBody(report: report);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load the report: $error'),
          ),
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final ClosedDayReport report;

  @override
  Widget build(BuildContext context) {
    final close = report.close;
    final bestSeller = report.bestSeller;
    final diffColor = close.cashDifference >= 0 ? AppColors.success : AppColors.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DateFormat('EEEE, d MMMM y').format(close.date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const SectionHeader('Financials — as at close'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              SummaryCard(label: 'Total sales', value: MoneyText(close.totalSales)),
              SummaryCard(label: 'Cash sales', value: MoneyText(close.cashSales)),
              SummaryCard(label: 'M-PESA sales', value: MoneyText(close.mpesaSales)),
              SummaryCard(label: 'Expenses', value: MoneyText(close.expenses)),
              SummaryCard(label: 'Cost of goods', value: MoneyText(close.costOfGoods)),
              SummaryCard(label: 'Gross profit', value: MoneyText(close.grossProfit)),
              SummaryCard(label: 'Net result', value: MoneyText(close.netResult)),
              SummaryCard(label: 'Expected cash', value: MoneyText(close.expectedCash)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SummaryCard(label: 'Actual cash', value: MoneyText(close.actualCash)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryCard(
                  label: 'Cash difference',
                  value: MoneyText(
                    close.cashDifference,
                    style: TextStyle(color: diffColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          if (close.note != null && close.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Note: ${close.note}'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const SectionHeader('Best seller — for the day'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: bestSeller == null
                  ? const Text('No sales recorded.')
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${bestSeller.name} · ${bestSeller.qtySold} sold',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        MoneyText(bestSeller.revenue),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader('Low stock — current'),
          report.lowStockNow.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No low-stock products. Well stocked!'),
                  ),
                )
              : Card(
                  child: Column(
                    children: [
                      for (final product in report.lowStockNow)
                        ProductListTile(
                          name: product.name,
                          sellingPriceCents: product.sellingPrice,
                          quantity: product.quantity,
                          unitLabel: product.unit.label,
                          threshold: product.lowStockThreshold,
                        ),
                    ],
                  ),
                ),
          const SizedBox(height: 16),
          const SectionHeader('Insight'),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline),
                  const SizedBox(width: 12),
                  Expanded(child: Text(buildInsight(report))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
