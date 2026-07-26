import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/assistant/ask_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/dashboard/splash_screen.dart';
import '../features/daily_close/close_day_screen.dart';
import '../features/daily_close/daily_report_screen.dart';
import '../features/expenses/expense_list_screen.dart';
import '../features/expenses/record_expense_screen.dart';
import '../features/inventory/add_stock_screen.dart';
import '../features/inventory/low_stock_screen.dart';
import '../features/products/add_product_screen.dart';
import '../features/products/product_list_screen.dart';
import '../features/sales/payment_screen.dart';
import '../features/sales/sale_success_screen.dart';
import '../features/sales/sell_screen.dart';
import 'theme.dart';

/// The FROZEN route table (design D6/D9). Foundation registers every
/// route up front, pointing at stub screens in each feature's own
/// folder; tracks may only edit/add files under their own
/// `lib/features/<feature>/` directory (including these stub screens) —
/// this file itself is Foundation-owned and read-only to tracks
/// thereafter.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => _AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'ask',
                  name: 'ask',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const AskScreen(),
                ),
                GoRoute(
                  path: 'add-stock',
                  name: 'add-stock',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => AddStockScreen(
                    productId: state.extra is int ? state.extra as int : null,
                  ),
                ),
                GoRoute(
                  path: 'low-stock',
                  name: 'low-stock',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const LowStockScreen(),
                ),
                GoRoute(
                  path: 'close-day',
                  name: 'close-day',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const CloseDayScreen(),
                ),
                GoRoute(
                  path: 'report',
                  name: 'daily-report',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final dateParam = state.uri.queryParameters['date'];
                    final date = dateParam != null ? DateTime.tryParse(dateParam) : null;
                    return DailyReportScreen(date: date);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/sell',
              name: 'sell',
              builder: (context, state) => const SellScreen(),
              routes: [
                GoRoute(
                  path: 'payment',
                  name: 'sale-payment',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const PaymentScreen(),
                ),
                GoRoute(
                  path: 'success/:saleId',
                  name: 'sale-success',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => SaleSuccessScreen(
                    saleId: int.parse(state.pathParameters['saleId']!),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/products',
              name: 'products',
              builder: (context, state) => const ProductListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'product-add',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const AddProductScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              name: 'expenses',
              builder: (context, state) => const ExpenseListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'expense-add',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const RecordExpenseScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// The 4-tab bottom navigation shell (Home, Sell, Products, Expenses)
/// wrapping the `StatefulShellRoute.indexedStack` branches.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      // NavigationBarThemeData has no border slot, so the DESIGN.md
      // hairline top border is applied here directly.
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTokens.border)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Sell',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Expenses',
            ),
          ],
        ),
      ),
    );
  }
}
