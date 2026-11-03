// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _colorLightMeta = const VerificationMeta(
    'colorLight',
  );
  @override
  late final GeneratedColumn<int> colorLight = GeneratedColumn<int>(
    'color_light',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorDarkMeta = const VerificationMeta(
    'colorDark',
  );
  @override
  late final GeneratedColumn<int> colorDark = GeneratedColumn<int>(
    'color_dark',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorLight,
    colorDark,
    icon,
    isDefault,
    isArchived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
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
    if (data.containsKey('color_light')) {
      context.handle(
        _colorLightMeta,
        colorLight.isAcceptableOrUnknown(data['color_light']!, _colorLightMeta),
      );
    } else if (isInserting) {
      context.missing(_colorLightMeta);
    }
    if (data.containsKey('color_dark')) {
      context.handle(
        _colorDarkMeta,
        colorDark.isAcceptableOrUnknown(data['color_dark']!, _colorDarkMeta),
      );
    } else if (isInserting) {
      context.missing(_colorDarkMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorLight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_light'],
      )!,
      colorDark: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_dark'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final int colorLight;
  final int colorDark;
  final String icon;
  final bool isDefault;
  final bool isArchived;
  final DateTime createdAt;
  const Category({
    required this.id,
    required this.name,
    required this.colorLight,
    required this.colorDark,
    required this.icon,
    required this.isDefault,
    required this.isArchived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_light'] = Variable<int>(colorLight);
    map['color_dark'] = Variable<int>(colorDark);
    map['icon'] = Variable<String>(icon);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorLight: Value(colorLight),
      colorDark: Value(colorDark),
      icon: Value(icon),
      isDefault: Value(isDefault),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorLight: serializer.fromJson<int>(json['colorLight']),
      colorDark: serializer.fromJson<int>(json['colorDark']),
      icon: serializer.fromJson<String>(json['icon']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorLight': serializer.toJson<int>(colorLight),
      'colorDark': serializer.toJson<int>(colorDark),
      'icon': serializer.toJson<String>(icon),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    int? colorLight,
    int? colorDark,
    String? icon,
    bool? isDefault,
    bool? isArchived,
    DateTime? createdAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    colorLight: colorLight ?? this.colorLight,
    colorDark: colorDark ?? this.colorDark,
    icon: icon ?? this.icon,
    isDefault: isDefault ?? this.isDefault,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorLight: data.colorLight.present
          ? data.colorLight.value
          : this.colorLight,
      colorDark: data.colorDark.present ? data.colorDark.value : this.colorDark,
      icon: data.icon.present ? data.icon.value : this.icon,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorLight: $colorLight, ')
          ..write('colorDark: $colorDark, ')
          ..write('icon: $icon, ')
          ..write('isDefault: $isDefault, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    colorLight,
    colorDark,
    icon,
    isDefault,
    isArchived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorLight == this.colorLight &&
          other.colorDark == this.colorDark &&
          other.icon == this.icon &&
          other.isDefault == this.isDefault &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> colorLight;
  final Value<int> colorDark;
  final Value<String> icon;
  final Value<bool> isDefault;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorLight = const Value.absent(),
    this.colorDark = const Value.absent(),
    this.icon = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int colorLight,
    required int colorDark,
    required String icon,
    this.isDefault = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       colorLight = Value(colorLight),
       colorDark = Value(colorDark),
       icon = Value(icon);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? colorLight,
    Expression<int>? colorDark,
    Expression<String>? icon,
    Expression<bool>? isDefault,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorLight != null) 'color_light': colorLight,
      if (colorDark != null) 'color_dark': colorDark,
      if (icon != null) 'icon': icon,
      if (isDefault != null) 'is_default': isDefault,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? colorLight,
    Value<int>? colorDark,
    Value<String>? icon,
    Value<bool>? isDefault,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorLight: colorLight ?? this.colorLight,
      colorDark: colorDark ?? this.colorDark,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
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
    if (colorLight.present) {
      map['color_light'] = Variable<int>(colorLight.value);
    }
    if (colorDark.present) {
      map['color_dark'] = Variable<int>(colorDark.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorLight: $colorLight, ')
          ..write('colorDark: $colorDark, ')
          ..write('icon: $icon, ')
          ..write('isDefault: $isDefault, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
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
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(amountPaise).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _itemMeta = const VerificationMeta('item');
  @override
  late final GeneratedColumn<String> item = GeneratedColumn<String>(
    'item',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spentOnMeta = const VerificationMeta(
    'spentOn',
  );
  @override
  late final GeneratedColumn<String> spentOn = GeneratedColumn<String>(
    'spent_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('chat'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountPaise,
    categoryId,
    item,
    location,
    paymentMethod,
    spentOn,
    rawText,
    source,
    createdAt,
    updatedAt,
    deletedAt,
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
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('item')) {
      context.handle(
        _itemMeta,
        item.isAcceptableOrUnknown(data['item']!, _itemMeta),
      );
    } else if (isInserting) {
      context.missing(_itemMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('spent_on')) {
      context.handle(
        _spentOnMeta,
        spentOn.isAcceptableOrUnknown(data['spent_on']!, _spentOnMeta),
      );
    } else if (isInserting) {
      context.missing(_spentOnMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
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
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      item: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      spentOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spent_on'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final int id;
  final int amountPaise;
  final int categoryId;
  final String item;
  final String? location;

  /// cash | upi | card | netbanking | other
  final String? paymentMethod;
  final String spentOn;
  final String? rawText;

  /// chat | voice | manual
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft delete, so Undo is possible.
  final DateTime? deletedAt;
  const Expense({
    required this.id,
    required this.amountPaise,
    required this.categoryId,
    required this.item,
    this.location,
    this.paymentMethod,
    required this.spentOn,
    this.rawText,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['category_id'] = Variable<int>(categoryId);
    map['item'] = Variable<String>(item);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['spent_on'] = Variable<String>(spentOn);
    if (!nullToAbsent || rawText != null) {
      map['raw_text'] = Variable<String>(rawText);
    }
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      amountPaise: Value(amountPaise),
      categoryId: Value(categoryId),
      item: Value(item),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      spentOn: Value(spentOn),
      rawText: rawText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawText),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<int>(json['id']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      item: serializer.fromJson<String>(json['item']),
      location: serializer.fromJson<String?>(json['location']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      spentOn: serializer.fromJson<String>(json['spentOn']),
      rawText: serializer.fromJson<String?>(json['rawText']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'categoryId': serializer.toJson<int>(categoryId),
      'item': serializer.toJson<String>(item),
      'location': serializer.toJson<String?>(location),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'spentOn': serializer.toJson<String>(spentOn),
      'rawText': serializer.toJson<String?>(rawText),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Expense copyWith({
    int? id,
    int? amountPaise,
    int? categoryId,
    String? item,
    Value<String?> location = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    String? spentOn,
    Value<String?> rawText = const Value.absent(),
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Expense(
    id: id ?? this.id,
    amountPaise: amountPaise ?? this.amountPaise,
    categoryId: categoryId ?? this.categoryId,
    item: item ?? this.item,
    location: location.present ? location.value : this.location,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    spentOn: spentOn ?? this.spentOn,
    rawText: rawText.present ? rawText.value : this.rawText,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      item: data.item.present ? data.item.value : this.item,
      location: data.location.present ? data.location.value : this.location,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      spentOn: data.spentOn.present ? data.spentOn.value : this.spentOn,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('categoryId: $categoryId, ')
          ..write('item: $item, ')
          ..write('location: $location, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('spentOn: $spentOn, ')
          ..write('rawText: $rawText, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amountPaise,
    categoryId,
    item,
    location,
    paymentMethod,
    spentOn,
    rawText,
    source,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.amountPaise == this.amountPaise &&
          other.categoryId == this.categoryId &&
          other.item == this.item &&
          other.location == this.location &&
          other.paymentMethod == this.paymentMethod &&
          other.spentOn == this.spentOn &&
          other.rawText == this.rawText &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<int> id;
  final Value<int> amountPaise;
  final Value<int> categoryId;
  final Value<String> item;
  final Value<String?> location;
  final Value<String?> paymentMethod;
  final Value<String> spentOn;
  final Value<String?> rawText;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.item = const Value.absent(),
    this.location = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.spentOn = const Value.absent(),
    this.rawText = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required int amountPaise,
    required int categoryId,
    required String item,
    this.location = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    required String spentOn,
    this.rawText = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : amountPaise = Value(amountPaise),
       categoryId = Value(categoryId),
       item = Value(item),
       spentOn = Value(spentOn);
  static Insertable<Expense> custom({
    Expression<int>? id,
    Expression<int>? amountPaise,
    Expression<int>? categoryId,
    Expression<String>? item,
    Expression<String>? location,
    Expression<String>? paymentMethod,
    Expression<String>? spentOn,
    Expression<String>? rawText,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (categoryId != null) 'category_id': categoryId,
      if (item != null) 'item': item,
      if (location != null) 'location': location,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (spentOn != null) 'spent_on': spentOn,
      if (rawText != null) 'raw_text': rawText,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  ExpensesCompanion copyWith({
    Value<int>? id,
    Value<int>? amountPaise,
    Value<int>? categoryId,
    Value<String>? item,
    Value<String?>? location,
    Value<String?>? paymentMethod,
    Value<String>? spentOn,
    Value<String?>? rawText,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      amountPaise: amountPaise ?? this.amountPaise,
      categoryId: categoryId ?? this.categoryId,
      item: item ?? this.item,
      location: location ?? this.location,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      spentOn: spentOn ?? this.spentOn,
      rawText: rawText ?? this.rawText,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (item.present) {
      map['item'] = Variable<String>(item.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (spentOn.present) {
      map['spent_on'] = Variable<String>(spentOn.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('categoryId: $categoryId, ')
          ..write('item: $item, ')
          ..write('location: $location, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('spentOn: $spentOn, ')
          ..write('rawText: $rawText, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _monthlyLimitPaiseMeta = const VerificationMeta(
    'monthlyLimitPaise',
  );
  @override
  late final GeneratedColumn<int> monthlyLimitPaise = GeneratedColumn<int>(
    'monthly_limit_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(monthlyLimitPaise).isBiggerThanValue(0),
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    monthlyLimitPaise,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('monthly_limit_paise')) {
      context.handle(
        _monthlyLimitPaiseMeta,
        monthlyLimitPaise.isAcceptableOrUnknown(
          data['monthly_limit_paise']!,
          _monthlyLimitPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_monthlyLimitPaiseMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      monthlyLimitPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_limit_paise'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final int id;

  /// NULL means the overall monthly budget. SQLite allows several NULLs in a
  /// UNIQUE column, so the "one overall budget" rule is enforced in the
  /// repository (upsert), not here.
  final int? categoryId;
  final int monthlyLimitPaise;
  final DateTime updatedAt;
  const Budget({
    required this.id,
    this.categoryId,
    required this.monthlyLimitPaise,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['monthly_limit_paise'] = Variable<int>(monthlyLimitPaise);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      monthlyLimitPaise: Value(monthlyLimitPaise),
      updatedAt: Value(updatedAt),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      monthlyLimitPaise: serializer.fromJson<int>(json['monthlyLimitPaise']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int?>(categoryId),
      'monthlyLimitPaise': serializer.toJson<int>(monthlyLimitPaise),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Budget copyWith({
    int? id,
    Value<int?> categoryId = const Value.absent(),
    int? monthlyLimitPaise,
    DateTime? updatedAt,
  }) => Budget(
    id: id ?? this.id,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    monthlyLimitPaise: monthlyLimitPaise ?? this.monthlyLimitPaise,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      monthlyLimitPaise: data.monthlyLimitPaise.present
          ? data.monthlyLimitPaise.value
          : this.monthlyLimitPaise,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthlyLimitPaise: $monthlyLimitPaise, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, monthlyLimitPaise, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.monthlyLimitPaise == this.monthlyLimitPaise &&
          other.updatedAt == this.updatedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<int> id;
  final Value<int?> categoryId;
  final Value<int> monthlyLimitPaise;
  final Value<DateTime> updatedAt;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.monthlyLimitPaise = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    required int monthlyLimitPaise,
    this.updatedAt = const Value.absent(),
  }) : monthlyLimitPaise = Value(monthlyLimitPaise);
  static Insertable<Budget> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<int>? monthlyLimitPaise,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (monthlyLimitPaise != null) 'monthly_limit_paise': monthlyLimitPaise,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BudgetsCompanion copyWith({
    Value<int>? id,
    Value<int?>? categoryId,
    Value<int>? monthlyLimitPaise,
    Value<DateTime>? updatedAt,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      monthlyLimitPaise: monthlyLimitPaise ?? this.monthlyLimitPaise,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (monthlyLimitPaise.present) {
      map['monthly_limit_paise'] = Variable<int>(monthlyLimitPaise.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthlyLimitPaise: $monthlyLimitPaise, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKeyMeta = const VerificationMeta(
    'nameKey',
  );
  @override
  late final GeneratedColumn<String> nameKey = GeneratedColumn<String>(
    'name_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, nameKey, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
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
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final int id;
  final String name;

  /// Lower-cased, trimmed name used to match "rahul" with "Rahul".
  final String nameKey;
  final DateTime createdAt;
  const Person({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['name_key'] = Variable<String>(nameKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      name: Value(name),
      nameKey: Value(nameKey),
      createdAt: Value(createdAt),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameKey: serializer.fromJson<String>(json['nameKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nameKey': serializer.toJson<String>(nameKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Person copyWith({
    int? id,
    String? name,
    String? nameKey,
    DateTime? createdAt,
  }) => Person(
    id: id ?? this.id,
    name: name ?? this.name,
    nameKey: nameKey ?? this.nameKey,
    createdAt: createdAt ?? this.createdAt,
  );
  Person copyWithCompanion(PeopleCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, nameKey, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameKey == this.nameKey &&
          other.createdAt == this.createdAt);
}

class PeopleCompanion extends UpdateCompanion<Person> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> nameKey;
  final Value<DateTime> createdAt;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PeopleCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String nameKey,
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       nameKey = Value(nameKey);
  static Insertable<Person> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? nameKey,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameKey != null) 'name_key': nameKey,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PeopleCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? nameKey,
    Value<DateTime>? createdAt,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKey: nameKey ?? this.nameKey,
      createdAt: createdAt ?? this.createdAt,
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
    if (nameKey.present) {
      map['name_key'] = Variable<String>(nameKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LoansTable extends Loans with TableInfo<$LoansTable, Loan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    check: () => direction.isIn(const ['lent', 'borrowed']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _principalPaiseMeta = const VerificationMeta(
    'principalPaise',
  );
  @override
  late final GeneratedColumn<int> principalPaise = GeneratedColumn<int>(
    'principal_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(principalPaise).isBiggerThanValue(0),
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
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _happenedOnMeta = const VerificationMeta(
    'happenedOn',
  );
  @override
  late final GeneratedColumn<String> happenedOn = GeneratedColumn<String>(
    'happened_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    direction,
    principalPaise,
    note,
    paymentMethod,
    happenedOn,
    rawText,
    createdAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Loan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('principal_paise')) {
      context.handle(
        _principalPaiseMeta,
        principalPaise.isAcceptableOrUnknown(
          data['principal_paise']!,
          _principalPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_principalPaiseMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('happened_on')) {
      context.handle(
        _happenedOnMeta,
        happenedOn.isAcceptableOrUnknown(data['happened_on']!, _happenedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_happenedOnMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Loan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Loan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      principalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}principal_paise'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      happenedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}happened_on'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $LoansTable createAlias(String alias) {
    return $LoansTable(attachedDatabase, alias);
  }
}

class Loan extends DataClass implements Insertable<Loan> {
  final int id;
  final int personId;

  /// lent = they owe you, borrowed = you owe them.
  final String direction;
  final int principalPaise;
  final String? note;
  final String? paymentMethod;
  final String happenedOn;
  final String? rawText;
  final DateTime createdAt;
  final DateTime? deletedAt;
  const Loan({
    required this.id,
    required this.personId,
    required this.direction,
    required this.principalPaise,
    this.note,
    this.paymentMethod,
    required this.happenedOn,
    this.rawText,
    required this.createdAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<int>(personId);
    map['direction'] = Variable<String>(direction);
    map['principal_paise'] = Variable<int>(principalPaise);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['happened_on'] = Variable<String>(happenedOn);
    if (!nullToAbsent || rawText != null) {
      map['raw_text'] = Variable<String>(rawText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  LoansCompanion toCompanion(bool nullToAbsent) {
    return LoansCompanion(
      id: Value(id),
      personId: Value(personId),
      direction: Value(direction),
      principalPaise: Value(principalPaise),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      happenedOn: Value(happenedOn),
      rawText: rawText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawText),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Loan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Loan(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      direction: serializer.fromJson<String>(json['direction']),
      principalPaise: serializer.fromJson<int>(json['principalPaise']),
      note: serializer.fromJson<String?>(json['note']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      happenedOn: serializer.fromJson<String>(json['happenedOn']),
      rawText: serializer.fromJson<String?>(json['rawText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'direction': serializer.toJson<String>(direction),
      'principalPaise': serializer.toJson<int>(principalPaise),
      'note': serializer.toJson<String?>(note),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'happenedOn': serializer.toJson<String>(happenedOn),
      'rawText': serializer.toJson<String?>(rawText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Loan copyWith({
    int? id,
    int? personId,
    String? direction,
    int? principalPaise,
    Value<String?> note = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    String? happenedOn,
    Value<String?> rawText = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Loan(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    direction: direction ?? this.direction,
    principalPaise: principalPaise ?? this.principalPaise,
    note: note.present ? note.value : this.note,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    happenedOn: happenedOn ?? this.happenedOn,
    rawText: rawText.present ? rawText.value : this.rawText,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Loan copyWithCompanion(LoansCompanion data) {
    return Loan(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      direction: data.direction.present ? data.direction.value : this.direction,
      principalPaise: data.principalPaise.present
          ? data.principalPaise.value
          : this.principalPaise,
      note: data.note.present ? data.note.value : this.note,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      happenedOn: data.happenedOn.present
          ? data.happenedOn.value
          : this.happenedOn,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Loan(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('direction: $direction, ')
          ..write('principalPaise: $principalPaise, ')
          ..write('note: $note, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('happenedOn: $happenedOn, ')
          ..write('rawText: $rawText, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    direction,
    principalPaise,
    note,
    paymentMethod,
    happenedOn,
    rawText,
    createdAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Loan &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.direction == this.direction &&
          other.principalPaise == this.principalPaise &&
          other.note == this.note &&
          other.paymentMethod == this.paymentMethod &&
          other.happenedOn == this.happenedOn &&
          other.rawText == this.rawText &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class LoansCompanion extends UpdateCompanion<Loan> {
  final Value<int> id;
  final Value<int> personId;
  final Value<String> direction;
  final Value<int> principalPaise;
  final Value<String?> note;
  final Value<String?> paymentMethod;
  final Value<String> happenedOn;
  final Value<String?> rawText;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  const LoansCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.direction = const Value.absent(),
    this.principalPaise = const Value.absent(),
    this.note = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.happenedOn = const Value.absent(),
    this.rawText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  LoansCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required String direction,
    required int principalPaise,
    this.note = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    required String happenedOn,
    this.rawText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : personId = Value(personId),
       direction = Value(direction),
       principalPaise = Value(principalPaise),
       happenedOn = Value(happenedOn);
  static Insertable<Loan> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? direction,
    Expression<int>? principalPaise,
    Expression<String>? note,
    Expression<String>? paymentMethod,
    Expression<String>? happenedOn,
    Expression<String>? rawText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (direction != null) 'direction': direction,
      if (principalPaise != null) 'principal_paise': principalPaise,
      if (note != null) 'note': note,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (happenedOn != null) 'happened_on': happenedOn,
      if (rawText != null) 'raw_text': rawText,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  LoansCompanion copyWith({
    Value<int>? id,
    Value<int>? personId,
    Value<String>? direction,
    Value<int>? principalPaise,
    Value<String?>? note,
    Value<String?>? paymentMethod,
    Value<String>? happenedOn,
    Value<String?>? rawText,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
  }) {
    return LoansCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      direction: direction ?? this.direction,
      principalPaise: principalPaise ?? this.principalPaise,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      happenedOn: happenedOn ?? this.happenedOn,
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (principalPaise.present) {
      map['principal_paise'] = Variable<int>(principalPaise.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (happenedOn.present) {
      map['happened_on'] = Variable<String>(happenedOn.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoansCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('direction: $direction, ')
          ..write('principalPaise: $principalPaise, ')
          ..write('note: $note, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('happenedOn: $happenedOn, ')
          ..write('rawText: $rawText, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $LoanRepaymentsTable extends LoanRepayments
    with TableInfo<$LoanRepaymentsTable, LoanRepayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoanRepaymentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _loanIdMeta = const VerificationMeta('loanId');
  @override
  late final GeneratedColumn<int> loanId = GeneratedColumn<int>(
    'loan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES loans (id)',
    ),
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(amountPaise).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidOnMeta = const VerificationMeta('paidOn');
  @override
  late final GeneratedColumn<String> paidOn = GeneratedColumn<String>(
    'paid_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loanId,
    amountPaise,
    paidOn,
    rawText,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loan_repayments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoanRepayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('loan_id')) {
      context.handle(
        _loanIdMeta,
        loanId.isAcceptableOrUnknown(data['loan_id']!, _loanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_loanIdMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('paid_on')) {
      context.handle(
        _paidOnMeta,
        paidOn.isAcceptableOrUnknown(data['paid_on']!, _paidOnMeta),
      );
    } else if (isInserting) {
      context.missing(_paidOnMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoanRepayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoanRepayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      loanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loan_id'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      paidOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_on'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LoanRepaymentsTable createAlias(String alias) {
    return $LoanRepaymentsTable(attachedDatabase, alias);
  }
}

class LoanRepayment extends DataClass implements Insertable<LoanRepayment> {
  final int id;
  final int loanId;
  final int amountPaise;
  final String paidOn;
  final String? rawText;
  final DateTime createdAt;
  const LoanRepayment({
    required this.id,
    required this.loanId,
    required this.amountPaise,
    required this.paidOn,
    this.rawText,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['loan_id'] = Variable<int>(loanId);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['paid_on'] = Variable<String>(paidOn);
    if (!nullToAbsent || rawText != null) {
      map['raw_text'] = Variable<String>(rawText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LoanRepaymentsCompanion toCompanion(bool nullToAbsent) {
    return LoanRepaymentsCompanion(
      id: Value(id),
      loanId: Value(loanId),
      amountPaise: Value(amountPaise),
      paidOn: Value(paidOn),
      rawText: rawText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawText),
      createdAt: Value(createdAt),
    );
  }

  factory LoanRepayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoanRepayment(
      id: serializer.fromJson<int>(json['id']),
      loanId: serializer.fromJson<int>(json['loanId']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      paidOn: serializer.fromJson<String>(json['paidOn']),
      rawText: serializer.fromJson<String?>(json['rawText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'loanId': serializer.toJson<int>(loanId),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'paidOn': serializer.toJson<String>(paidOn),
      'rawText': serializer.toJson<String?>(rawText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LoanRepayment copyWith({
    int? id,
    int? loanId,
    int? amountPaise,
    String? paidOn,
    Value<String?> rawText = const Value.absent(),
    DateTime? createdAt,
  }) => LoanRepayment(
    id: id ?? this.id,
    loanId: loanId ?? this.loanId,
    amountPaise: amountPaise ?? this.amountPaise,
    paidOn: paidOn ?? this.paidOn,
    rawText: rawText.present ? rawText.value : this.rawText,
    createdAt: createdAt ?? this.createdAt,
  );
  LoanRepayment copyWithCompanion(LoanRepaymentsCompanion data) {
    return LoanRepayment(
      id: data.id.present ? data.id.value : this.id,
      loanId: data.loanId.present ? data.loanId.value : this.loanId,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      paidOn: data.paidOn.present ? data.paidOn.value : this.paidOn,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoanRepayment(')
          ..write('id: $id, ')
          ..write('loanId: $loanId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('paidOn: $paidOn, ')
          ..write('rawText: $rawText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, loanId, amountPaise, paidOn, rawText, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoanRepayment &&
          other.id == this.id &&
          other.loanId == this.loanId &&
          other.amountPaise == this.amountPaise &&
          other.paidOn == this.paidOn &&
          other.rawText == this.rawText &&
          other.createdAt == this.createdAt);
}

class LoanRepaymentsCompanion extends UpdateCompanion<LoanRepayment> {
  final Value<int> id;
  final Value<int> loanId;
  final Value<int> amountPaise;
  final Value<String> paidOn;
  final Value<String?> rawText;
  final Value<DateTime> createdAt;
  const LoanRepaymentsCompanion({
    this.id = const Value.absent(),
    this.loanId = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.paidOn = const Value.absent(),
    this.rawText = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LoanRepaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int loanId,
    required int amountPaise,
    required String paidOn,
    this.rawText = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : loanId = Value(loanId),
       amountPaise = Value(amountPaise),
       paidOn = Value(paidOn);
  static Insertable<LoanRepayment> custom({
    Expression<int>? id,
    Expression<int>? loanId,
    Expression<int>? amountPaise,
    Expression<String>? paidOn,
    Expression<String>? rawText,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loanId != null) 'loan_id': loanId,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (paidOn != null) 'paid_on': paidOn,
      if (rawText != null) 'raw_text': rawText,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LoanRepaymentsCompanion copyWith({
    Value<int>? id,
    Value<int>? loanId,
    Value<int>? amountPaise,
    Value<String>? paidOn,
    Value<String?>? rawText,
    Value<DateTime>? createdAt,
  }) {
    return LoanRepaymentsCompanion(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      amountPaise: amountPaise ?? this.amountPaise,
      paidOn: paidOn ?? this.paidOn,
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (loanId.present) {
      map['loan_id'] = Variable<int>(loanId.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (paidOn.present) {
      map['paid_on'] = Variable<String>(paidOn.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoanRepaymentsCompanion(')
          ..write('id: $id, ')
          ..write('loanId: $loanId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('paidOn: $paidOn, ')
          ..write('rawText: $rawText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardTypeMeta = const VerificationMeta(
    'cardType',
  );
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
    'card_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardPayloadMeta = const VerificationMeta(
    'cardPayload',
  );
  @override
  late final GeneratedColumn<String> cardPayload = GeneratedColumn<String>(
    'card_payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardStatusMeta = const VerificationMeta(
    'cardStatus',
  );
  @override
  late final GeneratedColumn<String> cardStatus = GeneratedColumn<String>(
    'card_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityRefMeta = const VerificationMeta(
    'entityRef',
  );
  @override
  late final GeneratedColumn<String> entityRef = GeneratedColumn<String>(
    'entity_ref',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    day,
    role,
    body,
    cardType,
    cardPayload,
    cardStatus,
    entityRef,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    }
    if (data.containsKey('card_type')) {
      context.handle(
        _cardTypeMeta,
        cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta),
      );
    }
    if (data.containsKey('card_payload')) {
      context.handle(
        _cardPayloadMeta,
        cardPayload.isAcceptableOrUnknown(
          data['card_payload']!,
          _cardPayloadMeta,
        ),
      );
    }
    if (data.containsKey('card_status')) {
      context.handle(
        _cardStatusMeta,
        cardStatus.isAcceptableOrUnknown(data['card_status']!, _cardStatusMeta),
      );
    }
    if (data.containsKey('entity_ref')) {
      context.handle(
        _entityRefMeta,
        entityRef.isAcceptableOrUnknown(data['entity_ref']!, _entityRefMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      ),
      cardType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_type'],
      ),
      cardPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_payload'],
      ),
      cardStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_status'],
      ),
      entityRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_ref'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final String id;

  /// 'YYYY-MM-DD' (IST). The Chat tab shows only today's day.
  final String day;

  /// user | assistant | card | notice
  final String role;
  final String? body;
  final String? cardType;
  final String? cardPayload;

  /// pending | confirmed | cancelled | expired
  final String? cardStatus;

  /// e.g. 'expense:42', 'loan:7'
  final String? entityRef;
  final DateTime createdAt;
  const ChatMessage({
    required this.id,
    required this.day,
    required this.role,
    this.body,
    this.cardType,
    this.cardPayload,
    this.cardStatus,
    this.entityRef,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<String>(day);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || body != null) {
      map['text'] = Variable<String>(body);
    }
    if (!nullToAbsent || cardType != null) {
      map['card_type'] = Variable<String>(cardType);
    }
    if (!nullToAbsent || cardPayload != null) {
      map['card_payload'] = Variable<String>(cardPayload);
    }
    if (!nullToAbsent || cardStatus != null) {
      map['card_status'] = Variable<String>(cardStatus);
    }
    if (!nullToAbsent || entityRef != null) {
      map['entity_ref'] = Variable<String>(entityRef);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      day: Value(day),
      role: Value(role),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      cardType: cardType == null && nullToAbsent
          ? const Value.absent()
          : Value(cardType),
      cardPayload: cardPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(cardPayload),
      cardStatus: cardStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(cardStatus),
      entityRef: entityRef == null && nullToAbsent
          ? const Value.absent()
          : Value(entityRef),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      role: serializer.fromJson<String>(json['role']),
      body: serializer.fromJson<String?>(json['body']),
      cardType: serializer.fromJson<String?>(json['cardType']),
      cardPayload: serializer.fromJson<String?>(json['cardPayload']),
      cardStatus: serializer.fromJson<String?>(json['cardStatus']),
      entityRef: serializer.fromJson<String?>(json['entityRef']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<String>(day),
      'role': serializer.toJson<String>(role),
      'body': serializer.toJson<String?>(body),
      'cardType': serializer.toJson<String?>(cardType),
      'cardPayload': serializer.toJson<String?>(cardPayload),
      'cardStatus': serializer.toJson<String?>(cardStatus),
      'entityRef': serializer.toJson<String?>(entityRef),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? day,
    String? role,
    Value<String?> body = const Value.absent(),
    Value<String?> cardType = const Value.absent(),
    Value<String?> cardPayload = const Value.absent(),
    Value<String?> cardStatus = const Value.absent(),
    Value<String?> entityRef = const Value.absent(),
    DateTime? createdAt,
  }) => ChatMessage(
    id: id ?? this.id,
    day: day ?? this.day,
    role: role ?? this.role,
    body: body.present ? body.value : this.body,
    cardType: cardType.present ? cardType.value : this.cardType,
    cardPayload: cardPayload.present ? cardPayload.value : this.cardPayload,
    cardStatus: cardStatus.present ? cardStatus.value : this.cardStatus,
    entityRef: entityRef.present ? entityRef.value : this.entityRef,
    createdAt: createdAt ?? this.createdAt,
  );
  ChatMessage copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessage(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      role: data.role.present ? data.role.value : this.role,
      body: data.body.present ? data.body.value : this.body,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      cardPayload: data.cardPayload.present
          ? data.cardPayload.value
          : this.cardPayload,
      cardStatus: data.cardStatus.present
          ? data.cardStatus.value
          : this.cardStatus,
      entityRef: data.entityRef.present ? data.entityRef.value : this.entityRef,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('role: $role, ')
          ..write('body: $body, ')
          ..write('cardType: $cardType, ')
          ..write('cardPayload: $cardPayload, ')
          ..write('cardStatus: $cardStatus, ')
          ..write('entityRef: $entityRef, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    day,
    role,
    body,
    cardType,
    cardPayload,
    cardStatus,
    entityRef,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == this.id &&
          other.day == this.day &&
          other.role == this.role &&
          other.body == this.body &&
          other.cardType == this.cardType &&
          other.cardPayload == this.cardPayload &&
          other.cardStatus == this.cardStatus &&
          other.entityRef == this.entityRef &&
          other.createdAt == this.createdAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<String> id;
  final Value<String> day;
  final Value<String> role;
  final Value<String?> body;
  final Value<String?> cardType;
  final Value<String?> cardPayload;
  final Value<String?> cardStatus;
  final Value<String?> entityRef;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.role = const Value.absent(),
    this.body = const Value.absent(),
    this.cardType = const Value.absent(),
    this.cardPayload = const Value.absent(),
    this.cardStatus = const Value.absent(),
    this.entityRef = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String day,
    required String role,
    this.body = const Value.absent(),
    this.cardType = const Value.absent(),
    this.cardPayload = const Value.absent(),
    this.cardStatus = const Value.absent(),
    this.entityRef = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       role = Value(role);
  static Insertable<ChatMessage> custom({
    Expression<String>? id,
    Expression<String>? day,
    Expression<String>? role,
    Expression<String>? body,
    Expression<String>? cardType,
    Expression<String>? cardPayload,
    Expression<String>? cardStatus,
    Expression<String>? entityRef,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (role != null) 'role': role,
      if (body != null) 'text': body,
      if (cardType != null) 'card_type': cardType,
      if (cardPayload != null) 'card_payload': cardPayload,
      if (cardStatus != null) 'card_status': cardStatus,
      if (entityRef != null) 'entity_ref': entityRef,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? day,
    Value<String>? role,
    Value<String?>? body,
    Value<String?>? cardType,
    Value<String?>? cardPayload,
    Value<String?>? cardStatus,
    Value<String?>? entityRef,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      role: role ?? this.role,
      body: body ?? this.body,
      cardType: cardType ?? this.cardType,
      cardPayload: cardPayload ?? this.cardPayload,
      cardStatus: cardStatus ?? this.cardStatus,
      entityRef: entityRef ?? this.entityRef,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (cardPayload.present) {
      map['card_payload'] = Variable<String>(cardPayload.value);
    }
    if (cardStatus.present) {
      map['card_status'] = Variable<String>(cardStatus.value);
    }
    if (entityRef.present) {
      map['entity_ref'] = Variable<String>(entityRef.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('role: $role, ')
          ..write('body: $body, ')
          ..write('cardType: $cardType, ')
          ..write('cardPayload: $cardPayload, ')
          ..write('cardStatus: $cardStatus, ')
          ..write('entityRef: $entityRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $LoansTable loans = $LoansTable(this);
  late final $LoanRepaymentsTable loanRepayments = $LoanRepaymentsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    expenses,
    budgets,
    people,
    loans,
    loanRepayments,
    chatMessages,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required int colorLight,
  required int colorDark,
  required String icon,
  Value<bool> isDefault,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> colorLight,
  Value<int> colorDark,
  Value<String> icon,
  Value<bool> isDefault,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'categories__id__expenses__category_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: 'categories__id__budgets__category_id',
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<int> get colorLight => $composableBuilder(
    column: $table.colorLight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorDark => $composableBuilder(
    column: $table.colorDark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<int> get colorLight => $composableBuilder(
    column: $table.colorLight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorDark => $composableBuilder(
    column: $table.colorDark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<int> get colorLight => $composableBuilder(
    column: $table.colorLight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorDark =>
      $composableBuilder(column: $table.colorDark, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool expensesRefs, bool budgetsRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorLight = const Value.absent(),
                Value<int> colorDark = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                colorLight: colorLight,
                colorDark: colorDark,
                icon: icon,
                isDefault: isDefault,
                isArchived: isArchived,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int colorLight,
                required int colorDark,
                required String icon,
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                colorLight: colorLight,
                colorDark: colorDark,
                icon: icon,
                isDefault: isDefault,
                isArchived: isArchived,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({expensesRefs = false, budgetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (expensesRefs) db.expenses,
                if (budgetsRefs) db.budgets,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (expensesRefs)
                    await $_getPrefetchedDataByColumns<
                      Category,
                      $CategoriesTable,
                      Expense,
                      $ExpensesTable
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._expensesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).expensesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                  if (budgetsRefs)
                    await $_getPrefetchedDataByColumns<
                      Category,
                      $CategoriesTable,
                      Budget,
                      $BudgetsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._budgetsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).budgetsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool expensesRefs, bool budgetsRefs})
    >;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  required int amountPaise,
  required int categoryId,
  required String item,
  Value<String?> location,
  Value<String?> paymentMethod,
  required String spentOn,
  Value<String?> rawText,
  Value<String> source,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  Value<int> amountPaise,
  Value<int> categoryId,
  Value<String> item,
  Value<String?> location,
  Value<String?> paymentMethod,
  Value<String> spentOn,
  Value<String?> rawText,
  Value<String> source,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('expenses__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spentOn => $composableBuilder(
    column: $table.spentOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spentOn => $composableBuilder(
    column: $table.spentOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spentOn =>
      $composableBuilder(column: $table.spentOn, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (Expense, $$ExpensesTableReferences),
          Expense,
          PrefetchHooks Function({bool categoryId})
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
                Value<int> amountPaise = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<String> item = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String> spentOn = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                amountPaise: amountPaise,
                categoryId: categoryId,
                item: item,
                location: location,
                paymentMethod: paymentMethod,
                spentOn: spentOn,
                rawText: rawText,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amountPaise,
                required int categoryId,
                required String item,
                Value<String?> location = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                required String spentOn,
                Value<String?> rawText = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                amountPaise: amountPaise,
                categoryId: categoryId,
                item: item,
                location: location,
                paymentMethod: paymentMethod,
                spentOn: spentOn,
                rawText: rawText,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpensesTable, Expense>(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
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
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$ExpensesTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$ExpensesTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
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
      (Expense, $$ExpensesTableReferences),
      Expense,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<int?> categoryId,
  required int monthlyLimitPaise,
  Value<DateTime> updatedAt,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<int?> categoryId,
  Value<int> monthlyLimitPaise,
  Value<DateTime> updatedAt,
});

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('budgets__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
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

  ColumnFilters<int> get monthlyLimitPaise => $composableBuilder(
    column: $table.monthlyLimitPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
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

  ColumnOrderings<int> get monthlyLimitPaise => $composableBuilder(
    column: $table.monthlyLimitPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get monthlyLimitPaise => $composableBuilder(
    column: $table.monthlyLimitPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, $$BudgetsTableReferences),
          Budget,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int> monthlyLimitPaise = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                categoryId: categoryId,
                monthlyLimitPaise: monthlyLimitPaise,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                required int monthlyLimitPaise,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                categoryId: categoryId,
                monthlyLimitPaise: monthlyLimitPaise,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, Budget>(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
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
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BudgetsTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$BudgetsTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
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

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, $$BudgetsTableReferences),
      Budget,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$PeopleTableCreateCompanionBuilder = PeopleCompanion Function({
  Value<int> id,
  required String name,
  required String nameKey,
  Value<DateTime> createdAt,
});
typedef $$PeopleTableUpdateCompanionBuilder = PeopleCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> nameKey,
  Value<DateTime> createdAt,
});

final class $$PeopleTableReferences
    extends BaseReferences<_$AppDatabase, $PeopleTable, Person> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LoansTable, List<Loan>> _loansRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.loans,
    aliasName: 'people__id__loans__person_id',
  );

  $$LoansTableProcessedTableManager get loansRefs {
    final manager = $$LoansTableTableManager(
      $_db,
      $_db.loans,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_loansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
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

  ColumnFilters<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> loansRefs(
    Expression<bool> Function($$LoansTableFilterComposer f) f,
  ) {
    final $$LoansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableFilterComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
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

  ColumnOrderings<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
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

  GeneratedColumn<String> get nameKey =>
      $composableBuilder(column: $table.nameKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> loansRefs<T extends Object>(
    Expression<T> Function($$LoansTableAnnotationComposer a) f,
  ) {
    final $$LoansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableAnnotationComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleTable,
          Person,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (Person, $$PeopleTableReferences),
          Person,
          PrefetchHooks Function({bool loansRefs})
        > {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                name: name,
                nameKey: nameKey,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String nameKey,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                name: name,
                nameKey: nameKey,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeopleTable, Person>(table),
                  $$PeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({loansRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (loansRefs) db.loans],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (loansRefs)
                    await $_getPrefetchedDataByColumns<
                      Person,
                      $PeopleTable,
                      Loan,
                      $LoansTable
                    >(
                      currentTable: table,
                      referencedTable: $$PeopleTableReferences._loansRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$PeopleTableReferences(db, table, p0).loansRefs,
                      currentColumn: 'id',
                      referencedColumn: 'person_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleTable,
      Person,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (Person, $$PeopleTableReferences),
      Person,
      PrefetchHooks Function({bool loansRefs})
    >;
typedef $$LoansTableCreateCompanionBuilder = LoansCompanion Function({
  Value<int> id,
  required int personId,
  required String direction,
  required int principalPaise,
  Value<String?> note,
  Value<String?> paymentMethod,
  required String happenedOn,
  Value<String?> rawText,
  Value<DateTime> createdAt,
  Value<DateTime?> deletedAt,
});
typedef $$LoansTableUpdateCompanionBuilder = LoansCompanion Function({
  Value<int> id,
  Value<int> personId,
  Value<String> direction,
  Value<int> principalPaise,
  Value<String?> note,
  Value<String?> paymentMethod,
  Value<String> happenedOn,
  Value<String?> rawText,
  Value<DateTime> createdAt,
  Value<DateTime?> deletedAt,
});

final class $$LoansTableReferences
    extends BaseReferences<_$AppDatabase, $LoansTable, Loan> {
  $$LoansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('loans__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LoanRepaymentsTable, List<LoanRepayment>>
  _loanRepaymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loanRepayments,
    aliasName: 'loans__id__loan_repayments__loan_id',
  );

  $$LoanRepaymentsTableProcessedTableManager get loanRepaymentsRefs {
    final manager = $$LoanRepaymentsTableTableManager(
      $_db,
      $_db.loanRepayments,
    ).filter((f) => f.loanId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_loanRepaymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LoansTableFilterComposer extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableFilterComposer({
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

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get principalPaise => $composableBuilder(
    column: $table.principalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get happenedOn => $composableBuilder(
    column: $table.happenedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> loanRepaymentsRefs(
    Expression<bool> Function($$LoanRepaymentsTableFilterComposer f) f,
  ) {
    final $$LoanRepaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loanRepayments,
      getReferencedColumn: (t) => t.loanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoanRepaymentsTableFilterComposer(
            $db: $db,
            $table: $db.loanRepayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LoansTableOrderingComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableOrderingComposer({
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

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get principalPaise => $composableBuilder(
    column: $table.principalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get happenedOn => $composableBuilder(
    column: $table.happenedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get principalPaise => $composableBuilder(
    column: $table.principalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get happenedOn => $composableBuilder(
    column: $table.happenedOn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> loanRepaymentsRefs<T extends Object>(
    Expression<T> Function($$LoanRepaymentsTableAnnotationComposer a) f,
  ) {
    final $$LoanRepaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loanRepayments,
      getReferencedColumn: (t) => t.loanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoanRepaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.loanRepayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LoansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoansTable,
          Loan,
          $$LoansTableFilterComposer,
          $$LoansTableOrderingComposer,
          $$LoansTableAnnotationComposer,
          $$LoansTableCreateCompanionBuilder,
          $$LoansTableUpdateCompanionBuilder,
          (Loan, $$LoansTableReferences),
          Loan,
          PrefetchHooks Function({bool personId, bool loanRepaymentsRefs})
        > {
  $$LoansTableTableManager(_$AppDatabase db, $LoansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> principalPaise = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String> happenedOn = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => LoansCompanion(
                id: id,
                personId: personId,
                direction: direction,
                principalPaise: principalPaise,
                note: note,
                paymentMethod: paymentMethod,
                happenedOn: happenedOn,
                rawText: rawText,
                createdAt: createdAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int personId,
                required String direction,
                required int principalPaise,
                Value<String?> note = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                required String happenedOn,
                Value<String?> rawText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => LoansCompanion.insert(
                id: id,
                personId: personId,
                direction: direction,
                principalPaise: principalPaise,
                note: note,
                paymentMethod: paymentMethod,
                happenedOn: happenedOn,
                rawText: rawText,
                createdAt: createdAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LoansTable, Loan>(table),
                  $$LoansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({personId = false, loanRepaymentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (loanRepaymentsRefs) db.loanRepayments,
                  ],
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
                        if (personId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.personId,
                            referencedTable: $$LoansTableReferences
                                ._personIdTable(db),
                            referencedColumn: $$LoansTableReferences
                                ._personIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (loanRepaymentsRefs)
                        await $_getPrefetchedDataByColumns<
                          Loan,
                          $LoansTable,
                          LoanRepayment,
                          $LoanRepaymentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$LoansTableReferences
                              ._loanRepaymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LoansTableReferences(
                                db,
                                table,
                                p0,
                              ).loanRepaymentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'loan_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LoansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoansTable,
      Loan,
      $$LoansTableFilterComposer,
      $$LoansTableOrderingComposer,
      $$LoansTableAnnotationComposer,
      $$LoansTableCreateCompanionBuilder,
      $$LoansTableUpdateCompanionBuilder,
      (Loan, $$LoansTableReferences),
      Loan,
      PrefetchHooks Function({bool personId, bool loanRepaymentsRefs})
    >;
typedef $$LoanRepaymentsTableCreateCompanionBuilder =
    LoanRepaymentsCompanion Function({
      Value<int> id,
      required int loanId,
      required int amountPaise,
      required String paidOn,
      Value<String?> rawText,
      Value<DateTime> createdAt,
    });
typedef $$LoanRepaymentsTableUpdateCompanionBuilder =
    LoanRepaymentsCompanion Function({
      Value<int> id,
      Value<int> loanId,
      Value<int> amountPaise,
      Value<String> paidOn,
      Value<String?> rawText,
      Value<DateTime> createdAt,
    });

final class $$LoanRepaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $LoanRepaymentsTable, LoanRepayment> {
  $$LoanRepaymentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LoansTable _loanIdTable(_$AppDatabase db) =>
      db.loans.createAlias('loan_repayments__loan_id__loans__id');

  $$LoansTableProcessedTableManager get loanId {
    final $_column = $_itemColumn<int>('loan_id')!;

    final manager = $$LoansTableTableManager(
      $_db,
      $_db.loans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_loanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LoanRepaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $LoanRepaymentsTable> {
  $$LoanRepaymentsTableFilterComposer({
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

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LoansTableFilterComposer get loanId {
    final $$LoansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loanId,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableFilterComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoanRepaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoanRepaymentsTable> {
  $$LoanRepaymentsTableOrderingComposer({
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

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LoansTableOrderingComposer get loanId {
    final $$LoansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loanId,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableOrderingComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoanRepaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoanRepaymentsTable> {
  $$LoanRepaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paidOn =>
      $composableBuilder(column: $table.paidOn, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LoansTableAnnotationComposer get loanId {
    final $$LoansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loanId,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableAnnotationComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoanRepaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoanRepaymentsTable,
          LoanRepayment,
          $$LoanRepaymentsTableFilterComposer,
          $$LoanRepaymentsTableOrderingComposer,
          $$LoanRepaymentsTableAnnotationComposer,
          $$LoanRepaymentsTableCreateCompanionBuilder,
          $$LoanRepaymentsTableUpdateCompanionBuilder,
          (LoanRepayment, $$LoanRepaymentsTableReferences),
          LoanRepayment,
          PrefetchHooks Function({bool loanId})
        > {
  $$LoanRepaymentsTableTableManager(
    _$AppDatabase db,
    $LoanRepaymentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoanRepaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoanRepaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoanRepaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> loanId = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String> paidOn = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LoanRepaymentsCompanion(
                id: id,
                loanId: loanId,
                amountPaise: amountPaise,
                paidOn: paidOn,
                rawText: rawText,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int loanId,
                required int amountPaise,
                required String paidOn,
                Value<String?> rawText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LoanRepaymentsCompanion.insert(
                id: id,
                loanId: loanId,
                amountPaise: amountPaise,
                paidOn: paidOn,
                rawText: rawText,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LoanRepaymentsTable, LoanRepayment>(table),
                  $$LoanRepaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({loanId = false}) {
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
                    if (loanId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.loanId,
                        referencedTable: $$LoanRepaymentsTableReferences
                            ._loanIdTable(db),
                        referencedColumn: $$LoanRepaymentsTableReferences
                            ._loanIdTable(db)
                            .id,
                      ) as T;
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

typedef $$LoanRepaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoanRepaymentsTable,
      LoanRepayment,
      $$LoanRepaymentsTableFilterComposer,
      $$LoanRepaymentsTableOrderingComposer,
      $$LoanRepaymentsTableAnnotationComposer,
      $$LoanRepaymentsTableCreateCompanionBuilder,
      $$LoanRepaymentsTableUpdateCompanionBuilder,
      (LoanRepayment, $$LoanRepaymentsTableReferences),
      LoanRepayment,
      PrefetchHooks Function({bool loanId})
    >;
typedef $$ChatMessagesTableCreateCompanionBuilder =
    ChatMessagesCompanion Function({
      required String id,
      required String day,
      required String role,
      Value<String?> body,
      Value<String?> cardType,
      Value<String?> cardPayload,
      Value<String?> cardStatus,
      Value<String?> entityRef,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ChatMessagesTableUpdateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<String> id,
      Value<String> day,
      Value<String> role,
      Value<String?> body,
      Value<String?> cardType,
      Value<String?> cardPayload,
      Value<String?> cardStatus,
      Value<String?> entityRef,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardPayload => $composableBuilder(
    column: $table.cardPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardStatus => $composableBuilder(
    column: $table.cardStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityRef => $composableBuilder(
    column: $table.entityRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardPayload => $composableBuilder(
    column: $table.cardPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardStatus => $composableBuilder(
    column: $table.cardStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityRef => $composableBuilder(
    column: $table.entityRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<String> get cardPayload => $composableBuilder(
    column: $table.cardPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardStatus => $composableBuilder(
    column: $table.cardStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityRef =>
      $composableBuilder(column: $table.entityRef, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ChatMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessagesTable,
          ChatMessage,
          $$ChatMessagesTableFilterComposer,
          $$ChatMessagesTableOrderingComposer,
          $$ChatMessagesTableAnnotationComposer,
          $$ChatMessagesTableCreateCompanionBuilder,
          $$ChatMessagesTableUpdateCompanionBuilder,
          (
            ChatMessage,
            BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>,
          ),
          ChatMessage,
          PrefetchHooks Function()
        > {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> cardType = const Value.absent(),
                Value<String?> cardPayload = const Value.absent(),
                Value<String?> cardStatus = const Value.absent(),
                Value<String?> entityRef = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion(
                id: id,
                day: day,
                role: role,
                body: body,
                cardType: cardType,
                cardPayload: cardPayload,
                cardStatus: cardStatus,
                entityRef: entityRef,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String day,
                required String role,
                Value<String?> body = const Value.absent(),
                Value<String?> cardType = const Value.absent(),
                Value<String?> cardPayload = const Value.absent(),
                Value<String?> cardStatus = const Value.absent(),
                Value<String?> entityRef = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion.insert(
                id: id,
                day: day,
                role: role,
                body: body,
                cardType: cardType,
                cardPayload: cardPayload,
                cardStatus: cardStatus,
                entityRef: entityRef,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChatMessagesTable, ChatMessage>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ChatMessagesTable,
                    ChatMessage
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessagesTable,
      ChatMessage,
      $$ChatMessagesTableFilterComposer,
      $$ChatMessagesTableOrderingComposer,
      $$ChatMessagesTableAnnotationComposer,
      $$ChatMessagesTableCreateCompanionBuilder,
      $$ChatMessagesTableUpdateCompanionBuilder,
      (
        ChatMessage,
        BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>,
      ),
      ChatMessage,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$LoansTableTableManager get loans =>
      $$LoansTableTableManager(_db, _db.loans);
  $$LoanRepaymentsTableTableManager get loanRepayments =>
      $$LoanRepaymentsTableTableManager(_db, _db.loanRepayments);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
}
