// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ClientesTable extends Clientes with TableInfo<$ClientesTable, Cliente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _odooIdMeta = const VerificationMeta('odooId');
  @override
  late final GeneratedColumn<int> odooId = GeneratedColumn<int>(
      'odoo_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
      'city', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<DateTime> lastSync = GeneratedColumn<DateTime>(
      'last_sync', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        odooId,
        name,
        email,
        phone,
        city,
        pendingSync,
        isDeleted,
        lastSync,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clientes';
  @override
  VerificationContext validateIntegrity(Insertable<Cliente> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('odoo_id')) {
      context.handle(_odooIdMeta,
          odooId.isAcceptableOrUnknown(data['odoo_id']!, _odooIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('city')) {
      context.handle(
          _cityMeta, city.isAcceptableOrUnknown(data['city']!, _cityMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('last_sync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['last_sync']!, _lastSyncMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cliente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cliente(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      odooId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}odoo_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      city: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city']),
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ClientesTable createAlias(String alias) {
    return $ClientesTable(attachedDatabase, alias);
  }
}

class Cliente extends DataClass implements Insertable<Cliente> {
  final int id;
  final int? odooId;
  final String name;
  final String? email;
  final String? phone;
  final String? city;
  final bool pendingSync;
  final bool isDeleted;
  final DateTime? lastSync;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Cliente(
      {required this.id,
      this.odooId,
      required this.name,
      this.email,
      this.phone,
      this.city,
      required this.pendingSync,
      required this.isDeleted,
      this.lastSync,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || odooId != null) {
      map['odoo_id'] = Variable<int>(odooId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || lastSync != null) {
      map['last_sync'] = Variable<DateTime>(lastSync);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ClientesCompanion toCompanion(bool nullToAbsent) {
    return ClientesCompanion(
      id: Value(id),
      odooId:
          odooId == null && nullToAbsent ? const Value.absent() : Value(odooId),
      name: Value(name),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      pendingSync: Value(pendingSync),
      isDeleted: Value(isDeleted),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Cliente.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cliente(
      id: serializer.fromJson<int>(json['id']),
      odooId: serializer.fromJson<int?>(json['odooId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      city: serializer.fromJson<String?>(json['city']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastSync: serializer.fromJson<DateTime?>(json['lastSync']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'odooId': serializer.toJson<int?>(odooId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'phone': serializer.toJson<String?>(phone),
      'city': serializer.toJson<String?>(city),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastSync': serializer.toJson<DateTime?>(lastSync),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Cliente copyWith(
          {int? id,
          Value<int?> odooId = const Value.absent(),
          String? name,
          Value<String?> email = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> city = const Value.absent(),
          bool? pendingSync,
          bool? isDeleted,
          Value<DateTime?> lastSync = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Cliente(
        id: id ?? this.id,
        odooId: odooId.present ? odooId.value : this.odooId,
        name: name ?? this.name,
        email: email.present ? email.value : this.email,
        phone: phone.present ? phone.value : this.phone,
        city: city.present ? city.value : this.city,
        pendingSync: pendingSync ?? this.pendingSync,
        isDeleted: isDeleted ?? this.isDeleted,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Cliente copyWithCompanion(ClientesCompanion data) {
    return Cliente(
      id: data.id.present ? data.id.value : this.id,
      odooId: data.odooId.present ? data.odooId.value : this.odooId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      city: data.city.present ? data.city.value : this.city,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cliente(')
          ..write('id: $id, ')
          ..write('odooId: $odooId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('city: $city, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastSync: $lastSync, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, odooId, name, email, phone, city,
      pendingSync, isDeleted, lastSync, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cliente &&
          other.id == this.id &&
          other.odooId == this.odooId &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.city == this.city &&
          other.pendingSync == this.pendingSync &&
          other.isDeleted == this.isDeleted &&
          other.lastSync == this.lastSync &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ClientesCompanion extends UpdateCompanion<Cliente> {
  final Value<int> id;
  final Value<int?> odooId;
  final Value<String> name;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<String?> city;
  final Value<bool> pendingSync;
  final Value<bool> isDeleted;
  final Value<DateTime?> lastSync;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ClientesCompanion({
    this.id = const Value.absent(),
    this.odooId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.city = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ClientesCompanion.insert({
    this.id = const Value.absent(),
    this.odooId = const Value.absent(),
    required String name,
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.city = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Cliente> custom({
    Expression<int>? id,
    Expression<int>? odooId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? city,
    Expression<bool>? pendingSync,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastSync,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (odooId != null) 'odoo_id': odooId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (city != null) 'city': city,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastSync != null) 'last_sync': lastSync,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ClientesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? odooId,
      Value<String>? name,
      Value<String?>? email,
      Value<String?>? phone,
      Value<String?>? city,
      Value<bool>? pendingSync,
      Value<bool>? isDeleted,
      Value<DateTime?>? lastSync,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ClientesCompanion(
      id: id ?? this.id,
      odooId: odooId ?? this.odooId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSync: lastSync ?? this.lastSync,
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
    if (odooId.present) {
      map['odoo_id'] = Variable<int>(odooId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<DateTime>(lastSync.value);
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
    return (StringBuffer('ClientesCompanion(')
          ..write('id: $id, ')
          ..write('odooId: $odooId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('city: $city, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastSync: $lastSync, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClientesTable clientes = $ClientesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [clientes];
}

typedef $$ClientesTableCreateCompanionBuilder = ClientesCompanion Function({
  Value<int> id,
  Value<int?> odooId,
  required String name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> city,
  Value<bool> pendingSync,
  Value<bool> isDeleted,
  Value<DateTime?> lastSync,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ClientesTableUpdateCompanionBuilder = ClientesCompanion Function({
  Value<int> id,
  Value<int?> odooId,
  Value<String> name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> city,
  Value<bool> pendingSync,
  Value<bool> isDeleted,
  Value<DateTime?> lastSync,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$ClientesTableFilterComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get odooId => $composableBuilder(
      column: $table.odooId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ClientesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get odooId => $composableBuilder(
      column: $table.odooId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ClientesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get odooId =>
      $composableBuilder(column: $table.odooId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ClientesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClientesTable,
    Cliente,
    $$ClientesTableFilterComposer,
    $$ClientesTableOrderingComposer,
    $$ClientesTableAnnotationComposer,
    $$ClientesTableCreateCompanionBuilder,
    $$ClientesTableUpdateCompanionBuilder,
    (Cliente, BaseReferences<_$AppDatabase, $ClientesTable, Cliente>),
    Cliente,
    PrefetchHooks Function()> {
  $$ClientesTableTableManager(_$AppDatabase db, $ClientesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> odooId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> city = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime?> lastSync = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ClientesCompanion(
            id: id,
            odooId: odooId,
            name: name,
            email: email,
            phone: phone,
            city: city,
            pendingSync: pendingSync,
            isDeleted: isDeleted,
            lastSync: lastSync,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> odooId = const Value.absent(),
            required String name,
            Value<String?> email = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> city = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime?> lastSync = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ClientesCompanion.insert(
            id: id,
            odooId: odooId,
            name: name,
            email: email,
            phone: phone,
            city: city,
            pendingSync: pendingSync,
            isDeleted: isDeleted,
            lastSync: lastSync,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ClientesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClientesTable,
    Cliente,
    $$ClientesTableFilterComposer,
    $$ClientesTableOrderingComposer,
    $$ClientesTableAnnotationComposer,
    $$ClientesTableCreateCompanionBuilder,
    $$ClientesTableUpdateCompanionBuilder,
    (Cliente, BaseReferences<_$AppDatabase, $ClientesTable, Cliente>),
    Cliente,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClientesTableTableManager get clientes =>
      $$ClientesTableTableManager(_db, _db.clientes);
}
