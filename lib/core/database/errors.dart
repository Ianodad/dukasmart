/// Domain errors raised by the DAO layer (design D3 atomic contracts).
class DukaError implements Exception {
  DukaError(this.message);

  final String message;

  factory DukaError.duplicateBarcode(String barcode) =>
      DukaError('A product with barcode "$barcode" already exists.');

  factory DukaError.notFound(String what) => DukaError(what);

  factory DukaError.invalidQuantity(String reason) => DukaError(reason);

  factory DukaError.invalidAmount(String reason) => DukaError(reason);

  factory DukaError.invalidPayment(String reason) => DukaError(reason);

  factory DukaError.emptyCart() =>
      DukaError('Cart is empty. Add at least one item.');

  factory DukaError.insufficientStock(String productName) =>
      DukaError('Not enough stock for $productName.');

  factory DukaError.missingSellingPrice(String productName) =>
      DukaError('$productName has no selling price set.');

  factory DukaError.futureDate() =>
      DukaError('Date cannot be in the future.');

  @override
  String toString() => message;
}
