import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/database/daos/sales_dao.dart';
import '../../core/database/enums.dart';
import '../../core/providers.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/primary_button.dart';

/// The completed sale + its items for the Sale Success screen and its
/// "View Sale" bottom sheet (design D5). Feature-local: composes the
/// frozen `SalesDao.getSale` contract.
final saleWithItemsProvider =
    FutureProvider.autoDispose.family<SaleWithItems, int>((ref, saleId) {
  return ref.watch(salesDaoProvider).getSale(saleId);
});

/// Sale Success (route `/sell/success/:saleId`).
class SaleSuccessScreen extends ConsumerWidget {
  const SaleSuccessScreen({super.key, required this.saleId});

  final int saleId;

  void _showItemsSheet(BuildContext context, SaleWithItems sale) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sale items', style: AppTextStyles.title),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sale.items.length,
                    itemBuilder: (context, index) {
                      final item = sale.items[index];
                      return ListTile(
                        title: Text(item.productName),
                        subtitle: Text('Qty ${item.quantity}'),
                        trailing: MoneyText(item.total),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: AppTextStyles.bodyStrong),
                    MoneyText(sale.sale.total, style: AppTextStyles.moneySmall),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleWithItemsProvider(saleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Sale Complete'), automaticallyImplyLeading: false),
      body: saleAsync.when(
        data: (saleWithItems) {
          final sale = saleWithItems.sale;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: _SuccessCheck()),
                const SizedBox(height: 16),
                Center(child: MoneyText(sale.total, style: AppTextStyles.moneyMedium)),
                const SizedBox(height: 8),
                Center(child: Text(sale.paymentMethod.label, style: AppTextStyles.caption)),
                if (sale.paymentMethod == PaymentMethod.cash) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text('CHANGE GIVEN', style: AppTextStyles.overline),
                        const SizedBox(height: 4),
                        MoneyText(
                          sale.changeAmount,
                          style: AppTextStyles.moneySmall.copyWith(color: AppTokens.emerald),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    DateFormat('d MMM yyyy, h:mm a').format(sale.createdAt),
                    style: AppTextStyles.caption.copyWith(color: AppTokens.inkMuted),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'New Sale',
                  onPressed: () => context.goNamed('sell'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => context.goNamed('home'),
                  child: const Text('Return Home'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _showItemsSheet(context, saleWithItems),
                  child: const Text('View Sale'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load sale: $error')),
      ),
    );
  }
}

/// DESIGN.md Sale success note: "the one emerald-committed moment — emerald
/// circle check" that reveals with an `AnimatedScale`-in once, ≤250ms
/// (DESIGN.md Motion). Scales from 0 to 1 a single time on first build;
/// later rebuilds of the same element (e.g. the provider re-emitting) don't
/// replay it because [State] — and `_scale` — survive across them.
class _SuccessCheck extends StatefulWidget {
  const _SuccessCheck();

  @override
  State<_SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<_SuccessCheck> {
  double _scale = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _scale = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(color: AppTokens.emerald, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: AppTokens.onEmerald, size: 48),
      ),
    );
  }
}
