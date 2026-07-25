import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../core/database/database.dart';
import '../../core/database/enums.dart';
import '../../core/database/errors.dart';
import '../../core/providers.dart';
import '../../core/widgets/barcode_field.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/numeric_input_field.dart';
import '../../core/widgets/primary_button.dart';
import 'common_products.dart';
import 'image_storage/image_storage.dart';

/// Renders integer cents as an editable KES string ("5500" -> "55",
/// "5550" -> "55.50") without ever going through double math (design
/// D2) — used only to prefill [NumericInputField.money]'s controllers
/// when a common product is selected below.
String centsToInputString(int cents) {
  final shillings = cents ~/ 100;
  final remainder = cents % 100;
  if (remainder == 0) return '$shillings';
  return '$shillings.${remainder.toString().padLeft(2, '0')}';
}

/// Pure helper (testable): profit per unit in cents, or `null` when either
/// price is unset (requirements #4: "Show profit/unit = selling − buying").
int? computeProfitPerUnitCents({
  required int? buyingPriceCents,
  required int? sellingPriceCents,
}) {
  if (buyingPriceCents == null || sellingPriceCents == null) return null;
  return sellingPriceCents - buyingPriceCents;
}

/// Pure helper (testable): finds a product in [products] whose name matches
/// [name] exactly, case-insensitively, ignoring leading/trailing whitespace
/// on both sides. Returns `null` when [name] is blank or nothing matches
/// (UAT feedback: surface "already in inventory" duplicates by name too).
Product? findExactNameMatch(String name, List<Product> products) {
  final target = name.trim().toLowerCase();
  if (target.isEmpty) return null;
  for (final product in products) {
    if (product.name.trim().toLowerCase() == target) return product;
  }
  return null;
}

