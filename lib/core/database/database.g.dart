// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buyingPriceMeta = const VerificationMeta(
    'buyingPrice',
  );
  @override
  late final GeneratedColumn<int> buyingPrice = GeneratedColumn<int>(
    'buying_price',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellingPriceMeta = const VerificationMeta(
    'sellingPrice',
  );
  @override
  late final GeneratedColumn<int> sellingPrice = GeneratedColumn<int>(
    'selling_price',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProductUnit, String> unit =
      GeneratedColumn<String>(
        'unit',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ProductUnit>($ProductsTable.$converterunit);
  static const VerificationMeta _lowStockThresholdMeta = const VerificationMeta(
    'lowStockThreshold',
  );
  @override
  late final GeneratedColumn<int> lowStockThreshold = GeneratedColumn<int>(
    'low_stock_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    barcode,
    imagePath,
    buyingPrice,
    sellingPrice,
    quantity,
    unit,
    lowStockThreshold,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('buying_price')) {
      context.handle(
        _buyingPriceMeta,
        buyingPrice.isAcceptableOrUnknown(
          data['buying_price']!,
          _buyingPriceMeta,
        ),
      );
    }
    if (data.containsKey('selling_price')) {
      context.handle(
        _sellingPriceMeta,
        sellingPrice.isAcceptableOrUnknown(
          data['selling_price']!,
          _sellingPriceMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('low_stock_threshold')) {
      context.handle(
        _lowStockThresholdMeta,
        lowStockThreshold.isAcceptableOrUnknown(
          data['low_stock_threshold']!,
          _lowStockThresholdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      buyingPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}buying_price'],
      ),
      sellingPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}selling_price'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unit: $ProductsTable.$converterunit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit'],
        )!,
      ),
      lowStockThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low_stock_threshold'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProductUnit, String, String> $converterunit =
      const EnumNameConverter<ProductUnit>(ProductUnit.values);
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String name;
  final String? barcode;
  final String? imagePath;
  final int? buyingPrice;
  final int? sellingPrice;
  final int quantity;
  final ProductUnit unit;
  final int lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Product({
    required this.id,
    required this.name,
    this.barcode,
    this.imagePath,
    this.buyingPrice,
    this.sellingPrice,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || buyingPrice != null) {
      map['buying_price'] = Variable<int>(buyingPrice);
    }
    if (!nullToAbsent || sellingPrice != null) {
      map['selling_price'] = Variable<int>(sellingPrice);
    }
    map['quantity'] = Variable<int>(quantity);
    {
      map['unit'] = Variable<String>($ProductsTable.$converterunit.toSql(unit));
    }
    map['low_stock_threshold'] = Variable<int>(lowStockThreshold);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      buyingPrice: buyingPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(buyingPrice),
      sellingPrice: sellingPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(sellingPrice),
      quantity: Value(quantity),
      unit: Value(unit),
      lowStockThreshold: Value(lowStockThreshold),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      buyingPrice: serializer.fromJson<int?>(json['buyingPrice']),
      sellingPrice: serializer.fromJson<int?>(json['sellingPrice']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unit: $ProductsTable.$converterunit.fromJson(
        serializer.fromJson<String>(json['unit']),
      ),
      lowStockThreshold: serializer.fromJson<int>(json['lowStockThreshold']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'barcode': serializer.toJson<String?>(barcode),
      'imagePath': serializer.toJson<String?>(imagePath),
      'buyingPrice': serializer.toJson<int?>(buyingPrice),
      'sellingPrice': serializer.toJson<int?>(sellingPrice),
      'quantity': serializer.toJson<int>(quantity),
      'unit': serializer.toJson<String>(
        $ProductsTable.$converterunit.toJson(unit),
      ),
      'lowStockThreshold': serializer.toJson<int>(lowStockThreshold),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    Value<String?> barcode = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    Value<int?> buyingPrice = const Value.absent(),
    Value<int?> sellingPrice = const Value.absent(),
    int? quantity,
    ProductUnit? unit,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    barcode: barcode.present ? barcode.value : this.barcode,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    buyingPrice: buyingPrice.present ? buyingPrice.value : this.buyingPrice,
    sellingPrice: sellingPrice.present ? sellingPrice.value : this.sellingPrice,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      buyingPrice: data.buyingPrice.present
          ? data.buyingPrice.value
          : this.buyingPrice,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('imagePath: $imagePath, ')
          ..write('buyingPrice: $buyingPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    barcode,
    imagePath,
    buyingPrice,
    sellingPrice,
    quantity,
    unit,
    lowStockThreshold,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.barcode == this.barcode &&
          other.imagePath == this.imagePath &&
          other.buyingPrice == this.buyingPrice &&
          other.sellingPrice == this.sellingPrice &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.lowStockThreshold == this.lowStockThreshold &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> barcode;
  final Value<String?> imagePath;
  final Value<int?> buyingPrice;
  final Value<int?> sellingPrice;
  final Value<int> quantity;
  final Value<ProductUnit> unit;
  final Value<int> lowStockThreshold;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.barcode = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.buyingPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.barcode = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.buyingPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.quantity = const Value.absent(),
    required ProductUnit unit,
    this.lowStockThreshold = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       unit = Value(unit),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? barcode,
    Expression<String>? imagePath,
    Expression<int>? buyingPrice,
    Expression<int>? sellingPrice,
    Expression<int>? quantity,
    Expression<String>? unit,
    Expression<int>? lowStockThreshold,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (barcode != null) 'barcode': barcode,
      if (imagePath != null) 'image_path': imagePath,
      if (buyingPrice != null) 'buying_price': buyingPrice,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? barcode,
    Value<String?>? imagePath,
    Value<int?>? buyingPrice,
    Value<int?>? sellingPrice,
    Value<int>? quantity,
    Value<ProductUnit>? unit,
    Value<int>? lowStockThreshold,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (buyingPrice.present) {
      map['buying_price'] = Variable<int>(buyingPrice.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<int>(sellingPrice.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(
        $ProductsTable.$converterunit.toSql(unit.value),
      );
    }
    if (lowStockThreshold.present) {
      map['low_stock_threshold'] = Variable<int>(lowStockThreshold.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('imagePath: $imagePath, ')
          ..write('buyingPrice: $buyingPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<int> subtotal = GeneratedColumn<int>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PaymentMethod, String>
  paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PaymentMethod>($SalesTable.$converterpaymentMethod);
  static const VerificationMeta _amountReceivedMeta = const VerificationMeta(
    'amountReceived',
  );
  @override
  late final GeneratedColumn<int> amountReceived = GeneratedColumn<int>(
    'amount_received',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changeAmountMeta = const VerificationMeta(
    'changeAmount',
  );
  @override
  late final GeneratedColumn<int> changeAmount = GeneratedColumn<int>(
    'change_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mpesaCodeMeta = const VerificationMeta(
    'mpesaCode',
  );
  @override
  late final GeneratedColumn<String> mpesaCode = GeneratedColumn<String>(
    'mpesa_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subtotal,
    total,
    paymentMethod,
    amountReceived,
    changeAmount,
    mpesaCode,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('amount_received')) {
      context.handle(
        _amountReceivedMeta,
        amountReceived.isAcceptableOrUnknown(
          data['amount_received']!,
          _amountReceivedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountReceivedMeta);
    }
    if (data.containsKey('change_amount')) {
      context.handle(
        _changeAmountMeta,
        changeAmount.isAcceptableOrUnknown(
          data['change_amount']!,
          _changeAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changeAmountMeta);
    }
    if (data.containsKey('mpesa_code')) {
      context.handle(
        _mpesaCodeMeta,
        mpesaCode.isAcceptableOrUnknown(data['mpesa_code']!, _mpesaCodeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      paymentMethod: $SalesTable.$converterpaymentMethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}payment_method'],
        )!,
      ),
      amountReceived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_received'],
      )!,
      changeAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_amount'],
      )!,
      mpesaCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mpesa_code'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PaymentMethod, String, String>
  $converterpaymentMethod = const EnumNameConverter<PaymentMethod>(
    PaymentMethod.values,
  );
}

class Sale extends DataClass implements Insertable<Sale> {
  final int id;
  final int subtotal;
  final int total;
  final PaymentMethod paymentMethod;
  final int amountReceived;
  final int changeAmount;
  final String? mpesaCode;
  final DateTime createdAt;
  const Sale({
    required this.id,
    required this.subtotal,
    required this.total,
    required this.paymentMethod,
    required this.amountReceived,
    required this.changeAmount,
    this.mpesaCode,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subtotal'] = Variable<int>(subtotal);
    map['total'] = Variable<int>(total);
    {
      map['payment_method'] = Variable<String>(
        $SalesTable.$converterpaymentMethod.toSql(paymentMethod),
      );
    }
    map['amount_received'] = Variable<int>(amountReceived);
    map['change_amount'] = Variable<int>(changeAmount);
    if (!nullToAbsent || mpesaCode != null) {
      map['mpesa_code'] = Variable<String>(mpesaCode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      subtotal: Value(subtotal),
      total: Value(total),
      paymentMethod: Value(paymentMethod),
      amountReceived: Value(amountReceived),
      changeAmount: Value(changeAmount),
      mpesaCode: mpesaCode == null && nullToAbsent
          ? const Value.absent()
          : Value(mpesaCode),
      createdAt: Value(createdAt),
    );
  }

  factory Sale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<int>(json['id']),
      subtotal: serializer.fromJson<int>(json['subtotal']),
      total: serializer.fromJson<int>(json['total']),
      paymentMethod: $SalesTable.$converterpaymentMethod.fromJson(
        serializer.fromJson<String>(json['paymentMethod']),
      ),
      amountReceived: serializer.fromJson<int>(json['amountReceived']),
      changeAmount: serializer.fromJson<int>(json['changeAmount']),
      mpesaCode: serializer.fromJson<String?>(json['mpesaCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subtotal': serializer.toJson<int>(subtotal),
      'total': serializer.toJson<int>(total),
      'paymentMethod': serializer.toJson<String>(
        $SalesTable.$converterpaymentMethod.toJson(paymentMethod),
      ),
      'amountReceived': serializer.toJson<int>(amountReceived),
      'changeAmount': serializer.toJson<int>(changeAmount),
      'mpesaCode': serializer.toJson<String?>(mpesaCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Sale copyWith({
    int? id,
    int? subtotal,
    int? total,
    PaymentMethod? paymentMethod,
    int? amountReceived,
    int? changeAmount,
    Value<String?> mpesaCode = const Value.absent(),
    DateTime? createdAt,
  }) => Sale(
    id: id ?? this.id,
    subtotal: subtotal ?? this.subtotal,
    total: total ?? this.total,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    amountReceived: amountReceived ?? this.amountReceived,
    changeAmount: changeAmount ?? this.changeAmount,
    mpesaCode: mpesaCode.present ? mpesaCode.value : this.mpesaCode,
    createdAt: createdAt ?? this.createdAt,
  );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      total: data.total.present ? data.total.value : this.total,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      amountReceived: data.amountReceived.present
          ? data.amountReceived.value
          : this.amountReceived,
      changeAmount: data.changeAmount.present
          ? data.changeAmount.value
          : this.changeAmount,
      mpesaCode: data.mpesaCode.present ? data.mpesaCode.value : this.mpesaCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('subtotal: $subtotal, ')
          ..write('total: $total, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('amountReceived: $amountReceived, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('mpesaCode: $mpesaCode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subtotal,
    total,
    paymentMethod,
    amountReceived,
    changeAmount,
    mpesaCode,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.subtotal == this.subtotal &&
          other.total == this.total &&
          other.paymentMethod == this.paymentMethod &&
          other.amountReceived == this.amountReceived &&
          other.changeAmount == this.changeAmount &&
          other.mpesaCode == this.mpesaCode &&
          other.createdAt == this.createdAt);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<int> id;
  final Value<int> subtotal;
  final Value<int> total;
  final Value<PaymentMethod> paymentMethod;
  final Value<int> amountReceived;
  final Value<int> changeAmount;
  final Value<String?> mpesaCode;
  final Value<DateTime> createdAt;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.total = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.amountReceived = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.mpesaCode = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SalesCompanion.insert({
    this.id = const Value.absent(),
    required int subtotal,
    required int total,
    required PaymentMethod paymentMethod,
    required int amountReceived,
    required int changeAmount,
    this.mpesaCode = const Value.absent(),
    required DateTime createdAt,
  }) : subtotal = Value(subtotal),
       total = Value(total),
       paymentMethod = Value(paymentMethod),
       amountReceived = Value(amountReceived),
       changeAmount = Value(changeAmount),
       createdAt = Value(createdAt);
  static Insertable<Sale> custom({
    Expression<int>? id,
    Expression<int>? subtotal,
    Expression<int>? total,
    Expression<String>? paymentMethod,
    Expression<int>? amountReceived,
    Expression<int>? changeAmount,
    Expression<String>? mpesaCode,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subtotal != null) 'subtotal': subtotal,
      if (total != null) 'total': total,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (amountReceived != null) 'amount_received': amountReceived,
      if (changeAmount != null) 'change_amount': changeAmount,
      if (mpesaCode != null) 'mpesa_code': mpesaCode,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SalesCompanion copyWith({
    Value<int>? id,
    Value<int>? subtotal,
    Value<int>? total,
    Value<PaymentMethod>? paymentMethod,
    Value<int>? amountReceived,
    Value<int>? changeAmount,
    Value<String?>? mpesaCode,
    Value<DateTime>? createdAt,
  }) {
    return SalesCompanion(
      id: id ?? this.id,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: amountReceived ?? this.amountReceived,
      changeAmount: changeAmount ?? this.changeAmount,
      mpesaCode: mpesaCode ?? this.mpesaCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<int>(subtotal.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(
        $SalesTable.$converterpaymentMethod.toSql(paymentMethod.value),
      );
    }
    if (amountReceived.present) {
      map['amount_received'] = Variable<int>(amountReceived.value);
    }
    if (changeAmount.present) {
      map['change_amount'] = Variable<int>(changeAmount.value);
    }
    if (mpesaCode.present) {
      map['mpesa_code'] = Variable<String>(mpesaCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('subtotal: $subtotal, ')
          ..write('total: $total, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('amountReceived: $amountReceived, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('mpesaCode: $mpesaCode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SaleItemsTable extends SaleItems
    with TableInfo<$SaleItemsTable, SaleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<int> saleId = GeneratedColumn<int>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyingPriceSnapshotMeta =
      const VerificationMeta('buyingPriceSnapshot');
  @override
  late final GeneratedColumn<int> buyingPriceSnapshot = GeneratedColumn<int>(
    'buying_price_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellingPriceSnapshotMeta =
      const VerificationMeta('sellingPriceSnapshot');
  @override
  late final GeneratedColumn<int> sellingPriceSnapshot = GeneratedColumn<int>(
    'selling_price_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    productId,
    productName,
    quantity,
    buyingPriceSnapshot,
    sellingPriceSnapshot,
    total,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('buying_price_snapshot')) {
      context.handle(
        _buyingPriceSnapshotMeta,
        buyingPriceSnapshot.isAcceptableOrUnknown(
          data['buying_price_snapshot']!,
          _buyingPriceSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_buyingPriceSnapshotMeta);
    }
    if (data.containsKey('selling_price_snapshot')) {
      context.handle(
        _sellingPriceSnapshotMeta,
        sellingPriceSnapshot.isAcceptableOrUnknown(
          data['selling_price_snapshot']!,
          _sellingPriceSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sellingPriceSnapshotMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sale_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      buyingPriceSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}buying_price_snapshot'],
      )!,
      sellingPriceSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}selling_price_snapshot'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
    );
  }

  @override
  $SaleItemsTable createAlias(String alias) {
    return $SaleItemsTable(attachedDatabase, alias);
  }
}

class SaleItem extends DataClass implements Insertable<SaleItem> {
  final int id;
  final int saleId;
  final int productId;
  final String productName;
  final int quantity;
  final int buyingPriceSnapshot;
  final int sellingPriceSnapshot;
  final int total;
  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.buyingPriceSnapshot,
    required this.sellingPriceSnapshot,
    required this.total,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_id'] = Variable<int>(saleId);
    map['product_id'] = Variable<int>(productId);
    map['product_name'] = Variable<String>(productName);
    map['quantity'] = Variable<int>(quantity);
    map['buying_price_snapshot'] = Variable<int>(buyingPriceSnapshot);
    map['selling_price_snapshot'] = Variable<int>(sellingPriceSnapshot);
    map['total'] = Variable<int>(total);
    return map;
  }

  SaleItemsCompanion toCompanion(bool nullToAbsent) {
    return SaleItemsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: Value(productId),
      productName: Value(productName),
      quantity: Value(quantity),
      buyingPriceSnapshot: Value(buyingPriceSnapshot),
      sellingPriceSnapshot: Value(sellingPriceSnapshot),
      total: Value(total),
    );
  }

  factory SaleItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItem(
      id: serializer.fromJson<int>(json['id']),
      saleId: serializer.fromJson<int>(json['saleId']),
      productId: serializer.fromJson<int>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      quantity: serializer.fromJson<int>(json['quantity']),
      buyingPriceSnapshot: serializer.fromJson<int>(
        json['buyingPriceSnapshot'],
      ),
      sellingPriceSnapshot: serializer.fromJson<int>(
        json['sellingPriceSnapshot'],
      ),
      total: serializer.fromJson<int>(json['total']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleId': serializer.toJson<int>(saleId),
      'productId': serializer.toJson<int>(productId),
      'productName': serializer.toJson<String>(productName),
      'quantity': serializer.toJson<int>(quantity),
      'buyingPriceSnapshot': serializer.toJson<int>(buyingPriceSnapshot),
      'sellingPriceSnapshot': serializer.toJson<int>(sellingPriceSnapshot),
      'total': serializer.toJson<int>(total),
    };
  }

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? productName,
    int? quantity,
    int? buyingPriceSnapshot,
    int? sellingPriceSnapshot,
    int? total,
  }) => SaleItem(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    quantity: quantity ?? this.quantity,
    buyingPriceSnapshot: buyingPriceSnapshot ?? this.buyingPriceSnapshot,
    sellingPriceSnapshot: sellingPriceSnapshot ?? this.sellingPriceSnapshot,
    total: total ?? this.total,
  );
  SaleItem copyWithCompanion(SaleItemsCompanion data) {
    return SaleItem(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      buyingPriceSnapshot: data.buyingPriceSnapshot.present
          ? data.buyingPriceSnapshot.value
          : this.buyingPriceSnapshot,
      sellingPriceSnapshot: data.sellingPriceSnapshot.present
          ? data.sellingPriceSnapshot.value
          : this.sellingPriceSnapshot,
      total: data.total.present ? data.total.value : this.total,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItem(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('buyingPriceSnapshot: $buyingPriceSnapshot, ')
          ..write('sellingPriceSnapshot: $sellingPriceSnapshot, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    productId,
    productName,
    quantity,
    buyingPriceSnapshot,
    sellingPriceSnapshot,
    total,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItem &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.buyingPriceSnapshot == this.buyingPriceSnapshot &&
          other.sellingPriceSnapshot == this.sellingPriceSnapshot &&
          other.total == this.total);
}

class SaleItemsCompanion extends UpdateCompanion<SaleItem> {
  final Value<int> id;
  final Value<int> saleId;
  final Value<int> productId;
  final Value<String> productName;
  final Value<int> quantity;
  final Value<int> buyingPriceSnapshot;
  final Value<int> sellingPriceSnapshot;
  final Value<int> total;
  const SaleItemsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.buyingPriceSnapshot = const Value.absent(),
    this.sellingPriceSnapshot = const Value.absent(),
    this.total = const Value.absent(),
  });
  SaleItemsCompanion.insert({
    this.id = const Value.absent(),
    required int saleId,
    required int productId,
    required String productName,
    required int quantity,
    required int buyingPriceSnapshot,
    required int sellingPriceSnapshot,
    required int total,
  }) : saleId = Value(saleId),
       productId = Value(productId),
       productName = Value(productName),
       quantity = Value(quantity),
       buyingPriceSnapshot = Value(buyingPriceSnapshot),
       sellingPriceSnapshot = Value(sellingPriceSnapshot),
       total = Value(total);
  static Insertable<SaleItem> custom({
    Expression<int>? id,
    Expression<int>? saleId,
    Expression<int>? productId,
    Expression<String>? productName,
    Expression<int>? quantity,
    Expression<int>? buyingPriceSnapshot,
    Expression<int>? sellingPriceSnapshot,
    Expression<int>? total,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (buyingPriceSnapshot != null)
        'buying_price_snapshot': buyingPriceSnapshot,
      if (sellingPriceSnapshot != null)
        'selling_price_snapshot': sellingPriceSnapshot,
      if (total != null) 'total': total,
    });
  }

  SaleItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? saleId,
    Value<int>? productId,
    Value<String>? productName,
    Value<int>? quantity,
    Value<int>? buyingPriceSnapshot,
    Value<int>? sellingPriceSnapshot,
    Value<int>? total,
  }) {
    return SaleItemsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      buyingPriceSnapshot: buyingPriceSnapshot ?? this.buyingPriceSnapshot,
      sellingPriceSnapshot: sellingPriceSnapshot ?? this.sellingPriceSnapshot,
      total: total ?? this.total,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<int>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (buyingPriceSnapshot.present) {
      map['buying_price_snapshot'] = Variable<int>(buyingPriceSnapshot.value);
    }
    if (sellingPriceSnapshot.present) {
      map['selling_price_snapshot'] = Variable<int>(sellingPriceSnapshot.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('buyingPriceSnapshot: $buyingPriceSnapshot, ')
          ..write('sellingPriceSnapshot: $sellingPriceSnapshot, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExpenseCategory, String>
  category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ExpenseCategory>($ExpensesTable.$convertercategory);
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PaymentMethod, String>
  paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PaymentMethod>($ExpensesTable.$converterpaymentMethod);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    category,
    description,
    paymentMethod,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      category: $ExpensesTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      paymentMethod: $ExpensesTable.$converterpaymentMethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}payment_method'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExpenseCategory, String, String>
  $convertercategory = const EnumNameConverter<ExpenseCategory>(
    ExpenseCategory.values,
  );
  static JsonTypeConverter2<PaymentMethod, String, String>
  $converterpaymentMethod = const EnumNameConverter<PaymentMethod>(
    PaymentMethod.values,
  );
}

class Expense extends DataClass implements Insertable<Expense> {
  final int id;
  final int amount;
  final ExpenseCategory category;
  final String? description;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.paymentMethod,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<int>(amount);
    {
      map['category'] = Variable<String>(
        $ExpensesTable.$convertercategory.toSql(category),
      );
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    {
      map['payment_method'] = Variable<String>(
        $ExpensesTable.$converterpaymentMethod.toSql(paymentMethod),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      amount: Value(amount),
      category: Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      paymentMethod: Value(paymentMethod),
      createdAt: Value(createdAt),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<int>(json['amount']),
      category: $ExpensesTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      description: serializer.fromJson<String?>(json['description']),
      paymentMethod: $ExpensesTable.$converterpaymentMethod.fromJson(
        serializer.fromJson<String>(json['paymentMethod']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<int>(amount),
      'category': serializer.toJson<String>(
        $ExpensesTable.$convertercategory.toJson(category),
      ),
      'description': serializer.toJson<String?>(description),
      'paymentMethod': serializer.toJson<String>(
        $ExpensesTable.$converterpaymentMethod.toJson(paymentMethod),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Expense copyWith({
    int? id,
    int? amount,
    ExpenseCategory? category,
    Value<String?> description = const Value.absent(),
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
  }) => Expense(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    description: description.present ? description.value : this.description,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    createdAt: createdAt ?? this.createdAt,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, amount, category, description, paymentMethod, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.description == this.description &&
          other.paymentMethod == this.paymentMethod &&
          other.createdAt == this.createdAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<int> id;
  final Value<int> amount;
  final Value<ExpenseCategory> category;
  final Value<String?> description;
  final Value<PaymentMethod> paymentMethod;
  final Value<DateTime> createdAt;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required int amount,
    required ExpenseCategory category,
    this.description = const Value.absent(),
    required PaymentMethod paymentMethod,
    required DateTime createdAt,
  }) : amount = Value(amount),
       category = Value(category),
       paymentMethod = Value(paymentMethod),
       createdAt = Value(createdAt);
  static Insertable<Expense> custom({
    Expression<int>? id,
    Expression<int>? amount,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? paymentMethod,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExpensesCompanion copyWith({
    Value<int>? id,
    Value<int>? amount,
    Value<ExpenseCategory>? category,
    Value<String?>? description,
    Value<PaymentMethod>? paymentMethod,
    Value<DateTime>? createdAt,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $ExpensesTable.$convertercategory.toSql(category.value),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(
        $ExpensesTable.$converterpaymentMethod.toSql(paymentMethod.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTable extends StockMovements
    with TableInfo<$StockMovementsTable, StockMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MovementType, String>
  movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<MovementType>($StockMovementsTable.$convertermovementType);
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<int> referenceId = GeneratedColumn<int>(
    'reference_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    movementType,
    quantity,
    note,
    referenceId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      movementType: $StockMovementsTable.$convertermovementType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}movement_type'],
        )!,
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reference_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StockMovementsTable createAlias(String alias) {
    return $StockMovementsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MovementType, String, String>
  $convertermovementType = const EnumNameConverter<MovementType>(
    MovementType.values,
  );
}

class StockMovement extends DataClass implements Insertable<StockMovement> {
  final int id;
  final int productId;
  final MovementType movementType;
  final int quantity;
  final String? note;
  final int? referenceId;
  final DateTime createdAt;
  const StockMovement({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.quantity,
    this.note,
    this.referenceId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    {
      map['movement_type'] = Variable<String>(
        $StockMovementsTable.$convertermovementType.toSql(movementType),
      );
    }
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<int>(referenceId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StockMovementsCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsCompanion(
      id: Value(id),
      productId: Value(productId),
      movementType: Value(movementType),
      quantity: Value(quantity),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      referenceId: referenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceId),
      createdAt: Value(createdAt),
    );
  }

  factory StockMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovement(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      movementType: $StockMovementsTable.$convertermovementType.fromJson(
        serializer.fromJson<String>(json['movementType']),
      ),
      quantity: serializer.fromJson<int>(json['quantity']),
      note: serializer.fromJson<String?>(json['note']),
      referenceId: serializer.fromJson<int?>(json['referenceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'movementType': serializer.toJson<String>(
        $StockMovementsTable.$convertermovementType.toJson(movementType),
      ),
      'quantity': serializer.toJson<int>(quantity),
      'note': serializer.toJson<String?>(note),
      'referenceId': serializer.toJson<int?>(referenceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StockMovement copyWith({
    int? id,
    int? productId,
    MovementType? movementType,
    int? quantity,
    Value<String?> note = const Value.absent(),
    Value<int?> referenceId = const Value.absent(),
    DateTime? createdAt,
  }) => StockMovement(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    movementType: movementType ?? this.movementType,
    quantity: quantity ?? this.quantity,
    note: note.present ? note.value : this.note,
    referenceId: referenceId.present ? referenceId.value : this.referenceId,
    createdAt: createdAt ?? this.createdAt,
  );
  StockMovement copyWithCompanion(StockMovementsCompanion data) {
    return StockMovement(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      note: data.note.present ? data.note.value : this.note,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovement(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('movementType: $movementType, ')
          ..write('quantity: $quantity, ')
          ..write('note: $note, ')
          ..write('referenceId: $referenceId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    movementType,
    quantity,
    note,
    referenceId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovement &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.movementType == this.movementType &&
          other.quantity == this.quantity &&
          other.note == this.note &&
          other.referenceId == this.referenceId &&
          other.createdAt == this.createdAt);
}

class StockMovementsCompanion extends UpdateCompanion<StockMovement> {
  final Value<int> id;
  final Value<int> productId;
  final Value<MovementType> movementType;
  final Value<int> quantity;
  final Value<String?> note;
  final Value<int?> referenceId;
  final Value<DateTime> createdAt;
  const StockMovementsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.movementType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.note = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StockMovementsCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required MovementType movementType,
    required int quantity,
    this.note = const Value.absent(),
    this.referenceId = const Value.absent(),
    required DateTime createdAt,
  }) : productId = Value(productId),
       movementType = Value(movementType),
       quantity = Value(quantity),
       createdAt = Value(createdAt);
  static Insertable<StockMovement> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<String>? movementType,
    Expression<int>? quantity,
    Expression<String>? note,
    Expression<int>? referenceId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (movementType != null) 'movement_type': movementType,
      if (quantity != null) 'quantity': quantity,
      if (note != null) 'note': note,
      if (referenceId != null) 'reference_id': referenceId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StockMovementsCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<MovementType>? movementType,
    Value<int>? quantity,
    Value<String?>? note,
    Value<int?>? referenceId,
    Value<DateTime>? createdAt,
  }) {
    return StockMovementsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(
        $StockMovementsTable.$convertermovementType.toSql(movementType.value),
      );
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<int>(referenceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('movementType: $movementType, ')
          ..write('quantity: $quantity, ')
          ..write('note: $note, ')
          ..write('referenceId: $referenceId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DailyClosesTable extends DailyCloses
    with TableInfo<$DailyClosesTable, DailyClose> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyClosesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _totalSalesMeta = const VerificationMeta(
    'totalSales',
  );
  @override
  late final GeneratedColumn<int> totalSales = GeneratedColumn<int>(
    'total_sales',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashSalesMeta = const VerificationMeta(
    'cashSales',
  );
  @override
  late final GeneratedColumn<int> cashSales = GeneratedColumn<int>(
    'cash_sales',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mpesaSalesMeta = const VerificationMeta(
    'mpesaSales',
  );
  @override
  late final GeneratedColumn<int> mpesaSales = GeneratedColumn<int>(
    'mpesa_sales',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expensesMeta = const VerificationMeta(
    'expenses',
  );
  @override
  late final GeneratedColumn<int> expenses = GeneratedColumn<int>(
    'expenses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costOfGoodsMeta = const VerificationMeta(
    'costOfGoods',
  );
  @override
  late final GeneratedColumn<int> costOfGoods = GeneratedColumn<int>(
    'cost_of_goods',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grossProfitMeta = const VerificationMeta(
    'grossProfit',
  );
  @override
  late final GeneratedColumn<int> grossProfit = GeneratedColumn<int>(
    'gross_profit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _netResultMeta = const VerificationMeta(
    'netResult',
  );
  @override
  late final GeneratedColumn<int> netResult = GeneratedColumn<int>(
    'net_result',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedCashMeta = const VerificationMeta(
    'expectedCash',
  );
  @override
  late final GeneratedColumn<int> expectedCash = GeneratedColumn<int>(
    'expected_cash',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualCashMeta = const VerificationMeta(
    'actualCash',
  );
  @override
  late final GeneratedColumn<int> actualCash = GeneratedColumn<int>(
    'actual_cash',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashDifferenceMeta = const VerificationMeta(
    'cashDifference',
  );
  @override
  late final GeneratedColumn<int> cashDifference = GeneratedColumn<int>(
    'cash_difference',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    totalSales,
    cashSales,
    mpesaSales,
    expenses,
    costOfGoods,
    grossProfit,
    netResult,
    expectedCash,
    actualCash,
    cashDifference,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_closes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyClose> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_sales')) {
      context.handle(
        _totalSalesMeta,
        totalSales.isAcceptableOrUnknown(data['total_sales']!, _totalSalesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSalesMeta);
    }
    if (data.containsKey('cash_sales')) {
      context.handle(
        _cashSalesMeta,
        cashSales.isAcceptableOrUnknown(data['cash_sales']!, _cashSalesMeta),
      );
    } else if (isInserting) {
      context.missing(_cashSalesMeta);
    }
    if (data.containsKey('mpesa_sales')) {
      context.handle(
        _mpesaSalesMeta,
        mpesaSales.isAcceptableOrUnknown(data['mpesa_sales']!, _mpesaSalesMeta),
      );
    } else if (isInserting) {
      context.missing(_mpesaSalesMeta);
    }
    if (data.containsKey('expenses')) {
      context.handle(
        _expensesMeta,
        expenses.isAcceptableOrUnknown(data['expenses']!, _expensesMeta),
      );
    } else if (isInserting) {
      context.missing(_expensesMeta);
    }
    if (data.containsKey('cost_of_goods')) {
      context.handle(
        _costOfGoodsMeta,
        costOfGoods.isAcceptableOrUnknown(
          data['cost_of_goods']!,
          _costOfGoodsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costOfGoodsMeta);
    }
    if (data.containsKey('gross_profit')) {
      context.handle(
        _grossProfitMeta,
        grossProfit.isAcceptableOrUnknown(
          data['gross_profit']!,
          _grossProfitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grossProfitMeta);
    }
    if (data.containsKey('net_result')) {
      context.handle(
        _netResultMeta,
        netResult.isAcceptableOrUnknown(data['net_result']!, _netResultMeta),
      );
    } else if (isInserting) {
      context.missing(_netResultMeta);
    }
    if (data.containsKey('expected_cash')) {
      context.handle(
        _expectedCashMeta,
        expectedCash.isAcceptableOrUnknown(
          data['expected_cash']!,
          _expectedCashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedCashMeta);
    }
    if (data.containsKey('actual_cash')) {
      context.handle(
        _actualCashMeta,
        actualCash.isAcceptableOrUnknown(data['actual_cash']!, _actualCashMeta),
      );
    } else if (isInserting) {
      context.missing(_actualCashMeta);
    }
    if (data.containsKey('cash_difference')) {
      context.handle(
        _cashDifferenceMeta,
        cashDifference.isAcceptableOrUnknown(
          data['cash_difference']!,
          _cashDifferenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashDifferenceMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyClose map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyClose(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      totalSales: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_sales'],
      )!,
      cashSales: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_sales'],
      )!,
      mpesaSales: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mpesa_sales'],
      )!,
      expenses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expenses'],
      )!,
      costOfGoods: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_of_goods'],
      )!,
      grossProfit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gross_profit'],
      )!,
      netResult: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}net_result'],
      )!,
      expectedCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_cash'],
      )!,
      actualCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_cash'],
      )!,
      cashDifference: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_difference'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DailyClosesTable createAlias(String alias) {
    return $DailyClosesTable(attachedDatabase, alias);
  }
}

class DailyClose extends DataClass implements Insertable<DailyClose> {
  final int id;
  final DateTime date;
  final int totalSales;
  final int cashSales;
  final int mpesaSales;
  final int expenses;
  final int costOfGoods;
  final int grossProfit;
  final int netResult;
  final int expectedCash;
  final int actualCash;
  final int cashDifference;
  final String? note;
  final DateTime createdAt;
  const DailyClose({
    required this.id,
    required this.date,
    required this.totalSales,
    required this.cashSales,
    required this.mpesaSales,
    required this.expenses,
    required this.costOfGoods,
    required this.grossProfit,
    required this.netResult,
    required this.expectedCash,
    required this.actualCash,
    required this.cashDifference,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['total_sales'] = Variable<int>(totalSales);
    map['cash_sales'] = Variable<int>(cashSales);
    map['mpesa_sales'] = Variable<int>(mpesaSales);
    map['expenses'] = Variable<int>(expenses);
    map['cost_of_goods'] = Variable<int>(costOfGoods);
    map['gross_profit'] = Variable<int>(grossProfit);
    map['net_result'] = Variable<int>(netResult);
    map['expected_cash'] = Variable<int>(expectedCash);
    map['actual_cash'] = Variable<int>(actualCash);
    map['cash_difference'] = Variable<int>(cashDifference);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DailyClosesCompanion toCompanion(bool nullToAbsent) {
    return DailyClosesCompanion(
      id: Value(id),
      date: Value(date),
      totalSales: Value(totalSales),
      cashSales: Value(cashSales),
      mpesaSales: Value(mpesaSales),
      expenses: Value(expenses),
      costOfGoods: Value(costOfGoods),
      grossProfit: Value(grossProfit),
      netResult: Value(netResult),
      expectedCash: Value(expectedCash),
      actualCash: Value(actualCash),
      cashDifference: Value(cashDifference),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory DailyClose.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyClose(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      totalSales: serializer.fromJson<int>(json['totalSales']),
      cashSales: serializer.fromJson<int>(json['cashSales']),
      mpesaSales: serializer.fromJson<int>(json['mpesaSales']),
      expenses: serializer.fromJson<int>(json['expenses']),
      costOfGoods: serializer.fromJson<int>(json['costOfGoods']),
      grossProfit: serializer.fromJson<int>(json['grossProfit']),
      netResult: serializer.fromJson<int>(json['netResult']),
      expectedCash: serializer.fromJson<int>(json['expectedCash']),
      actualCash: serializer.fromJson<int>(json['actualCash']),
      cashDifference: serializer.fromJson<int>(json['cashDifference']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'totalSales': serializer.toJson<int>(totalSales),
      'cashSales': serializer.toJson<int>(cashSales),
      'mpesaSales': serializer.toJson<int>(mpesaSales),
      'expenses': serializer.toJson<int>(expenses),
      'costOfGoods': serializer.toJson<int>(costOfGoods),
      'grossProfit': serializer.toJson<int>(grossProfit),
      'netResult': serializer.toJson<int>(netResult),
      'expectedCash': serializer.toJson<int>(expectedCash),
      'actualCash': serializer.toJson<int>(actualCash),
      'cashDifference': serializer.toJson<int>(cashDifference),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DailyClose copyWith({
    int? id,
    DateTime? date,
    int? totalSales,
    int? cashSales,
    int? mpesaSales,
    int? expenses,
    int? costOfGoods,
    int? grossProfit,
    int? netResult,
    int? expectedCash,
    int? actualCash,
    int? cashDifference,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => DailyClose(
    id: id ?? this.id,
    date: date ?? this.date,
    totalSales: totalSales ?? this.totalSales,
    cashSales: cashSales ?? this.cashSales,
    mpesaSales: mpesaSales ?? this.mpesaSales,
    expenses: expenses ?? this.expenses,
    costOfGoods: costOfGoods ?? this.costOfGoods,
    grossProfit: grossProfit ?? this.grossProfit,
    netResult: netResult ?? this.netResult,
    expectedCash: expectedCash ?? this.expectedCash,
    actualCash: actualCash ?? this.actualCash,
    cashDifference: cashDifference ?? this.cashDifference,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  DailyClose copyWithCompanion(DailyClosesCompanion data) {
    return DailyClose(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      totalSales: data.totalSales.present
          ? data.totalSales.value
          : this.totalSales,
      cashSales: data.cashSales.present ? data.cashSales.value : this.cashSales,
      mpesaSales: data.mpesaSales.present
          ? data.mpesaSales.value
          : this.mpesaSales,
      expenses: data.expenses.present ? data.expenses.value : this.expenses,
      costOfGoods: data.costOfGoods.present
          ? data.costOfGoods.value
          : this.costOfGoods,
      grossProfit: data.grossProfit.present
          ? data.grossProfit.value
          : this.grossProfit,
      netResult: data.netResult.present ? data.netResult.value : this.netResult,
      expectedCash: data.expectedCash.present
          ? data.expectedCash.value
          : this.expectedCash,
      actualCash: data.actualCash.present
          ? data.actualCash.value
          : this.actualCash,
      cashDifference: data.cashDifference.present
          ? data.cashDifference.value
          : this.cashDifference,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyClose(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('totalSales: $totalSales, ')
          ..write('cashSales: $cashSales, ')
          ..write('mpesaSales: $mpesaSales, ')
          ..write('expenses: $expenses, ')
          ..write('costOfGoods: $costOfGoods, ')
          ..write('grossProfit: $grossProfit, ')
          ..write('netResult: $netResult, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('actualCash: $actualCash, ')
          ..write('cashDifference: $cashDifference, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    totalSales,
    cashSales,
    mpesaSales,
    expenses,
    costOfGoods,
    grossProfit,
    netResult,
    expectedCash,
    actualCash,
    cashDifference,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyClose &&
          other.id == this.id &&
          other.date == this.date &&
          other.totalSales == this.totalSales &&
          other.cashSales == this.cashSales &&
          other.mpesaSales == this.mpesaSales &&
          other.expenses == this.expenses &&
          other.costOfGoods == this.costOfGoods &&
          other.grossProfit == this.grossProfit &&
          other.netResult == this.netResult &&
          other.expectedCash == this.expectedCash &&
          other.actualCash == this.actualCash &&
          other.cashDifference == this.cashDifference &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class DailyClosesCompanion extends UpdateCompanion<DailyClose> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> totalSales;
  final Value<int> cashSales;
  final Value<int> mpesaSales;
  final Value<int> expenses;
  final Value<int> costOfGoods;
  final Value<int> grossProfit;
  final Value<int> netResult;
  final Value<int> expectedCash;
  final Value<int> actualCash;
  final Value<int> cashDifference;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const DailyClosesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.totalSales = const Value.absent(),
    this.cashSales = const Value.absent(),
    this.mpesaSales = const Value.absent(),
    this.expenses = const Value.absent(),
    this.costOfGoods = const Value.absent(),
    this.grossProfit = const Value.absent(),
    this.netResult = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.actualCash = const Value.absent(),
    this.cashDifference = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DailyClosesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required int totalSales,
    required int cashSales,
    required int mpesaSales,
    required int expenses,
    required int costOfGoods,
    required int grossProfit,
    required int netResult,
    required int expectedCash,
    required int actualCash,
    required int cashDifference,
    this.note = const Value.absent(),
    required DateTime createdAt,
  }) : date = Value(date),
       totalSales = Value(totalSales),
       cashSales = Value(cashSales),
       mpesaSales = Value(mpesaSales),
       expenses = Value(expenses),
       costOfGoods = Value(costOfGoods),
       grossProfit = Value(grossProfit),
       netResult = Value(netResult),
       expectedCash = Value(expectedCash),
       actualCash = Value(actualCash),
       cashDifference = Value(cashDifference),
       createdAt = Value(createdAt);
  static Insertable<DailyClose> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? totalSales,
    Expression<int>? cashSales,
    Expression<int>? mpesaSales,
    Expression<int>? expenses,
    Expression<int>? costOfGoods,
    Expression<int>? grossProfit,
    Expression<int>? netResult,
    Expression<int>? expectedCash,
    Expression<int>? actualCash,
    Expression<int>? cashDifference,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (totalSales != null) 'total_sales': totalSales,
      if (cashSales != null) 'cash_sales': cashSales,
      if (mpesaSales != null) 'mpesa_sales': mpesaSales,
      if (expenses != null) 'expenses': expenses,
      if (costOfGoods != null) 'cost_of_goods': costOfGoods,
      if (grossProfit != null) 'gross_profit': grossProfit,
      if (netResult != null) 'net_result': netResult,
      if (expectedCash != null) 'expected_cash': expectedCash,
      if (actualCash != null) 'actual_cash': actualCash,
      if (cashDifference != null) 'cash_difference': cashDifference,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DailyClosesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? totalSales,
    Value<int>? cashSales,
    Value<int>? mpesaSales,
    Value<int>? expenses,
    Value<int>? costOfGoods,
    Value<int>? grossProfit,
    Value<int>? netResult,
    Value<int>? expectedCash,
    Value<int>? actualCash,
    Value<int>? cashDifference,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return DailyClosesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      totalSales: totalSales ?? this.totalSales,
      cashSales: cashSales ?? this.cashSales,
      mpesaSales: mpesaSales ?? this.mpesaSales,
      expenses: expenses ?? this.expenses,
      costOfGoods: costOfGoods ?? this.costOfGoods,
      grossProfit: grossProfit ?? this.grossProfit,
      netResult: netResult ?? this.netResult,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      cashDifference: cashDifference ?? this.cashDifference,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (totalSales.present) {
      map['total_sales'] = Variable<int>(totalSales.value);
    }
    if (cashSales.present) {
      map['cash_sales'] = Variable<int>(cashSales.value);
    }
    if (mpesaSales.present) {
      map['mpesa_sales'] = Variable<int>(mpesaSales.value);
    }
    if (expenses.present) {
      map['expenses'] = Variable<int>(expenses.value);
    }
    if (costOfGoods.present) {
      map['cost_of_goods'] = Variable<int>(costOfGoods.value);
    }
    if (grossProfit.present) {
      map['gross_profit'] = Variable<int>(grossProfit.value);
    }
    if (netResult.present) {
      map['net_result'] = Variable<int>(netResult.value);
    }
    if (expectedCash.present) {
      map['expected_cash'] = Variable<int>(expectedCash.value);
    }
    if (actualCash.present) {
      map['actual_cash'] = Variable<int>(actualCash.value);
    }
    if (cashDifference.present) {
      map['cash_difference'] = Variable<int>(cashDifference.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyClosesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('totalSales: $totalSales, ')
          ..write('cashSales: $cashSales, ')
          ..write('mpesaSales: $mpesaSales, ')
          ..write('expenses: $expenses, ')
          ..write('costOfGoods: $costOfGoods, ')
          ..write('grossProfit: $grossProfit, ')
          ..write('netResult: $netResult, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('actualCash: $actualCash, ')
          ..write('cashDifference: $cashDifference, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $SaleItemsTable saleItems = $SaleItemsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $StockMovementsTable stockMovements = $StockMovementsTable(this);
  late final $DailyClosesTable dailyCloses = $DailyClosesTable(this);
  late final ProductsDao productsDao = ProductsDao(this as AppDatabase);
  late final StockDao stockDao = StockDao(this as AppDatabase);
  late final SalesDao salesDao = SalesDao(this as AppDatabase);
  late final ExpensesDao expensesDao = ExpensesDao(this as AppDatabase);
  late final DailyCloseDao dailyCloseDao = DailyCloseDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    sales,
    saleItems,
    expenses,
    stockMovements,
    dailyCloses,
  ];
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> barcode,
      Value<String?> imagePath,
      Value<int?> buyingPrice,
      Value<int?> sellingPrice,
      Value<int> quantity,
      required ProductUnit unit,
      Value<int> lowStockThreshold,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> barcode,
      Value<String?> imagePath,
      Value<int?> buyingPrice,
      Value<int?> sellingPrice,
      Value<int> quantity,
      Value<ProductUnit> unit,
      Value<int> lowStockThreshold,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SaleItemsTable, List<SaleItem>>
  _saleItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleItems,
    aliasName: 'products__id__sale_items__product_id',
  );

  $$SaleItemsTableProcessedTableManager get saleItemsRefs {
    final manager = $$SaleItemsTableTableManager(
      $_db,
      $_db.saleItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
  _stockMovementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stockMovements,
    aliasName: 'products__id__stock_movements__product_id',
  );

  $$StockMovementsTableProcessedTableManager get stockMovementsRefs {
    final manager = $$StockMovementsTableTableManager(
      $_db,
      $_db.stockMovements,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get buyingPrice => $composableBuilder(
    column: $table.buyingPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ProductUnit, ProductUnit, String> get unit =>
      $composableBuilder(
        column: $table.unit,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> saleItemsRefs(
    Expression<bool> Function($$SaleItemsTableFilterComposer f) f,
  ) {
    final $$SaleItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableFilterComposer(
            $db: $db,
            $table: $db.saleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stockMovementsRefs(
    Expression<bool> Function($$StockMovementsTableFilterComposer f) f,
  ) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMovements,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockMovementsTableFilterComposer(
            $db: $db,
            $table: $db.stockMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get buyingPrice => $composableBuilder(
    column: $table.buyingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<int> get buyingPrice => $composableBuilder(
    column: $table.buyingPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProductUnit, String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> saleItemsRefs<T extends Object>(
    Expression<T> Function($$SaleItemsTableAnnotationComposer a) f,
  ) {
    final $$SaleItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.saleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stockMovementsRefs<T extends Object>(
    Expression<T> Function($$StockMovementsTableAnnotationComposer a) f,
  ) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMovements,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockMovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.stockMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({bool saleItemsRefs, bool stockMovementsRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int?> buyingPrice = const Value.absent(),
                Value<int?> sellingPrice = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<ProductUnit> unit = const Value.absent(),
                Value<int> lowStockThreshold = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                barcode: barcode,
                imagePath: imagePath,
                buyingPrice: buyingPrice,
                sellingPrice: sellingPrice,
                quantity: quantity,
                unit: unit,
                lowStockThreshold: lowStockThreshold,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> barcode = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int?> buyingPrice = const Value.absent(),
                Value<int?> sellingPrice = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                required ProductUnit unit,
                Value<int> lowStockThreshold = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                barcode: barcode,
                imagePath: imagePath,
                buyingPrice: buyingPrice,
                sellingPrice: sellingPrice,
                quantity: quantity,
                unit: unit,
                lowStockThreshold: lowStockThreshold,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({saleItemsRefs = false, stockMovementsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (saleItemsRefs) db.saleItems,
                    if (stockMovementsRefs) db.stockMovements,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (saleItemsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          SaleItem
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._saleItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).saleItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (stockMovementsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          StockMovement
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._stockMovementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).stockMovementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({bool saleItemsRefs, bool stockMovementsRefs})
    >;
typedef $$SalesTableCreateCompanionBuilder =
    SalesCompanion Function({
      Value<int> id,
      required int subtotal,
      required int total,
      required PaymentMethod paymentMethod,
      required int amountReceived,
      required int changeAmount,
      Value<String?> mpesaCode,
      required DateTime createdAt,
    });
typedef $$SalesTableUpdateCompanionBuilder =
    SalesCompanion Function({
      Value<int> id,
      Value<int> subtotal,
      Value<int> total,
      Value<PaymentMethod> paymentMethod,
      Value<int> amountReceived,
      Value<int> changeAmount,
      Value<String?> mpesaCode,
      Value<DateTime> createdAt,
    });

final class $$SalesTableReferences
    extends BaseReferences<_$AppDatabase, $SalesTable, Sale> {
  $$SalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SaleItemsTable, List<SaleItem>>
  _saleItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleItems,
    aliasName: 'sales__id__sale_items__sale_id',
  );

  $$SaleItemsTableProcessedTableManager get saleItemsRefs {
    final manager = $$SaleItemsTableTableManager(
      $_db,
      $_db.saleItems,
    ).filter((f) => f.saleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SalesTableFilterComposer extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PaymentMethod, PaymentMethod, String>
  get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get amountReceived => $composableBuilder(
    column: $table.amountReceived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mpesaCode => $composableBuilder(
    column: $table.mpesaCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> saleItemsRefs(
    Expression<bool> Function($$SaleItemsTableFilterComposer f) f,
  ) {
    final $$SaleItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleItems,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableFilterComposer(
            $db: $db,
            $table: $db.saleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountReceived => $composableBuilder(
    column: $table.amountReceived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mpesaCode => $composableBuilder(
    column: $table.mpesaCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PaymentMethod, String> get paymentMethod =>
      $composableBuilder(
        column: $table.paymentMethod,
        builder: (column) => column,
      );

  GeneratedColumn<int> get amountReceived => $composableBuilder(
    column: $table.amountReceived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mpesaCode =>
      $composableBuilder(column: $table.mpesaCode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> saleItemsRefs<T extends Object>(
    Expression<T> Function($$SaleItemsTableAnnotationComposer a) f,
  ) {
    final $$SaleItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleItems,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.saleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesTable,
          Sale,
          $$SalesTableFilterComposer,
          $$SalesTableOrderingComposer,
          $$SalesTableAnnotationComposer,
          $$SalesTableCreateCompanionBuilder,
          $$SalesTableUpdateCompanionBuilder,
          (Sale, $$SalesTableReferences),
          Sale,
          PrefetchHooks Function({bool saleItemsRefs})
        > {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<PaymentMethod> paymentMethod = const Value.absent(),
                Value<int> amountReceived = const Value.absent(),
                Value<int> changeAmount = const Value.absent(),
                Value<String?> mpesaCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SalesCompanion(
                id: id,
                subtotal: subtotal,
                total: total,
                paymentMethod: paymentMethod,
                amountReceived: amountReceived,
                changeAmount: changeAmount,
                mpesaCode: mpesaCode,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int subtotal,
                required int total,
                required PaymentMethod paymentMethod,
                required int amountReceived,
                required int changeAmount,
                Value<String?> mpesaCode = const Value.absent(),
                required DateTime createdAt,
              }) => SalesCompanion.insert(
                id: id,
                subtotal: subtotal,
                total: total,
                paymentMethod: paymentMethod,
                amountReceived: amountReceived,
                changeAmount: changeAmount,
                mpesaCode: mpesaCode,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SalesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({saleItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (saleItemsRefs) db.saleItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (saleItemsRefs)
                    await $_getPrefetchedData<Sale, $SalesTable, SaleItem>(
                      currentTable: table,
                      referencedTable: $$SalesTableReferences
                          ._saleItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SalesTableReferences(db, table, p0).saleItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.saleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesTable,
      Sale,
      $$SalesTableFilterComposer,
      $$SalesTableOrderingComposer,
      $$SalesTableAnnotationComposer,
      $$SalesTableCreateCompanionBuilder,
      $$SalesTableUpdateCompanionBuilder,
      (Sale, $$SalesTableReferences),
      Sale,
      PrefetchHooks Function({bool saleItemsRefs})
    >;
typedef $$SaleItemsTableCreateCompanionBuilder =
    SaleItemsCompanion Function({
      Value<int> id,
      required int saleId,
      required int productId,
      required String productName,
      required int quantity,
      required int buyingPriceSnapshot,
      required int sellingPriceSnapshot,
      required int total,
    });
typedef $$SaleItemsTableUpdateCompanionBuilder =
    SaleItemsCompanion Function({
      Value<int> id,
      Value<int> saleId,
      Value<int> productId,
      Value<String> productName,
      Value<int> quantity,
      Value<int> buyingPriceSnapshot,
      Value<int> sellingPriceSnapshot,
      Value<int> total,
    });

final class $$SaleItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SaleItemsTable, SaleItem> {
  $$SaleItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SalesTable _saleIdTable(_$AppDatabase db) =>
      db.sales.createAlias('sale_items__sale_id__sales__id');

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<int>('sale_id')!;

    final manager = $$SalesTableTableManager(
      $_db,
      $_db.sales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('sale_items__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SaleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get buyingPriceSnapshot => $composableBuilder(
    column: $table.buyingPriceSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sellingPriceSnapshot => $composableBuilder(
    column: $table.sellingPriceSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get buyingPriceSnapshot => $composableBuilder(
    column: $table.buyingPriceSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sellingPriceSnapshot => $composableBuilder(
    column: $table.sellingPriceSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableOrderingComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get buyingPriceSnapshot => $composableBuilder(
    column: $table.buyingPriceSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sellingPriceSnapshot => $composableBuilder(
    column: $table.sellingPriceSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleItemsTable,
          SaleItem,
          $$SaleItemsTableFilterComposer,
          $$SaleItemsTableOrderingComposer,
          $$SaleItemsTableAnnotationComposer,
          $$SaleItemsTableCreateCompanionBuilder,
          $$SaleItemsTableUpdateCompanionBuilder,
          (SaleItem, $$SaleItemsTableReferences),
          SaleItem,
          PrefetchHooks Function({bool saleId, bool productId})
        > {
  $$SaleItemsTableTableManager(_$AppDatabase db, $SaleItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> saleId = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> buyingPriceSnapshot = const Value.absent(),
                Value<int> sellingPriceSnapshot = const Value.absent(),
                Value<int> total = const Value.absent(),
              }) => SaleItemsCompanion(
                id: id,
                saleId: saleId,
                productId: productId,
                productName: productName,
                quantity: quantity,
                buyingPriceSnapshot: buyingPriceSnapshot,
                sellingPriceSnapshot: sellingPriceSnapshot,
                total: total,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int saleId,
                required int productId,
                required String productName,
                required int quantity,
                required int buyingPriceSnapshot,
                required int sellingPriceSnapshot,
                required int total,
              }) => SaleItemsCompanion.insert(
                id: id,
                saleId: saleId,
                productId: productId,
                productName: productName,
                quantity: quantity,
                buyingPriceSnapshot: buyingPriceSnapshot,
                sellingPriceSnapshot: sellingPriceSnapshot,
                total: total,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SaleItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({saleId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (saleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.saleId,
                                referencedTable: $$SaleItemsTableReferences
                                    ._saleIdTable(db),
                                referencedColumn: $$SaleItemsTableReferences
                                    ._saleIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$SaleItemsTableReferences
                                    ._productIdTable(db),
                                referencedColumn: $$SaleItemsTableReferences
                                    ._productIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SaleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleItemsTable,
      SaleItem,
      $$SaleItemsTableFilterComposer,
      $$SaleItemsTableOrderingComposer,
      $$SaleItemsTableAnnotationComposer,
      $$SaleItemsTableCreateCompanionBuilder,
      $$SaleItemsTableUpdateCompanionBuilder,
      (SaleItem, $$SaleItemsTableReferences),
      SaleItem,
      PrefetchHooks Function({bool saleId, bool productId})
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      Value<int> id,
      required int amount,
      required ExpenseCategory category,
      Value<String?> description,
      required PaymentMethod paymentMethod,
      required DateTime createdAt,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<int> id,
      Value<int> amount,
      Value<ExpenseCategory> category,
      Value<String?> description,
      Value<PaymentMethod> paymentMethod,
      Value<DateTime> createdAt,
    });

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExpenseCategory, ExpenseCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PaymentMethod, PaymentMethod, String>
  get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExpenseCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PaymentMethod, String> get paymentMethod =>
      $composableBuilder(
        column: $table.paymentMethod,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
          Expense,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<ExpenseCategory> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<PaymentMethod> paymentMethod = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                amount: amount,
                category: category,
                description: description,
                paymentMethod: paymentMethod,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amount,
                required ExpenseCategory category,
                Value<String?> description = const Value.absent(),
                required PaymentMethod paymentMethod,
                required DateTime createdAt,
              }) => ExpensesCompanion.insert(
                id: id,
                amount: amount,
                category: category,
                description: description,
                paymentMethod: paymentMethod,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
      Expense,
      PrefetchHooks Function()
    >;
typedef $$StockMovementsTableCreateCompanionBuilder =
    StockMovementsCompanion Function({
      Value<int> id,
      required int productId,
      required MovementType movementType,
      required int quantity,
      Value<String?> note,
      Value<int?> referenceId,
      required DateTime createdAt,
    });
typedef $$StockMovementsTableUpdateCompanionBuilder =
    StockMovementsCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<MovementType> movementType,
      Value<int> quantity,
      Value<String?> note,
      Value<int?> referenceId,
      Value<DateTime> createdAt,
    });

final class $$StockMovementsTableReferences
    extends BaseReferences<_$AppDatabase, $StockMovementsTable, StockMovement> {
  $$StockMovementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('stock_movements__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StockMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MovementType, MovementType, String>
  get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MovementType, String> get movementType =>
      $composableBuilder(
        column: $table.movementType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockMovementsTable,
          StockMovement,
          $$StockMovementsTableFilterComposer,
          $$StockMovementsTableOrderingComposer,
          $$StockMovementsTableAnnotationComposer,
          $$StockMovementsTableCreateCompanionBuilder,
          $$StockMovementsTableUpdateCompanionBuilder,
          (StockMovement, $$StockMovementsTableReferences),
          StockMovement,
          PrefetchHooks Function({bool productId})
        > {
  $$StockMovementsTableTableManager(
    _$AppDatabase db,
    $StockMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<MovementType> movementType = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> referenceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StockMovementsCompanion(
                id: id,
                productId: productId,
                movementType: movementType,
                quantity: quantity,
                note: note,
                referenceId: referenceId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                required MovementType movementType,
                required int quantity,
                Value<String?> note = const Value.absent(),
                Value<int?> referenceId = const Value.absent(),
                required DateTime createdAt,
              }) => StockMovementsCompanion.insert(
                id: id,
                productId: productId,
                movementType: movementType,
                quantity: quantity,
                note: note,
                referenceId: referenceId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StockMovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$StockMovementsTableReferences
                                    ._productIdTable(db),
                                referencedColumn:
                                    $$StockMovementsTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StockMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockMovementsTable,
      StockMovement,
      $$StockMovementsTableFilterComposer,
      $$StockMovementsTableOrderingComposer,
      $$StockMovementsTableAnnotationComposer,
      $$StockMovementsTableCreateCompanionBuilder,
      $$StockMovementsTableUpdateCompanionBuilder,
      (StockMovement, $$StockMovementsTableReferences),
      StockMovement,
      PrefetchHooks Function({bool productId})
    >;
typedef $$DailyClosesTableCreateCompanionBuilder =
    DailyClosesCompanion Function({
      Value<int> id,
      required DateTime date,
      required int totalSales,
      required int cashSales,
      required int mpesaSales,
      required int expenses,
      required int costOfGoods,
      required int grossProfit,
      required int netResult,
      required int expectedCash,
      required int actualCash,
      required int cashDifference,
      Value<String?> note,
      required DateTime createdAt,
    });
typedef $$DailyClosesTableUpdateCompanionBuilder =
    DailyClosesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> totalSales,
      Value<int> cashSales,
      Value<int> mpesaSales,
      Value<int> expenses,
      Value<int> costOfGoods,
      Value<int> grossProfit,
      Value<int> netResult,
      Value<int> expectedCash,
      Value<int> actualCash,
      Value<int> cashDifference,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

class $$DailyClosesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyClosesTable> {
  $$DailyClosesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashSales => $composableBuilder(
    column: $table.cashSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mpesaSales => $composableBuilder(
    column: $table.mpesaSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expenses => $composableBuilder(
    column: $table.expenses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costOfGoods => $composableBuilder(
    column: $table.costOfGoods,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grossProfit => $composableBuilder(
    column: $table.grossProfit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get netResult => $composableBuilder(
    column: $table.netResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualCash => $composableBuilder(
    column: $table.actualCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashDifference => $composableBuilder(
    column: $table.cashDifference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyClosesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyClosesTable> {
  $$DailyClosesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashSales => $composableBuilder(
    column: $table.cashSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mpesaSales => $composableBuilder(
    column: $table.mpesaSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expenses => $composableBuilder(
    column: $table.expenses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costOfGoods => $composableBuilder(
    column: $table.costOfGoods,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grossProfit => $composableBuilder(
    column: $table.grossProfit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get netResult => $composableBuilder(
    column: $table.netResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualCash => $composableBuilder(
    column: $table.actualCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashDifference => $composableBuilder(
    column: $table.cashDifference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyClosesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyClosesTable> {
  $$DailyClosesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashSales =>
      $composableBuilder(column: $table.cashSales, builder: (column) => column);

  GeneratedColumn<int> get mpesaSales => $composableBuilder(
    column: $table.mpesaSales,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expenses =>
      $composableBuilder(column: $table.expenses, builder: (column) => column);

  GeneratedColumn<int> get costOfGoods => $composableBuilder(
    column: $table.costOfGoods,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grossProfit => $composableBuilder(
    column: $table.grossProfit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get netResult =>
      $composableBuilder(column: $table.netResult, builder: (column) => column);

  GeneratedColumn<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualCash => $composableBuilder(
    column: $table.actualCash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashDifference => $composableBuilder(
    column: $table.cashDifference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyClosesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyClosesTable,
          DailyClose,
          $$DailyClosesTableFilterComposer,
          $$DailyClosesTableOrderingComposer,
          $$DailyClosesTableAnnotationComposer,
          $$DailyClosesTableCreateCompanionBuilder,
          $$DailyClosesTableUpdateCompanionBuilder,
          (
            DailyClose,
            BaseReferences<_$AppDatabase, $DailyClosesTable, DailyClose>,
          ),
          DailyClose,
          PrefetchHooks Function()
        > {
  $$DailyClosesTableTableManager(_$AppDatabase db, $DailyClosesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyClosesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyClosesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyClosesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> totalSales = const Value.absent(),
                Value<int> cashSales = const Value.absent(),
                Value<int> mpesaSales = const Value.absent(),
                Value<int> expenses = const Value.absent(),
                Value<int> costOfGoods = const Value.absent(),
                Value<int> grossProfit = const Value.absent(),
                Value<int> netResult = const Value.absent(),
                Value<int> expectedCash = const Value.absent(),
                Value<int> actualCash = const Value.absent(),
                Value<int> cashDifference = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DailyClosesCompanion(
                id: id,
                date: date,
                totalSales: totalSales,
                cashSales: cashSales,
                mpesaSales: mpesaSales,
                expenses: expenses,
                costOfGoods: costOfGoods,
                grossProfit: grossProfit,
                netResult: netResult,
                expectedCash: expectedCash,
                actualCash: actualCash,
                cashDifference: cashDifference,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required int totalSales,
                required int cashSales,
                required int mpesaSales,
                required int expenses,
                required int costOfGoods,
                required int grossProfit,
                required int netResult,
                required int expectedCash,
                required int actualCash,
                required int cashDifference,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
              }) => DailyClosesCompanion.insert(
                id: id,
                date: date,
                totalSales: totalSales,
                cashSales: cashSales,
                mpesaSales: mpesaSales,
                expenses: expenses,
                costOfGoods: costOfGoods,
                grossProfit: grossProfit,
                netResult: netResult,
                expectedCash: expectedCash,
                actualCash: actualCash,
                cashDifference: cashDifference,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyClosesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyClosesTable,
      DailyClose,
      $$DailyClosesTableFilterComposer,
      $$DailyClosesTableOrderingComposer,
      $$DailyClosesTableAnnotationComposer,
      $$DailyClosesTableCreateCompanionBuilder,
      $$DailyClosesTableUpdateCompanionBuilder,
      (
        DailyClose,
        BaseReferences<_$AppDatabase, $DailyClosesTable, DailyClose>,
      ),
      DailyClose,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db, _db.saleItems);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(_db, _db.stockMovements);
  $$DailyClosesTableTableManager get dailyCloses =>
      $$DailyClosesTableTableManager(_db, _db.dailyCloses);
}
