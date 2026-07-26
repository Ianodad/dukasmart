import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/ai/ai_providers.dart';
import '../../core/database/database.dart';
import '../../core/database/day_bounds.dart';
import '../../core/models/closed_day_report.dart';
import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/section_header.dart';
import 'insight_generator.dart';

/// Daily Report (route `/home/report`, optional `?date=`). Reads the
/// frozen `closedDayReportProvider` (design D4): stored financials are
/// labeled "as at close", the best-seller is derived fresh "for the day",
/// and the low-stock list reflects "current" stock levels. Shows an
/// EmptyState with a Close Day shortcut when the day has not been closed.
///
/// DESIGN.md "Screen notes -> Close day / Report": figures render as a
/// clean two-column ledger list (label inkSecondary / value moneySmall
/// ink) — never a card grid; the qualifier suffixes ("as at close" / "for
/// the day" / "current") are styled caption/inkMuted; cash difference is
/// an emerald pair when at/over expected, a red pair when short; the
/// insight paragraph sits in a surfaceMuted block.
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
    final diffColor = close.cashDifference >= 0 ? AppTokens.emerald : AppTokens.red;
    final lowStock = report.lowStockNow;
    final note = close.note?.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(DateFormat('EEEE, d MMMM y').format(close.date), style: AppTextStyles.headline),
          const _QualifiedSectionHeader(title: 'Financials', qualifier: '— as at close'),
          _MoneyLedgerRow(label: 'Total sales', cents: close.totalSales),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Cash sales', cents: close.cashSales),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'M-PESA sales', cents: close.mpesaSales),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Expenses', cents: close.expenses),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Cost of goods', cents: close.costOfGoods),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Gross profit', cents: close.grossProfit, emphasize: true),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Net result', cents: close.netResult, emphasize: true),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Expected cash', cents: close.expectedCash, emphasize: true),
          const Divider(height: 1),
          _MoneyLedgerRow(label: 'Actual cash', cents: close.actualCash),
          const Divider(height: 1),
          _MoneyLedgerRow(
            label: 'Cash difference',
            cents: close.cashDifference,
            emphasize: true,
            color: diffColor,
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTokens.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Note: $note', style: AppTextStyles.body),
            ),
          ],
          const _QualifiedSectionHeader(title: 'Best seller', qualifier: '— for the day'),
          bestSeller == null
              ? Text(
                  'No sales recorded.',
                  style: AppTextStyles.body.copyWith(color: AppTokens.inkSecondary),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bestSeller.name,
                            style: AppTextStyles.bodyStrong,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${bestSeller.qtySold} sold',
                            style: AppTextStyles.caption.copyWith(color: AppTokens.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    MoneyText(bestSeller.revenue),
                  ],
                ),
          const _QualifiedSectionHeader(title: 'Low stock', qualifier: '— current'),
          lowStock.isEmpty
              ? Text(
                  'No low-stock products. Well stocked!',
                  style: AppTextStyles.body.copyWith(color: AppTokens.inkSecondary),
                )
              : Column(
                  children: [
                    for (var i = 0; i < lowStock.length; i++) ...[
                      _LowStockRow(product: lowStock[i]),
                      if (i != lowStock.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
          const SectionHeader('Insight'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: AppTokens.inkSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(buildInsight(report), style: AppTextStyles.body)),
              ],
            ),
          ),
          _AiInsightCard(date: close.date),
        ],
      ),
    );
  }
}

/// A section header with a muted qualifier suffix on the same line (e.g.
/// "Financials — as at close") — the qualifier renders caption/inkMuted
/// exactly as the underlying data source labels it (design D4).
class _QualifiedSectionHeader extends StatelessWidget {
  const _QualifiedSectionHeader({required this.title, required this.qualifier});

  final String title;
  final String qualifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(width: 6),
          Text(qualifier, style: AppTextStyles.caption.copyWith(color: AppTokens.inkMuted)),
        ],
      ),
    );
  }
}

/// A ledger row for a money figure: label inkSecondary on the left, value
/// on the right via [MoneyText] (design D2 — the sole KES renderer).
/// [emphasize] bumps the value to moneyMedium (gross/net/expected/cash
/// difference); [color] recolors both label and value as one pair
/// (emerald when the cash difference is at/over expected, red when
/// short).
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

/// A single low-stock row — DESIGN.md "amber pairs": both the product
/// name and its remaining quantity render in amber, since every row here
/// is already known to be low/out of stock (no per-row chip needed).
class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              product.name,
              style: AppTextStyles.bodyStrong.copyWith(color: AppTokens.amber),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${product.quantity} ${product.unit.label}',
            style: AppTextStyles.caption.copyWith(color: AppTokens.amber, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// AI insight card (spec): loads below the deterministic insight when AI
/// is configured and online. Loading -> subtle progress row; success ->
/// paragraph; null or failure -> renders nothing (this screen never
/// shows an AI error state). The rule-based insight above is the
/// permanent offline fallback.
class _AiInsightCard extends ConsumerWidget {
  const _AiInsightCard({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(aiAvailableProvider)) return const SizedBox.shrink();

    final insightAsync = ref.watch(aiInsightProvider(date));
    return insightAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'AI insight…',
              style: AppTextStyles.caption.copyWith(color: AppTokens.inkMuted),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (insight) {
        if (insight == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_outlined,
                    color: AppTokens.inkSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(insight, style: AppTextStyles.body)),
              ],
            ),
          ),
        );
      },
    );
  }
}
