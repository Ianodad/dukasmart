import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/daos/sales_dao.dart';
import '../../core/database/enums.dart';
import '../../core/providers.dart';
import 'cart_notifier.dart';

/// Guards the Payment screen's submit button against double-taps (design
/// D3: "every mutating screen's submit button is state-guarded ... via its
/// Riverpod notifier"). `state.isLoading` disables the button while
/// `completeSale` is in flight.
class SaleSubmitController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Submits the sale. Returns the new `saleId` on success, or `null` after
  /// recording the failure in [state] (surfaced by the screen as a
  /// SnackBar; the screen stays put — design D8).
  Future<int?> submit({
    required List<CartLine> lines,
    required PaymentMethod method,
    required int amountReceivedCents,
    String? mpesaCode,
  }) async {
    state = const AsyncLoading();
    try {
      final saleId = await ref.read(salesDaoProvider).completeSale(
            lines: lines,
            method: method,
            amountReceivedCents: amountReceivedCents,
            mpesaCode: mpesaCode,
          );
      // Cart is cleared only after completeSale returns successfully
      // (design D3).
      ref.read(cartProvider.notifier).clear();
      state = const AsyncData(null);
      return saleId;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final saleSubmitProvider =
    AutoDisposeAsyncNotifierProvider<SaleSubmitController, void>(SaleSubmitController.new);
