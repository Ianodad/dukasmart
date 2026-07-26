// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_close_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyCloseDaoMixin on DatabaseAccessor<AppDatabase> {
  $SalesTable get sales => attachedDatabase.sales;
  $ProductsTable get products => attachedDatabase.products;
  $SaleItemsTable get saleItems => attachedDatabase.saleItems;
  $ExpensesTable get expenses => attachedDatabase.expenses;
  $DailyClosesTable get dailyCloses => attachedDatabase.dailyCloses;
  DailyCloseDaoManager get managers => DailyCloseDaoManager(this);
}

class DailyCloseDaoManager {
  final _$DailyCloseDaoMixin _db;
  DailyCloseDaoManager(this._db);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db.attachedDatabase, _db.saleItems);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db.attachedDatabase, _db.expenses);
  $$DailyClosesTableTableManager get dailyCloses =>
      $$DailyClosesTableTableManager(_db.attachedDatabase, _db.dailyCloses);
}
