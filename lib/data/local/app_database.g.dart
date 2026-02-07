// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TarifasTable extends Tarifas with TableInfo<$TarifasTable, Tarifa> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TarifasTable(this.attachedDatabase, [this._alias]);
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
      'odoo_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, odooId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tarifas';
  @override
  VerificationContext validateIntegrity(Insertable<Tarifa> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('odoo_id')) {
      context.handle(_odooIdMeta,
          odooId.isAcceptableOrUnknown(data['odoo_id']!, _odooIdMeta));
    } else if (isInserting) {
      context.missing(_odooIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tarifa map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tarifa(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      odooId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}odoo_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $TarifasTable createAlias(String alias) {
    return $TarifasTable(attachedDatabase, alias);
  }
}

class Tarifa extends DataClass implements Insertable<Tarifa> {
  final int id;
  final int odooId;
  final String name;
  const Tarifa({required this.id, required this.odooId, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['odoo_id'] = Variable<int>(odooId);
    map['name'] = Variable<String>(name);
    return map;
  }

  TarifasCompanion toCompanion(bool nullToAbsent) {
    return TarifasCompanion(
      id: Value(id),
      odooId: Value(odooId),
      name: Value(name),
    );
  }

  factory Tarifa.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tarifa(
      id: serializer.fromJson<int>(json['id']),
      odooId: serializer.fromJson<int>(json['odooId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'odooId': serializer.toJson<int>(odooId),
      'name': serializer.toJson<String>(name),
    };
  }

  Tarifa copyWith({int? id, int? odooId, String? name}) => Tarifa(
        id: id ?? this.id,
        odooId: odooId ?? this.odooId,
        name: name ?? this.name,
      );
  Tarifa copyWithCompanion(TarifasCompanion data) {
    return Tarifa(
      id: data.id.present ? data.id.value : this.id,
      odooId: data.odooId.present ? data.odooId.value : this.odooId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tarifa(')
          ..write('id: $id, ')
          ..write('odooId: $odooId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, odooId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tarifa &&
          other.id == this.id &&
          other.odooId == this.odooId &&
          other.name == this.name);
}

class TarifasCompanion extends UpdateCompanion<Tarifa> {
  final Value<int> id;
  final Value<int> odooId;
  final Value<String> name;
  const TarifasCompanion({
    this.id = const Value.absent(),
    this.odooId = const Value.absent(),
    this.name = const Value.absent(),
  });
  TarifasCompanion.insert({
    this.id = const Value.absent(),
    required int odooId,
    required String name,
  })  : odooId = Value(odooId),
        name = Value(name);
  static Insertable<Tarifa> custom({
    Expression<int>? id,
    Expression<int>? odooId,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (odooId != null) 'odoo_id': odooId,
      if (name != null) 'name': name,
    });
  }

  TarifasCompanion copyWith(
      {Value<int>? id, Value<int>? odooId, Value<String>? name}) {
    return TarifasCompanion(
      id: id ?? this.id,
      odooId: odooId ?? this.odooId,
      name: name ?? this.name,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TarifasCompanion(')
          ..write('id: $id, ')
          ..write('odooId: $odooId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

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
  static const VerificationMeta _tarifaIdMeta =
      const VerificationMeta('tarifaId');
  @override
  late final GeneratedColumn<int> tarifaId = GeneratedColumn<int>(
      'tarifa_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tarifas (odoo_id)'));
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
  @override
  List<GeneratedColumn> get $columns =>
      [id, odooId, name, email, phone, city, tarifaId, pendingSync, isDeleted];
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
    if (data.containsKey('tarifa_id')) {
      context.handle(_tarifaIdMeta,
          tarifaId.isAcceptableOrUnknown(data['tarifa_id']!, _tarifaIdMeta));
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
      tarifaId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tarifa_id']),
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
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
  final int? tarifaId;
  final bool pendingSync;
  final bool isDeleted;
  const Cliente(
      {required this.id,
      this.odooId,
      required this.name,
      this.email,
      this.phone,
      this.city,
      this.tarifaId,
      required this.pendingSync,
      required this.isDeleted});
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
    if (!nullToAbsent || tarifaId != null) {
      map['tarifa_id'] = Variable<int>(tarifaId);
    }
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['is_deleted'] = Variable<bool>(isDeleted);
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
      tarifaId: tarifaId == null && nullToAbsent
          ? const Value.absent()
          : Value(tarifaId),
      pendingSync: Value(pendingSync),
      isDeleted: Value(isDeleted),
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
      tarifaId: serializer.fromJson<int?>(json['tarifaId']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
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
      'tarifaId': serializer.toJson<int?>(tarifaId),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Cliente copyWith(
          {int? id,
          Value<int?> odooId = const Value.absent(),
          String? name,
          Value<String?> email = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> city = const Value.absent(),
          Value<int?> tarifaId = const Value.absent(),
          bool? pendingSync,
          bool? isDeleted}) =>
      Cliente(
        id: id ?? this.id,
        odooId: odooId.present ? odooId.value : this.odooId,
        name: name ?? this.name,
        email: email.present ? email.value : this.email,
        phone: phone.present ? phone.value : this.phone,
        city: city.present ? city.value : this.city,
        tarifaId: tarifaId.present ? tarifaId.value : this.tarifaId,
        pendingSync: pendingSync ?? this.pendingSync,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Cliente copyWithCompanion(ClientesCompanion data) {
    return Cliente(
      id: data.id.present ? data.id.value : this.id,
      odooId: data.odooId.present ? data.odooId.value : this.odooId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      city: data.city.present ? data.city.value : this.city,
      tarifaId: data.tarifaId.present ? data.tarifaId.value : this.tarifaId,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
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
          ..write('tarifaId: $tarifaId, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, odooId, name, email, phone, city, tarifaId, pendingSync, isDeleted);
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
          other.tarifaId == this.tarifaId &&
          other.pendingSync == this.pendingSync &&
          other.isDeleted == this.isDeleted);
}

class ClientesCompanion extends UpdateCompanion<Cliente> {
  final Value<int> id;
  final Value<int?> odooId;
  final Value<String> name;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<String?> city;
  final Value<int?> tarifaId;
  final Value<bool> pendingSync;
  final Value<bool> isDeleted;
  const ClientesCompanion({
    this.id = const Value.absent(),
    this.odooId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.city = const Value.absent(),
    this.tarifaId = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  ClientesCompanion.insert({
    this.id = const Value.absent(),
    this.odooId = const Value.absent(),
    required String name,
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.city = const Value.absent(),
    this.tarifaId = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Cliente> custom({
    Expression<int>? id,
    Expression<int>? odooId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? city,
    Expression<int>? tarifaId,
    Expression<bool>? pendingSync,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (odooId != null) 'odoo_id': odooId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (city != null) 'city': city,
      if (tarifaId != null) 'tarifa_id': tarifaId,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  ClientesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? odooId,
      Value<String>? name,
      Value<String?>? email,
      Value<String?>? phone,
      Value<String?>? city,
      Value<int?>? tarifaId,
      Value<bool>? pendingSync,
      Value<bool>? isDeleted}) {
    return ClientesCompanion(
      id: id ?? this.id,
      odooId: odooId ?? this.odooId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      tarifaId: tarifaId ?? this.tarifaId,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
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
    if (tarifaId.present) {
      map['tarifa_id'] = Variable<int>(tarifaId.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
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
          ..write('tarifaId: $tarifaId, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TarifasTable tarifas = $TarifasTable(this);
  late final $ClientesTable clientes = $ClientesTable(this);
  late final ClientesDao clientesDao = ClientesDao(this as AppDatabase);
  late final TarifasDao tarifasDao = TarifasDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tarifas, clientes];
}

typedef $$TarifasTableCreateCompanionBuilder = TarifasCompanion Function({
  Value<int> id,
  required int odooId,
  required String name,
});
typedef $$TarifasTableUpdateCompanionBuilder = TarifasCompanion Function({
  Value<int> id,
  Value<int> odooId,
  Value<String> name,
});

final class $$TarifasTableReferences
    extends BaseReferences<_$AppDatabase, $TarifasTable, Tarifa> {
  $$TarifasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ClientesTable, List<Cliente>> _clientesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.clientes,
          aliasName:
              $_aliasNameGenerator(db.tarifas.odooId, db.clientes.tarifaId));

  $$ClientesTableProcessedTableManager get clientesRefs {
    final manager = $$ClientesTableTableManager($_db, $_db.clientes).filter(
        (f) => f.tarifaId.odooId.sqlEquals($_itemColumn<int>('odoo_id')!));

    final cache = $_typedResult.readTableOrNull(_clientesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TarifasTableFilterComposer
    extends Composer<_$AppDatabase, $TarifasTable> {
  $$TarifasTableFilterComposer({
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

  Expression<bool> clientesRefs(
      Expression<bool> Function($$ClientesTableFilterComposer f) f) {
    final $$ClientesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.odooId,
        referencedTable: $db.clientes,
        getReferencedColumn: (t) => t.tarifaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientesTableFilterComposer(
              $db: $db,
              $table: $db.clientes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TarifasTableOrderingComposer
    extends Composer<_$AppDatabase, $TarifasTable> {
  $$TarifasTableOrderingComposer({
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
}

class $$TarifasTableAnnotationComposer
    extends Composer<_$AppDatabase, $TarifasTable> {
  $$TarifasTableAnnotationComposer({
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

  Expression<T> clientesRefs<T extends Object>(
      Expression<T> Function($$ClientesTableAnnotationComposer a) f) {
    final $$ClientesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.odooId,
        referencedTable: $db.clientes,
        getReferencedColumn: (t) => t.tarifaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientesTableAnnotationComposer(
              $db: $db,
              $table: $db.clientes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TarifasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TarifasTable,
    Tarifa,
    $$TarifasTableFilterComposer,
    $$TarifasTableOrderingComposer,
    $$TarifasTableAnnotationComposer,
    $$TarifasTableCreateCompanionBuilder,
    $$TarifasTableUpdateCompanionBuilder,
    (Tarifa, $$TarifasTableReferences),
    Tarifa,
    PrefetchHooks Function({bool clientesRefs})> {
  $$TarifasTableTableManager(_$AppDatabase db, $TarifasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TarifasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TarifasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TarifasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> odooId = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              TarifasCompanion(
            id: id,
            odooId: odooId,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int odooId,
            required String name,
          }) =>
              TarifasCompanion.insert(
            id: id,
            odooId: odooId,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TarifasTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({clientesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (clientesRefs) db.clientes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (clientesRefs)
                    await $_getPrefetchedData<Tarifa, $TarifasTable, Cliente>(
                        currentTable: table,
                        referencedTable:
                            $$TarifasTableReferences._clientesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TarifasTableReferences(db, table, p0)
                                .clientesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.tarifaId == item.odooId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TarifasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TarifasTable,
    Tarifa,
    $$TarifasTableFilterComposer,
    $$TarifasTableOrderingComposer,
    $$TarifasTableAnnotationComposer,
    $$TarifasTableCreateCompanionBuilder,
    $$TarifasTableUpdateCompanionBuilder,
    (Tarifa, $$TarifasTableReferences),
    Tarifa,
    PrefetchHooks Function({bool clientesRefs})>;
typedef $$ClientesTableCreateCompanionBuilder = ClientesCompanion Function({
  Value<int> id,
  Value<int?> odooId,
  required String name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> city,
  Value<int?> tarifaId,
  Value<bool> pendingSync,
  Value<bool> isDeleted,
});
typedef $$ClientesTableUpdateCompanionBuilder = ClientesCompanion Function({
  Value<int> id,
  Value<int?> odooId,
  Value<String> name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> city,
  Value<int?> tarifaId,
  Value<bool> pendingSync,
  Value<bool> isDeleted,
});

final class $$ClientesTableReferences
    extends BaseReferences<_$AppDatabase, $ClientesTable, Cliente> {
  $$ClientesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TarifasTable _tarifaIdTable(_$AppDatabase db) =>
      db.tarifas.createAlias(
          $_aliasNameGenerator(db.clientes.tarifaId, db.tarifas.odooId));

  $$TarifasTableProcessedTableManager? get tarifaId {
    final $_column = $_itemColumn<int>('tarifa_id');
    if ($_column == null) return null;
    final manager = $$TarifasTableTableManager($_db, $_db.tarifas)
        .filter((f) => f.odooId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tarifaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

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

  $$TarifasTableFilterComposer get tarifaId {
    final $$TarifasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tarifaId,
        referencedTable: $db.tarifas,
        getReferencedColumn: (t) => t.odooId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TarifasTableFilterComposer(
              $db: $db,
              $table: $db.tarifas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
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

  $$TarifasTableOrderingComposer get tarifaId {
    final $$TarifasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tarifaId,
        referencedTable: $db.tarifas,
        getReferencedColumn: (t) => t.odooId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TarifasTableOrderingComposer(
              $db: $db,
              $table: $db.tarifas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
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

  $$TarifasTableAnnotationComposer get tarifaId {
    final $$TarifasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tarifaId,
        referencedTable: $db.tarifas,
        getReferencedColumn: (t) => t.odooId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TarifasTableAnnotationComposer(
              $db: $db,
              $table: $db.tarifas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
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
    (Cliente, $$ClientesTableReferences),
    Cliente,
    PrefetchHooks Function({bool tarifaId})> {
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
            Value<int?> tarifaId = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ClientesCompanion(
            id: id,
            odooId: odooId,
            name: name,
            email: email,
            phone: phone,
            city: city,
            tarifaId: tarifaId,
            pendingSync: pendingSync,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> odooId = const Value.absent(),
            required String name,
            Value<String?> email = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> city = const Value.absent(),
            Value<int?> tarifaId = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ClientesCompanion.insert(
            id: id,
            odooId: odooId,
            name: name,
            email: email,
            phone: phone,
            city: city,
            tarifaId: tarifaId,
            pendingSync: pendingSync,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ClientesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({tarifaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (tarifaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tarifaId,
                    referencedTable:
                        $$ClientesTableReferences._tarifaIdTable(db),
                    referencedColumn:
                        $$ClientesTableReferences._tarifaIdTable(db).odooId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
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
    (Cliente, $$ClientesTableReferences),
    Cliente,
    PrefetchHooks Function({bool tarifaId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TarifasTableTableManager get tarifas =>
      $$TarifasTableTableManager(_db, _db.tarifas);
  $$ClientesTableTableManager get clientes =>
      $$ClientesTableTableManager(_db, _db.clientes);
}
