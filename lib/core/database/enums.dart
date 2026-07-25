/// Core enums shared across the DukaSmart data layer.
///
/// Each enum exposes a `label` getter with the exact display string from
/// the product requirements (`docs/specs/2026-07-25-requirements.md`).
library;

enum ProductUnit {
  piece,
  packet,
  bottle,
  kilogram,
  litre,
  crate,
  carton,
  tray,
  other;

  String get label => switch (this) {
        ProductUnit.piece => 'Piece',
        ProductUnit.packet => 'Packet',
        ProductUnit.bottle => 'Bottle',
        ProductUnit.kilogram => 'Kilogram',
        ProductUnit.litre => 'Litre',
        ProductUnit.crate => 'Crate',
        ProductUnit.carton => 'Carton',
        ProductUnit.tray => 'Tray',
        ProductUnit.other => 'Other',
      };
}

enum PaymentMethod {
  cash,
  mpesa;

  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.mpesa => 'M-PESA',
      };
}

enum ExpenseCategory {
  stockTransport,
  stockPurchase,
  electricity,
  airtime,
  food,
  rent,
  repairs,
  personalWithdrawal,
  other;

  String get label => switch (this) {
        ExpenseCategory.stockTransport => 'Stock transport',
        ExpenseCategory.stockPurchase => 'Stock purchase',
        ExpenseCategory.electricity => 'Electricity',
        ExpenseCategory.airtime => 'Airtime',
        ExpenseCategory.food => 'Food',
        ExpenseCategory.rent => 'Rent',
        ExpenseCategory.repairs => 'Repairs',
        ExpenseCategory.personalWithdrawal => 'Personal withdrawal',
        ExpenseCategory.other => 'Other',
      };
}

enum MovementType {
  openingStock,
  stockReceived,
  sale,
  manualCorrection;

  String get label => switch (this) {
        MovementType.openingStock => 'Opening stock',
        MovementType.stockReceived => 'Stock received',
        MovementType.sale => 'Sale',
        MovementType.manualCorrection => 'Manual correction',
      };
}
