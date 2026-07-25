# DukaSmart — MVP Requirements (from Ian, 2026-07-25)

**Product:** DukaSmart — Android inventory & sales app for a single Kenyan kiosk owner.
**Tagline:** "Know your stock. Grow your business."
**Scope:** One-day MVP. One owner, one kiosk, one phone. Local data only.

## Constraints (explicitly OUT of scope)
No auth/login, employee roles, customer accounts/credit, multi-branch, cloud sync, backend,
KRA eTIMS, Daraja/M-PESA API integration, receipt printing, AI assistant, push notifications,
data export, refunds, discounts, mixed payments, expiry tracking, Bluetooth printing,
barcode product lookup, suppliers/purchase orders.

## Stack (mandated)
Flutter + Dart, Riverpod (state), GoRouter (navigation), Drift + SQLite (storage),
mobile_scanner (barcodes), image_picker (optional product images), intl (KES formatting).
Target: Android.

## Core workflow
Open app → dashboard → add products/opening stock → record sale → cash or M-PESA →
stock auto-reduces → record expenses → view low stock → close day → daily summary.

## Screens (13, build ONLY these)
1. **Splash** — logo, name, tagline, loader; auto-open Home after local data loads.
2. **Home dashboard** — today's total sales, cash sales, M-PESA sales, today's expenses,
   estimated gross profit, low-stock count. Quick actions: New Sale, Add Product, Add Stock,
   Record Expense, Close Day. "Attention Needed" list: low-stock, out-of-stock, missing
   buying price, missing selling price. KES formatting: `KES 12,450`.
3. **Product list** — rows: name, selling price, stock, unit, status (In Stock / Low Stock /
   Out of Stock). Search, Add Product button, barcode-scan button, low-stock filter.
4. **Add product** — fields: name, optional barcode, optional image, buying price, selling
   price, opening stock, unit, low-stock threshold. Units: Piece, Packet, Bottle, Kilogram,
   Litre, Crate, Carton, Tray, Other. Show profit/unit = selling − buying. Save → Product List.
5. **Add stock** — select product, qty received, latest buying price, optional note.
   Confirm → increase stock, create stock movement, update buying price if changed.
6. **New sale (POS)** — search, barcode scan, product tiles (name, price, stock), cart with
   +/−/remove, block overselling, show total. Primary button: Proceed to Payment.
7. **Payment** — total prominent. Cash: amount received → change = received − total.
   M-PESA: amount received + optional transaction code, manual confirm button. No Daraja.
8. **Sale success** — total, method, change (cash), date/time. Buttons: New Sale, Return
   Home, View Sale. Completing a sale saves sale + payment, reduces stock, writes movements.
9. **Expense list** — today's total, recent expenses (category, amount, method, time),
   Record Expense button.
10. **Record expense** — amount, category, description, method (Cash/M-PESA), date.
    Categories: Stock transport, Electricity, Airtime, Food, Rent, Repairs, Personal
    withdrawal, Other. Expenses reduce net profit, never sales totals.
11. **Low stock** — products where qty <= threshold: name, qty, threshold, price.
    Actions: Add Stock, View Product.
12. **Close day** — totals: sales, cash, M-PESA, expenses, COGS, gross profit, net result,
    transaction count, low-stock count.
    `Gross profit = revenue − cost of goods sold`; `Net = gross − expenses`.
    Input: actual cash on hand + note. `Expected cash = cash sales − cash expenses`;
    `Difference = actual − expected`. Button: Complete Day → save daily-close record.
    Do NOT lock the app after closing.
13. **Daily report** — date, totals, gross/net, cash difference, best-selling product,
    low-stock list, and a rule-generated plain-text insight (no external AI).

## Navigation
Bottom nav: Home, Sell, Products, Expenses. Add Stock / Low Stock / Close Day /
Daily Report accessible from Home.

## Database tables (ONLY these six)
- **products**: id, name, barcode, imagePath, buyingPrice, sellingPrice, quantity, unit,
  lowStockThreshold, createdAt, updatedAt
- **sales**: id, subtotal, total, paymentMethod, amountReceived, changeAmount, mpesaCode, createdAt
- **sale_items**: id, saleId, productId, productName, quantity, buyingPriceSnapshot,
  sellingPriceSnapshot, total
- **expenses**: id, amount, category, description, paymentMethod, createdAt
- **stock_movements**: id, productId, movementType (openingStock | stockReceived | sale |
  manualCorrection), quantity, note, referenceId, createdAt
- **daily_closes**: id, date, totalSales, cashSales, mpesaSales, expenses, costOfGoods,
  grossProfit, netResult, expectedCash, actualCash, cashDifference, note, createdAt

## Business rules
- Products: no negative prices/stock; name required; threshold defaults to 5.
- Sales: ≥1 item; cannot exceed available stock; completing reduces stock; completed sales
  not deletable from UI; cash received ≥ total; M-PESA amount == total.
- Expenses: amount > 0; category and method required.
- Stock: every change creates a movement record; stock never negative; adding stock increases qty.
- Profit: snapshot buying price on every sale item (historical profit immune to price changes).

## Project structure
`lib/app/` (app, router, theme), `lib/core/` (database, formatting, widgets),
`lib/features/` (dashboard, products, inventory, sales, expenses, daily_close), `lib/main.dart`.
Keep simple — no repository/use-case layering.

## Reusable widgets
SummaryCard, ProductListTile, StockStatusChip, MoneyText, PrimaryButton, EmptyState,
NumericInputField, PaymentMethodSelector, CartItemTile, SectionHeader, ConfirmationDialog.

## Design direction
Clean light theme. Dark green primary, white/light-grey background, charcoal text, soft
green success, amber low-stock, red errors/out-of-stock, blue for M-PESA info (no M-PESA
branding). Large touch targets, rounded cards, large financial totals, one-handed use,
no complex charts.

## Seed data (first launch)
| Product | Buy | Sell | Stock | Unit | Threshold |
|---|---|---|---|---|---|
| Coca-Cola 500ml | 55 | 70 | 24 | Bottle | 6 |
| Brookside Milk 500ml | 55 | 65 | 12 | Packet | 5 |
| Jogoo Maize Flour 2kg | 180 | 210 | 10 | Packet | 4 |
| Sugar 1kg | 145 | 170 | 8 | Packet | 4 |
| Bread 400g | 55 | 65 | 5 | Piece | 3 |

## Acceptance flow
Launch → add product → add stock → sale → cash/M-PESA → payment → stock reduces →
record expense → dashboard → close day → daily report. All actions work on local data —
no static-only screens. Deliverables include README + APK build instructions.
