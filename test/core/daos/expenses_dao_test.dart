import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/database/errors.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('recordExpense', () {
    test('today -> createdAt is a real "now" timestamp', () async {
      final before = DateTime.now();
      await db.expensesDao.recordExpense(
        amountCents: 500,
        category: ExpenseCategory.airtime,
        method: PaymentMethod.cash,
        selectedDate: DateTime.now(),
      );
      final after = DateTime.now();

      final expense = (await db.select(db.expenses).get()).single;
      expect(expense.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(expense.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('backdated -> createdAt is that date at local midnight', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await db.expensesDao.recordExpense(
        amountCents: 500,
        category: ExpenseCategory.rent,
        method: PaymentMethod.cash,
        selectedDate: yesterday,
      );

      final expense = (await db.select(db.expenses).get()).single;
      expect(expense.createdAt, DateTime(yesterday.year, yesterday.month, yesterday.day));
    });

    test('future date -> throws', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(
        () => db.expensesDao.recordExpense(
          amountCents: 500,
          category: ExpenseCategory.other,
          method: PaymentMethod.cash,
          selectedDate: tomorrow,
        ),
        throwsA(isA<DukaError>()),
      );
    });

    test('rejects amount <= 0', () async {
      expect(
        () => db.expensesDao.recordExpense(
          amountCents: 0,
          category: ExpenseCategory.other,
          method: PaymentMethod.cash,
          selectedDate: DateTime.now(),
        ),
        throwsA(isA<DukaError>()),
      );
    });
  });

  group('day bounds', () {
    test('an expense at 23:59 is in today, 00:00 next day is not', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endOfToday = today.add(const Duration(hours: 23, minutes: 59));
      final startOfNextDay = today.add(const Duration(days: 1));

      await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              amount: 100,
              category: ExpenseCategory.other,
              paymentMethod: PaymentMethod.cash,
              createdAt: endOfToday,
            ),
          );
      await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              amount: 200,
              category: ExpenseCategory.other,
              paymentMethod: PaymentMethod.cash,
              createdAt: startOfNextDay,
            ),
          );

      final todaysExpenses = await db.expensesDao.watchExpensesForDay(today).first;
      expect(todaysExpenses, hasLength(1));
      expect(todaysExpenses.single.amount, 100);
    });
  });

  group('watchRecentExpenses', () {
    test('returns newest-first across all days, limited', () async {
      final now = DateTime.now();
      for (var i = 0; i < 3; i++) {
        await db.into(db.expenses).insert(
              ExpensesCompanion.insert(
                amount: 100 + i,
                category: ExpenseCategory.other,
                paymentMethod: PaymentMethod.cash,
                createdAt: now.subtract(Duration(days: i)),
              ),
            );
      }

      final recent = await db.expensesDao.watchRecentExpenses(limit: 2).first;
      expect(recent, hasLength(2));
      expect(recent.first.amount, 100); // most recent (i=0) first
    });
  });
}
