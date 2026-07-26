import 'package:drift/drift.dart';

import 'enums.dart';

/// The six mandated DukaSmart tables (requirements §DB). Prices are
/// nullable per design D3 — the dashboard's Attention Needed list flags
/// null prices rather than forcing a value at creation time.
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get barcode => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get buyingPrice => integer().nullable()(); // cents
  IntColumn get sellingPrice => integer().nullable()(); // cents
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  TextColumn get unit => textEnum<ProductUnit>()();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subtotal => integer()(); // cents
  IntColumn get total => integer()(); // cents
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();
  IntColumn get amountReceived => integer()(); // cents
  IntColumn get changeAmount => integer()(); // cents
  TextColumn get mpesaCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  IntColumn get buyingPriceSnapshot => integer()(); // cents; product.buyingPrice ?? 0
  IntColumn get sellingPriceSnapshot => integer()(); // cents
  IntColumn get total => integer()(); // cents
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()(); // cents
  TextColumn get category => textEnum<ExpenseCategory>()();
  TextColumn get description => text().nullable()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();
  DateTimeColumn get createdAt => dateTime()(); // see design D3 expense semantics
}

class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get movementType => textEnum<MovementType>()();
  IntColumn get quantity => integer()(); // signed: +in / -sale (design D3)
  TextColumn get note => text().nullable()();
  IntColumn get referenceId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class DailyCloses extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()(); // normalized to local midnight
  IntColumn get totalSales => integer()();
  IntColumn get cashSales => integer()();
  IntColumn get mpesaSales => integer()();
  IntColumn get expenses => integer()();
  IntColumn get costOfGoods => integer()();
  IntColumn get grossProfit => integer()();
  IntColumn get netResult => integer()();
  IntColumn get expectedCash => integer()();
  IntColumn get actualCash => integer()();
  IntColumn get cashDifference => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
