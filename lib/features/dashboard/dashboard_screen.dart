import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models/daily_metrics.dart';
import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/summary_card.dart';

/// Home Dashboard (route `/home`). Track T3 body. Renders the frozen
/// [dailyMetricsProvider] ONLY — no screen-local aggregates (design D1).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dailyMetricsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: metricsAsync.when(
        data: (metrics) => _DashboardBody(metrics: metrics),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load dashboard: $error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.metrics});

  final DailyMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final attentionCount = metrics.outOfStock.length +
        metrics.lowStock.length +
        metrics.missingBuyingPrice.length +
        metrics.missingSellingPrice.length;
    final neutralIconColor = Theme.of(context).colorScheme.outline;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: [
            SummaryCard(
              label: "Today's Sales",
              value: MoneyText(metrics.totalSales, style: AppTextStyles.totalSmall),
              icon: Icons.point_of_sale_outlined,
            ),
            SummaryCard(
              label: 'Cash Sales',
              value: MoneyText(metrics.cashSales, style: AppTextStyles.totalSmall),
              icon: Icons.payments_outlined,
            ),
            SummaryCard(
              label: 'M-PESA Sales',
              value: MoneyText(metrics.mpesaSales, style: AppTextStyles.totalSmall),
              icon: Icons.phone_iphone_outlined,
              color: AppColors.mpesaAccent,
            ),
            SummaryCard(
              label: "Today's Expenses",
              value: MoneyText(metrics.expensesTotal, style: AppTextStyles.totalSmall),
              icon: Icons.receipt_long_outlined,
            ),
            SummaryCard(
              label: 'Gross Profit',
              value: MoneyText(metrics.grossProfit, style: AppTextStyles.totalSmall),
              icon: Icons.trending_up_outlined,
              color: AppColors.success,
            ),
            SummaryCard(
              label: 'Low Stock',
              value: Text('${metrics.lowStockCount}', style: AppTextStyles.totalSmall),
              icon: Icons.warning_amber_outlined,
              color: metrics.lowStockCount > 0 ? AppColors.warning : null,
              onTap: () => context.pushNamed('low-stock'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SectionHeader('Quick Actions'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickAction(
              icon: Icons.point_of_sale,
              label: 'New Sale',
              onTap: () => context.goNamed('sell'),
            ),
            _QuickAction(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
              onTap: () => context.pushNamed('product-add'),
            ),
            _QuickAction(
              icon: Icons.inventory_2_outlined,
              label: 'Add Stock',
              onTap: () => context.pushNamed('add-stock'),
            ),
            _QuickAction(
              icon: Icons.receipt_long,
              label: 'Record Expense',
              onTap: () => context.pushNamed('expense-add'),
            ),
            _QuickAction(
              icon: Icons.event_available_outlined,
              label: 'Close Day',
              onTap: () => context.pushNamed('close-day'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SectionHeader('Attention Needed'),
        if (attentionCount == 0)
          const EmptyState(title: 'All good!', icon: Icons.check_circle_outline)
        else ...[
          for (final product in metrics.outOfStock)
            _AttentionTile(
              icon: Icons.remove_shopping_cart_outlined,
              color: AppColors.error,
              title: product.name,
              subtitle: 'Out of stock',
              onTap: () => context.pushNamed('low-stock'),
            ),
          for (final product in metrics.lowStock)
            _AttentionTile(
              icon: Icons.warning_amber_outlined,
              color: AppColors.warning,
              title: product.name,
              subtitle: 'Low stock: ${product.quantity} left',
              onTap: () => context.pushNamed('low-stock'),
            ),
          for (final product in metrics.missingBuyingPrice)
            _AttentionTile(
              icon: Icons.price_change_outlined,
              color: neutralIconColor,
              title: product.name,
              subtitle: 'Missing buying price',
              onTap: () => context.goNamed('products'),
            ),
          for (final product in metrics.missingSellingPrice)
            _AttentionTile(
              icon: Icons.price_change_outlined,
              color: neutralIconColor,
              title: product.name,
              subtitle: 'Missing selling price',
              onTap: () => context.goNamed('products'),
            ),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
