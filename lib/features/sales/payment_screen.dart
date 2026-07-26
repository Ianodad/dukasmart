import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Payment (route `/sell/payment`). Stub — Track T2 replaces this body
/// (design D6 write rule).
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: const EmptyState(title: 'Payment — under construction'),
    );
  }
}
