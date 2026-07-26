import '../../core/database/enums.dart';

/// A catalog entry for a common kiosk product (UAT feedback: "offer a
/// catalog of common products with default prices so I don't have to type
/// descriptions"). All prices are integer cents (design D2) — never
/// floating point money.
class CommonProduct {
  const CommonProduct({
    required this.name,
    required this.unit,
    required this.buyingPriceCents,
    required this.sellingPriceCents,
    required this.threshold,
  });

  final String name;
  final ProductUnit unit;
  final int buyingPriceCents;
  final int sellingPriceCents;
  final int threshold;
}

/// The 15 common kiosk products offered in Add Product's "Choose common
/// product" bottom sheet, with Ian's UAT-supplied default KES prices
/// converted to integer cents.
const List<CommonProduct> commonProducts = [
  CommonProduct(
    name: 'Bread 400g',
    unit: ProductUnit.piece,
    buyingPriceCents: 5500,
    sellingPriceCents: 6500,
    threshold: 5,
  ),
  CommonProduct(
    name: 'Milk 500ml',
    unit: ProductUnit.packet,
    buyingPriceCents: 5000,
    sellingPriceCents: 6000,
    threshold: 10,
  ),
  CommonProduct(
    name: 'Sugar 1kg',
    unit: ProductUnit.packet,
    buyingPriceCents: 14500,
    sellingPriceCents: 16000,
    threshold: 5,
  ),
  CommonProduct(
    name: 'Maize Flour 2kg',
    unit: ProductUnit.packet,
    buyingPriceCents: 15500,
    sellingPriceCents: 17500,
    threshold: 5,
  ),
  CommonProduct(
    name: 'Wheat Flour 2kg',
    unit: ProductUnit.packet,
    buyingPriceCents: 16500,
    sellingPriceCents: 18500,
    threshold: 5,
  ),
  CommonProduct(
    name: 'Cooking Oil 500ml',
    unit: ProductUnit.bottle,
    buyingPriceCents: 13000,
    sellingPriceCents: 15000,
    threshold: 5,
  ),
  CommonProduct(
    name: 'Rice 1kg',
    unit: ProductUnit.packet,
    buyingPriceCents: 15000,
    sellingPriceCents: 17000,
    threshold: 5,
  ),
  CommonProduct(
    name: 'Tea Leaves 250g',
    unit: ProductUnit.packet,
    buyingPriceCents: 11500,
    sellingPriceCents: 13000,
    threshold: 5,
  ),
  CommonProduct(
    name: 'Egg',
    unit: ProductUnit.piece,
    buyingPriceCents: 1300,
    sellingPriceCents: 1500,
    threshold: 30,
  ),
  CommonProduct(
    name: 'Bar Soap 800g',
    unit: ProductUnit.piece,
    buyingPriceCents: 13000,
    sellingPriceCents: 15000,
    threshold: 5,
  ),
  CommonProduct(
    name: 'Detergent 500g',
    unit: ProductUnit.packet,
    buyingPriceCents: 18000,
    sellingPriceCents: 20000,
    threshold: 5,
  ),
  CommonProduct(
    name: 'Salt 500g',
    unit: ProductUnit.packet,
    buyingPriceCents: 2500,
    sellingPriceCents: 3000,
    threshold: 5,
  ),
  CommonProduct(
    name: 'Matches Box',
    unit: ProductUnit.piece,
    buyingPriceCents: 500,
    sellingPriceCents: 1000,
    threshold: 10,
  ),
  CommonProduct(
    name: 'Soda 500ml',
    unit: ProductUnit.bottle,
    buyingPriceCents: 5500,
    sellingPriceCents: 7000,
    threshold: 12,
  ),
  CommonProduct(
    name: 'Tissue Paper Roll',
    unit: ProductUnit.piece,
    buyingPriceCents: 2500,
    sellingPriceCents: 3500,
    threshold: 10,
  ),
];
