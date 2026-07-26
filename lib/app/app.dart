import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class DukaSmartApp extends StatelessWidget {
  const DukaSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DukaSmart',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
