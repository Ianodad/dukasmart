import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/ai/ai_providers.dart';
import '../../core/models/daily_metrics.dart';
import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';

/// Home Dashboard (route `/home`). Track T3 body. Renders the frozen
/// [dailyMetricsProvider] ONLY — no screen-local aggregates (design D1).
///
/// DESIGN.md "Screen notes -> Dashboard": header band, TODAY'S SALES hero
/// number directly on bg, cash/M-PESA dot-chips, an amberContainer
/// Attention block with a full border, a tonal quick-actions grid, and a
/// full-width emerald New Sale pill pinned above the bottom nav.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dailyMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('DukaSmart'),
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: AppTextStyles.caption.copyWith(color: AppTokens.onDark),
            ),
          ],
        ),
      ),
      body: metricsAsync.when(
        data: (metrics) => _DashboardBody(
          metrics: metrics,
          aiAvailable: ref.watch(aiAvailableProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load dashboard: $error', textAlign: TextAlign.center),
          ),
        ),
      ),
      // Pinned above the shell's bottom nav (DESIGN.md: "New Sale =
      // full-width primary pill pinned above nav").
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: PrimaryButton(
          label: 'New Sale',
          icon: Icons.point_of_sale,
          onPressed: () => context.goNamed('sell'),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.metrics, required this.aiAvailable});

  final DailyMetrics metrics;
  final bool aiAvailable;

  @override
  Widget build(BuildContext context) {
    final attentionCount = metrics.outOfStock.length +
        metrics.lowStock.length +
        metrics.missingBuyingPrice.length +
        metrics.missingSellingPrice.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        Text("TODAY'S SALES", style: AppTextStyles.overline),
        const SizedBox(height: 4),
        MoneyText(metrics.totalSales, style: AppTextStyles.moneyDisplay),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MethodDotChip(dotColor: AppTokens.emerald, label: 'Cash', amountCents: metrics.cashSales),
            _MethodDotChip(dotColor: AppTokens.blue, label: 'M-PESA', amountCents: metrics.mpesaSales),
          ],
        ),
        if (aiAvailable) ...[
          const SizedBox(height: 16),
          const _AskDukaBar(),
        ],
        const SectionHeader('Attention Needed'),
        if (attentionCount == 0)
          const EmptyState(
            title: 'All good!',
            message: 'No stock or pricing issues right now.',
            icon: Icons.check_circle_outline,
          )
        else
          _AttentionCard(metrics: metrics, attentionCount: attentionCount),
        const SectionHeader('Quick Actions'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          children: [
            _QuickActionTile(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
              onTap: () => context.pushNamed('product-add'),
            ),
            _QuickActionTile(
              icon: Icons.inventory_2_outlined,
              label: 'Add Stock',
              onTap: () => context.pushNamed('add-stock'),
            ),
            _QuickActionTile(
              icon: Icons.receipt_long_outlined,
              label: 'Record Expense',
              onTap: () => context.pushNamed('expense-add'),
            ),
            _QuickActionTile(
              icon: Icons.event_available_outlined,
              label: 'Close Day',
              onTap: () => context.pushNamed('close-day'),
            ),
            _QuickActionTile(
              icon: Icons.summarize_outlined,
              label: 'Daily Report',
              onTap: () => _openLatestReport(context),
            ),
          ],
        ),
      ],
    );
  }

  // Codex fix: dashboard "Daily Report" quick action. Reads the most
  // recently closed day and opens the existing report route for that
  // date; if no day has ever been closed, tells the owner instead of
  // navigating to an empty report.
  Future<void> _openLatestReport(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final close = await container.read(dailyCloseDaoProvider).latestClose();
    if (!context.mounted) return;

    if (close == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No closed day yet')),
      );
      return;
    }

    context.pushNamed(
      'daily-report',
      queryParameters: {'date': close.date.toIso8601String()},
    );
  }
}

class _MethodDotChip extends StatelessWidget {
  const _MethodDotChip({required this.dotColor, required this.label, required this.amountCents});

  final Color dotColor;
  final String label;
  final int amountCents;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppTokens.surfaceMuted, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.caption),
            const SizedBox(width: 6),
            MoneyText(
              amountCents,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppTokens.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// DESIGN.md: amberContainer block with a FULL border (never a side
/// stripe) — count + every attention item, block tap -> Low stock. Each
/// item keeps its own existing destination (low-stock or products),
/// preserving the prior per-item navigation semantics exactly.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.metrics, required this.attentionCount});

  final DailyMetrics metrics;
  final int attentionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.amberContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTokens.amber),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.pushNamed('low-stock'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_outlined, color: AppTokens.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$attentionCount item${attentionCount == 1 ? '' : 's'} need attention',
                        style: AppTextStyles.bodyStrong.copyWith(color: AppTokens.amber),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppTokens.amber),
                  ],
                ),
                const SizedBox(height: 8),
                for (final product in metrics.outOfStock)
                  _AttentionRow(
                    title: product.name,
                    subtitle: 'Out of stock',
                    onTap: () => context.pushNamed('low-stock'),
                  ),
                for (final product in metrics.lowStock)
                  _AttentionRow(
                    title: product.name,
                    subtitle: 'Low stock: ${product.quantity} left',
                    onTap: () => context.pushNamed('low-stock'),
                  ),
                for (final product in metrics.missingBuyingPrice)
                  _AttentionRow(
                    title: product.name,
                    subtitle: 'Missing buying price',
                    onTap: () => context.goNamed('products'),
                  ),
                for (final product in metrics.missingSellingPrice)
                  _AttentionRow(
                    title: product.name,
                    subtitle: 'Missing selling price',
                    onTap: () => context.goNamed('products'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(color: AppTokens.ink)),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppTokens.amber)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppTokens.amber),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppTokens.emerald, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyStrong,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiet ask-bar entry point for the AI assistant (spec UX decision:
/// discoverable without competing with the money numbers — slate
/// surface, never emerald).
class _AskDukaBar extends StatelessWidget {
  const _AskDukaBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => context.pushNamed('ask'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  size: 18, color: AppTokens.inkSecondary),
              const SizedBox(width: 10),
              Text(
                'Ask about your duka…',
                style: AppTextStyles.body.copyWith(color: AppTokens.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