/// Add Product (route `/products/add`).
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '5');

  ProductUnit _unit = ProductUnit.piece;
  String? _imagePath;
  bool _submitting = false;

  String? _nameError;
  String? _barcodeError;
  String? _buyingPriceError;
  String? _sellingPriceError;
  String? _quantityError;
  String? _thresholdError;

  // Duplicate-aware add (UAT feedback: "make it easy to add a product that
  // is already in inventory instead of writing the whole description").
  Timer? _barcodeDebounce;
  Timer? _nameDebounce;
  Product? _barcodeMatch;
  Product? _nameMatch;
  int? _dismissedMatchId;

  /// The duplicate match currently worth showing a banner for: barcode
  /// takes priority over a name match, and a dismissed match stays hidden
  /// until a *different* product matches.
  Product? get _activeMatch {
    if (_barcodeMatch != null && _barcodeMatch!.id != _dismissedMatchId) {
      return _barcodeMatch;
    }
    if (_nameMatch != null && _nameMatch!.id != _dismissedMatchId) {
      return _nameMatch;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _barcodeController.addListener(_onBarcodeChanged);
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _barcodeDebounce?.cancel();
    _nameDebounce?.cancel();
    _nameController.dispose();
    _barcodeController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _onBarcodeChanged() {
    _barcodeDebounce?.cancel();
    _barcodeDebounce = Timer(const Duration(milliseconds: 400), () {
      _lookupBarcode(_barcodeController.text);
    });
  }

  Future<void> _lookupBarcode(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) {
      if (mounted) setState(() => _barcodeMatch = null);
      return;
    }
    final match = await ref.read(productsDaoProvider).getByBarcode(trimmed);
    if (!mounted) return;
    setState(() => _barcodeMatch = match);
  }

  void _onNameChanged() {
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final products =
          ref.read(productsProvider).valueOrNull ?? const <Product>[];
      setState(
        () => _nameMatch = findExactNameMatch(_nameController.text, products),
      );
    });
  }

  Future<void> _pickImage() async {
    final path = await pickAndStoreProductImage();
    if (path == null) return;
    setState(() => _imagePath = path);
  }

  /// Opens the "Choose common product" bottom sheet (UAT feedback: "offer
  /// a catalog of common products with default prices so I don't have to
  /// type descriptions"). A row for a product already in inventory routes
  /// to Add Stock instead of prefilling.
  void _openCommonProductSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommonProductSheet(
        onSelect: _applyCommonProduct,
      ),
    );
  }

  /// Prefills the form from [product] (name, unit, buying/selling price,
  /// threshold), leaving opening stock, barcode, and image untouched.
  /// Setting `_nameController.text` fires the existing debounced name
  /// listener, so the duplicate-name banner still appears if the prefilled
  /// name later matches an existing product exactly.
  void _applyCommonProduct(CommonProduct product) {
    setState(() {
      _nameController.text = product.name;
      _buyingPriceController.text = centsToInputString(
        product.buyingPriceCents,
      );
      _sellingPriceController.text = centsToInputString(
        product.sellingPriceCents,
      );
      _thresholdController.text = '${product.threshold}';
      _unit = product.unit;
      _nameError = null;
      _buyingPriceError = null;
      _sellingPriceError = null;
      _thresholdError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prefilled from common products — adjust as needed'),
      ),
    );
  }

  Future<void> _save() async {
    if (_submitting) return;

    final name = _nameController.text.trim();
    final barcode = _barcodeController.text.trim();

    int? buyingPrice;
    int? sellingPrice;
    int? quantity;
    int? threshold;

    setState(() {
      _nameError = name.isEmpty ? 'Name is required' : null;

      _buyingPriceError = null;
      buyingPrice = null;
      if (_buyingPriceController.text.trim().isNotEmpty) {
        buyingPrice = NumericInputField.parseValue(
          _buyingPriceController.text,
          NumericInputMode.money,
        );
        if (buyingPrice == null) _buyingPriceError = 'Enter a valid amount';
      }

      _sellingPriceError = null;
      sellingPrice = null;
      if (_sellingPriceController.text.trim().isNotEmpty) {
        sellingPrice = NumericInputField.parseValue(
          _sellingPriceController.text,
          NumericInputMode.money,
        );
        if (sellingPrice == null) _sellingPriceError = 'Enter a valid amount';
      }

      final qtyText = _quantityController.text.trim().isEmpty
          ? '0'
          : _quantityController.text;
      quantity = NumericInputField.parseValue(
        qtyText,
        NumericInputMode.quantity,
      );
      _quantityError = quantity == null
          ? 'Enter a whole number of 0 or more'
          : null;

      final thresholdText = _thresholdController.text.trim().isEmpty
          ? '5'
          : _thresholdController.text;
      threshold = NumericInputField.parseValue(
        thresholdText,
        NumericInputMode.quantity,
      );
      _thresholdError = threshold == null
          ? 'Enter a whole number of 0 or more'
          : null;
    });

    if (_nameError != null ||
        _buyingPriceError != null ||
        _sellingPriceError != null ||
        _quantityError != null ||
        _thresholdError != null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final companion = ProductsCompanion.insert(
        name: name,
        barcode: Value(barcode.isEmpty ? null : barcode),
        imagePath: Value(_imagePath),
        buyingPrice: Value(buyingPrice),
        sellingPrice: Value(sellingPrice),
        unit: _unit,
        lowStockThreshold: Value(threshold!),
        createdAt: now,
        updatedAt: now,
      );
      await ref
          .read(productsDaoProvider)
          .createProduct(companion, openingQty: quantity!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name added')));
      context.pop();
    } on DukaError catch (e) {
      if (e.message.toLowerCase().contains('barcode')) {
        setState(() => _barcodeError = e.message);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profit = computeProfitPerUnitCents(
      buyingPriceCents: NumericInputField.parseValue(
        _buyingPriceController.text,
        NumericInputMode.money,
      ),
      sellingPriceCents: NumericInputField.parseValue(
        _sellingPriceController.text,
        NumericInputMode.money,
      ),
    );
    final match = _activeMatch;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Column(
        children: [
          if (match != null)
            _DuplicateProductBanner(
              product: match,
              onDismiss: () => setState(() => _dismissedMatchId = match.id),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OutlinedButton.icon(
                  onPressed: _openCommonProductSheet,
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Choose common product'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: _nameError,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                BarcodeField(
                  controller: _barcodeController,
                  label: 'Barcode (optional)',
                ),
                if (_barcodeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      _barcodeError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (!kIsWeb)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _imagePath == null
                              ? 'No image selected'
                              : 'Image: ${p.basename(_imagePath!)}',
                        ),
                      ),
                      TextButton(
                        onPressed: _pickImage,
                        child: Text(
                          _imagePath == null ? 'Add Image' : 'Change',
                        ),
                      ),
                      if (_imagePath != null)
                        TextButton(
                          onPressed: () => setState(() => _imagePath = null),
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                NumericInputField.money(
                  label: 'Buying price (optional)',
                  controller: _buyingPriceController,
                  errorText: _buyingPriceError,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                NumericInputField.money(
                  label: 'Selling price (optional)',
                  controller: _sellingPriceController,
                  errorText: _sellingPriceError,
                  onChanged: (_) => setState(() {}),
                ),
                if (profit != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Profit per unit: '),
                      if (profit < 0) const Text('-'),
                      MoneyText(profit.abs()),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                NumericInputField.quantity(
                  label: 'Opening stock',
                  controller: _quantityController,
                  errorText: _quantityError,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProductUnit>(
                  initialValue: _unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: ProductUnit.values
                      .map(
                        (u) => DropdownMenuItem(value: u, child: Text(u.label)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _unit = value);
                  },
                ),
                const SizedBox(height: 12),
                NumericInputField.quantity(
                  label: 'Low-stock threshold',
                  controller: _thresholdController,
                  errorText: _thresholdError,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Save',
                        loading: _submitting,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber "already in inventory" banner shown above the Add Product form
/// when the typed barcode or name exactly matches an existing product
/// (UAT feedback: "make it easy to add a product that is already in
/// inventory instead of writing the whole description").
class _DuplicateProductBanner extends StatelessWidget {
  const _DuplicateProductBanner({
    required this.product,
    required this.onDismiss,
  });

  final Product product;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.info_outline, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Already in inventory: ${product.name} — '
                    '${product.quantity} ${product.unit.label} in stock',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () =>
                        context.pushNamed('add-stock', extra: product.id),
                    child: const Text('Add Stock instead'),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Dismiss',
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Choose common product" bottom sheet (UAT feedback: "offer a catalog of
/// common products with default prices so I don't have to type
/// descriptions"). A catalog item already in inventory (exact, case-
/// insensitive name match) shows an "In stock" trailing label and routes
/// to Add Stock instead of prefilling.
class _CommonProductSheet extends ConsumerWidget {
  const _CommonProductSheet({required this.onSelect});

  final ValueChanged<CommonProduct> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products =
        ref.watch(productsProvider).valueOrNull ?? const <Product>[];

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose common product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: commonProducts.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = commonProducts[index];
                  final match = findExactNameMatch(item.name, products);
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Row(
                      children: [
                        Text('${item.unit.label} · Buy '),
                        MoneyText(item.buyingPriceCents),
                        const Text(' · Sell '),
                        MoneyText(item.sellingPriceCents),
                      ],
                    ),
                    trailing: match != null
                        ? Text(
                            'In stock: ${match.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (match != null) {
                        context.pushNamed('add-stock', extra: match.id);
                      } else {
                        onSelect(item);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
