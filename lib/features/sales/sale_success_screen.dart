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
                const Text('Sale items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    MoneyText(sale.sale.total, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 72),
                const SizedBox(height: 16),
                MoneyText(sale.total, style: AppTextStyles.totalLarge),
                const SizedBox(height: 8),
                Text(sale.paymentMethod.label, style: Theme.of(context).textTheme.titleMedium),
                if (sale.paymentMethod == PaymentMethod.cash) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Change given: '),
                      MoneyText(sale.changeAmount),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  DateFormat('d MMM yyyy, h:mm a').format(sale.createdAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'New Sale',
                  onPressed: () => context.goNamed('sell'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
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
