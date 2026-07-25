import 'package:drift/drift.dart';

import '../database.dart';
import '../day_bounds.dart';
import '../enums.dart';
import '../errors.dart';
import '../tables.dart';

part 'expenses_dao.g.dart';

/// Frozen atomic surface (design D3/D9).
@DriftAccessor(tables: [Expenses])
class ExpensesDao extends DatabaseAccessor<AppDatabase> with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  /// Records an expense. Applies the design D3 `createdAt` semantics:
  /// today -> `DateTime.now()`; a past date -> that date at local
  /// midnight; a future date -> [DukaError.futureDate].
  Future<void> recordExpense({
    required int amountCents,
    required ExpenseCategory category,
    String? description,
    required PaymentMethod method,
    required DateTime selectedDate,
  }) {
    if (amountCents <= 0) {
      throw DukaError.invalidAmount('Expense amount must be greater than zero.');
    }

    final today = localMidnight(DateTime.now());
    final selectedDay = localMidnight(selectedDate);

    if (selectedDay.isAfter(today)) {
      throw DukaError.futureDate();
    }

    final createdAt = selectedDay.isAtSameMomentAs(today) ? DateTime.now() : selectedDay;

    return into(expenses).insert(
      ExpensesCompanion.insert(
        amount: amountCents,
        category: category,
        description: Value(description),
        paymentMethod: method,
        createdAt: createdAt,
      ),
    );
  }

  /// Watches expenses within [day]'s half-open local day bounds
  /// (design D3), newest first.
  Stream<List<Expense>> watchExpensesForDay(DateTime day) {
    final bounds = dayBounds(day);
    return (select(expenses)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(bounds.start) &
              t.createdAt.isSmallerThanValue(bounds.end))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Watches the most recent expenses across all days, newest first —
  /// the Expense List source (design D3: makes the date-vs-time display
  /// rule for backdated entries reachable from a single stream).
  Stream<List<Expense>> watchRecentExpenses({int limit = 100}) {
    return (select(expenses)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }
}
