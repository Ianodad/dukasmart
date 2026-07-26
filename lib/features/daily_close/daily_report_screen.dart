import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Daily Report (route `/home/report`, optional `?date=`). Stub —
/// Track T4 replaces this body (design D6 write rule).
class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({super.key, this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Report')),
      body: const EmptyState(title: 'Daily Report — under construction'),
    );
  }
}
