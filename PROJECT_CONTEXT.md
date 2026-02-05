]633;E;echo "# Proyecto Flutter – Contexto para IA";4c913797-a980-4d2d-abcf-c94128636dee]633;C# Proyecto Flutter – Contexto para IA

## pubspec.yaml
name: myapp
description: "App offline-first de clientes con Odoo"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Database (solo SQLite nativo para Android)
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.8.0
  
  # HTTP para Odoo
  http: ^1.6.0
  
  # UI
  google_fonts: ^8.0.0
  xml: ^6.6.1
  provider: ^6.1.5+1
  shared_preferences: ^2.5.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  
  # Code generation
  drift_dev: ^2.14.0
  build_runner: ^2.10.5
  mockito: ^5.6.3
  flutter_launcher_icons: ^0.14.4

flutter:
  uses-material-design: true
  assets:
    - assets/images/

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/launcher_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/launcher_icon.png"

## Código fuente (lib/)

--------------------------------
### FILE: lib/data/clientes_repository.dart
--------------------------------

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote/odoo_service.dart';
import 'local/app_database.dart';
import 'local/dao/clientes_dao.dart';
import 'dart:developer' as developer;

class ClientesRepository {
  final OdooService? odooService;
  final ClientesDao clientesDao;
  final SharedPreferences sharedPreferences;

  var _progressStreamController = StreamController<String>.broadcast();
  Stream<String> get progressStream => _progressStreamController.stream;

  static const String lastSyncTimestampKey = 'last_sync_timestamp';

  ClientesRepository({
    this.odooService,
    required this.clientesDao,
    required this.sharedPreferences,
  });

  String _sanitizeString(dynamic value, {String defaultValue = ''}) {
    if (value is String) return value;
    if (value == false || value == null) return defaultValue;
    return value.toString();
  }

  Stream<List<Cliente>> watchClientes() {
    return clientesDao.watchAllClientes();
  }

  Future<void> syncClientes() async {
    if (_progressStreamController.isClosed) {
      _progressStreamController = StreamController<String>.broadcast();
    }

    if (odooService == null) {
      _progressStreamController.add("Sesión no iniciada. No se puede sincronizar.");
      return;
    }
    final prefs = sharedPreferences;
    DateTime? lastSync;

    final lastSyncString = prefs.getString(lastSyncTimestampKey);
    if (lastSyncString != null) {
      lastSync = DateTime.parse(lastSyncString);
    }

    developer.log('🚀 Iniciando proceso de sincronización...', name: 'ClientesRepository');
    _progressStreamController.add('Iniciando sincronización...');

    try {
      _progressStreamController.add('Contando registros en Odoo...');
      final totalToSync = await odooService!.countClientes(lastSync: lastSync);
      
      if (totalToSync == 0) {
        _progressStreamController.add('👍 ¡Todo está al día! No hay clientes nuevos para sincronizar.');
        await prefs.setString(lastSyncTimestampKey, DateTime.now().toIso8601String());
        return;
      }

      _progressStreamController.add('$totalToSync clientes para descargar.');

      final chunkSize = 50;
      int downloadedCount = 0;

      for (int offset = 0; offset < totalToSync; offset += chunkSize) {
        final message = 'Descargando clientes... ${offset + 1} - ${offset + chunkSize > totalToSync ? totalToSync : offset + chunkSize} de $totalToSync';
        _progressStreamController.add(message);

        final clientesFromOdoo = await odooService!.fetchClientesChunk(
          lastSync: lastSync,
          limit: chunkSize,
          offset: offset,
        );

        if (clientesFromOdoo.isNotEmpty) {
          final clientesToSave = clientesFromOdoo.map((clienteData) {
            // **LA SOLUCIÓN**
            // Priorizamos 'mobile' sobre 'phone'.
            final mobile = _sanitizeString(clienteData['mobile']);
            final phone = _sanitizeString(clienteData['phone']);
            final telefonoFinal = mobile.isNotEmpty ? mobile : phone;

            return ClientesCompanion(
              odooId: Value(clienteData['id'] as int),
              name: Value(_sanitizeString(clienteData['name'], defaultValue: 'Nombre no disponible')),
              email: Value(_sanitizeString(clienteData['email'])),
              phone: Value(telefonoFinal), // Usamos el teléfono final
              city: Value(_sanitizeString(clienteData['city'])),
              pendingSync: const Value(false),
            );
          });

          await clientesDao.insertOrUpdateAll(clientesToSave.toList());
          downloadedCount += clientesFromOdoo.length;
        }
      }
      
      final syncTime = DateTime.now();
      await prefs.setString(lastSyncTimestampKey, syncTime.toIso8601String());
      
      final successMessage = '✅ Sincronización completada. $downloadedCount clientes actualizados.';
      _progressStreamController.add(successMessage);

    } catch (e, s) {
      final errorMessage = '❌ Error durante la sincronización: $e';
      _progressStreamController.add(errorMessage);
      developer.log(errorMessage, stackTrace: s, name: 'ClientesRepository');
    }
  }

  void dispose() {
    if (!_progressStreamController.isClosed) {
      _progressStreamController.close();
    }
  }

  Future<void> createCliente(String name, String email, String phone, String city) async {
    if (odooService == null) throw Exception("Servicio Odoo no disponible");
    // Al crear un cliente, asumimos que el teléfono que nos dan es el móvil.
    final clienteData = {'name': name, 'email': email, 'mobile': phone, 'city': city, 'customer_rank': 1};
    try {
      final newOdooId = await odooService!.createCliente(clienteData);
      await clientesDao.insertCliente(ClientesCompanion(
        odooId: Value(newOdooId),
        name: Value(name),
        email: Value(email),
        phone: Value(phone),
        city: Value(city),
      ));
    } catch (e) {
      developer.log('❌ Error al crear el cliente: $e', name: 'ClientesRepository');
      rethrow;
    }
  }

  Future<void> updateCliente(Cliente cliente) async {
    if (odooService == null) throw Exception("Servicio Odoo no disponible");
    // Al actualizar, también enviamos el teléfono al campo 'mobile' de Odoo.
    final clienteData = {'name': cliente.name, 'email': cliente.email, 'mobile': cliente.phone, 'city': cliente.city};
    try {
      await odooService!.updateCliente(cliente.odooId!, clienteData);
      await clientesDao.updateCliente(cliente);
    } catch (e) {
      developer.log('❌ Error al actualizar el cliente: $e', name: 'ClientesRepository');
      rethrow;
    }
  }

  Future<void> deleteCliente(Cliente cliente) async {
    if (odooService == null) throw Exception("Servicio Odoo no disponible");
    try {
      await odooService!.deleteCliente(cliente.odooId!);
      await clientesDao.deleteCliente(cliente);
    } catch (e) {
      developer.log('❌ Error al eliminar el cliente: $e', name: 'ClientesRepository');
      rethrow;
    }
  }
}

--------------------------------
### FILE: lib/data/local/app_database.dart
--------------------------------
import 'package:drift/drift.dart';
import 'connection/mobile.dart';
import 'clientes_table.dart';
import 'dao/clientes_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Clientes], daos: [ClientesDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(openConnection());

  static final AppDatabase _instance = AppDatabase._();

  static AppDatabase get instance => _instance;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        // La forma correcta es usar `allTables` de la propia base de datos.
        // Primero, borramos todas las tablas.
        for (final table in allTables) {
          await m.drop(table);
        }

        // Luego, las volvemos a crear.
        for (final table in allTables) {
          await m.create(table);
        }
      },
    );
  }
}

--------------------------------
### FILE: lib/data/local/app_database.g.dart
--------------------------------
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
  late final ClientesDao clientesDao = ClientesDao(this as AppDatabase);
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

--------------------------------
### FILE: lib/data/local/clientes_table.dart
--------------------------------
import 'package:drift/drift.dart';

class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get odooId => integer().nullable().unique()(); // ID remoto
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get city => text().nullable()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSync => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
--------------------------------
### FILE: lib/data/local/connection/mobile.dart
--------------------------------
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'clientes.sqlite'));
    return NativeDatabase(file);
  });
}
--------------------------------
### FILE: lib/data/local/dao/clientes_dao.dart
--------------------------------
import 'package:drift/drift.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/data/local/clientes_table.dart';

part 'clientes_dao.g.dart';

@DriftAccessor(tables: [Clientes])
class ClientesDao extends DatabaseAccessor<AppDatabase> with _$ClientesDaoMixin {
  ClientesDao(super.db);

  Stream<List<Cliente>> watchAllClientes() => select(clientes).watch();

  Future<void> insertCliente(ClientesCompanion cliente) => into(clientes).insert(cliente);
  
  // Método para insertar/actualizar una lista de clientes.
  // Usado por el Repository para la sincronización.
  Future<void> insertOrUpdateAll(List<ClientesCompanion> clientesList) {
    return batch((batch) {
      batch.insertAll(
        clientes,
        clientesList,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> updateCliente(Cliente cliente) => update(clientes).replace(cliente);
  
  Future<void> deleteCliente(Cliente cliente) => delete(clientes).delete(cliente);
}

--------------------------------
### FILE: lib/data/local/dao/clientes_dao.g.dart
--------------------------------
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clientes_dao.dart';

// ignore_for_file: type=lint
mixin _$ClientesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ClientesTable get clientes => attachedDatabase.clientes;
  ClientesDaoManager get managers => ClientesDaoManager(this);
}

class ClientesDaoManager {
  final _$ClientesDaoMixin _db;
  ClientesDaoManager(this._db);
  $$ClientesTableTableManager get clientes =>
      $$ClientesTableTableManager(_db.attachedDatabase, _db.clientes);
}

--------------------------------
### FILE: lib/data/remote/odoo_service.dart
--------------------------------
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:async';

class OdooService {
  final String serverUrl;
  final String dbName;
  late http.Client _client;
  String? _sessionId;
  int? uid;
  String? userName;
  String? userLogin;

  String get url => serverUrl;
  String get db => dbName;
  String? get sessionId => _sessionId;
  
  /// Returns true if the user is currently authenticated.
  bool get isUserLoggedIn => uid != null && _sessionId != null;

  OdooService({required this.serverUrl, required this.dbName}) {
    _client = http.Client();
  }

  void restoreSession(String newSessionId, int newUid, String newUserName, String newUserLogin) {
    _sessionId = newSessionId;
    uid = newUid;
    userName = newUserName;
    userLogin = newUserLogin;
    developer.log('🔄 Sesión restaurada para $userName. UID: $uid', name: 'OdooService');
  }

  Future<void> authenticate(String email, String password) async {
    final url = Uri.parse('$serverUrl/web/session/authenticate');
    
    final requestBody = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'db': dbName,
        'login': email,
        'password': password,
        'context': {},
      },
    });

    developer.log('🔐 Autenticando en $url para la base de datos $dbName', name: 'OdooService');
    
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          _sessionId = rawCookie.split(';').firstWhere(
            (c) => c.trim().startsWith('session_id='),
            orElse: () => ''
          ).split('=').last;
        }
        
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData.containsKey('error')) {
          final error = responseData['error'];
          developer.log('❌ Error de Odoo: ${error['message']}', name: 'OdooService');
          throw Exception('Error de Odoo: ${error['data']['debug']}');
        }

        final result = responseData['result'];
        if (result != null && result['uid'] != false) {
          uid = result['uid'];
          userName = result['name'];
          userLogin = result['username'];

          developer.log('✅ Autenticación exitosa para $userName. UID: $uid', name: 'OdooService');
        } else {
          // Si no hay UID, consideramos la autenticación fallida.
          _sessionId = null; // Borramos el sessionId si lo hubiera
          throw Exception('Credenciales incorrectas o respuesta inesperada.');
        }
      } else {
        developer.log('❌ Error HTTP ${response.statusCode}: ${response.body}', name: 'OdooService');
        throw Exception('Error de conexión con el servidor: ${response.statusCode}');
      }
    } on TimeoutException {
      developer.log('❌ Timeout en la autenticación', name: 'OdooService');
      throw Exception('El servidor no respondió a tiempo. Verifique la URL y su conexión.');
    } catch (e) {
      developer.log('❌ Excepción en authenticate: $e', name: 'OdooService');
      rethrow;
    }
  }

  Future<dynamic> _executeRpc(String path, String method, Map<String, dynamic> params) async {
    if (!isUserLoggedIn) {
      throw Exception('No autenticado. Por favor, inicie sesión primero.');
    }

    final url = Uri.parse('$serverUrl$path');
    final requestBody = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': params,
    });

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 45));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        if (responseData.containsKey('error')) {
          final error = responseData['error'];
          developer.log('❌ Error RPC de Odoo: ${error['message']}', name: 'OdooService', error: error);
          throw Exception('Error RPC: ${error['data']['debug']}');
        }
        return responseData['result'];
      } else {
        throw Exception('Error en la llamada RPC: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Excepción en _executeRpc: $e', name: 'OdooService');
      rethrow;
    }
  }
  Future<int> countClientes({DateTime? lastSync}) async {
    developer.log('🔍 Contando clientes para sincronizar...', name: 'OdooService');
    List<dynamic> domain = [
      ['customer_rank', '>', 0]
    ];
    if (lastSync != null) {
      final utcDate = lastSync.toUtc().toIso8601String().split('.')[0];
      domain.add(['write_date', '>', utcDate]);
    }
    final result = await _executeRpc('/web/dataset/call_kw/res.partner/search_count', 'call', {
        'args': [domain],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'search_count',
    });
    developer.log('✅ Conteo finalizado: $result clientes.', name: 'OdooService');
    return result is int ? result : 0;
  }

  Future<List<Map<String, dynamic>>> fetchClientesChunk({
    DateTime? lastSync,
    required int limit,
    required int offset,
  }) async {
    final syncLog = lastSync != null ? 'modificados desde ${lastSync.toIso8601String()}' : 'TODOS';
    developer.log('📡 Obteniendo clientes (lote de $limit a partir de $offset) $syncLog...', name: 'OdooService');

    List<dynamic> domain = [
      ['customer_rank', '>', 0]
    ];
    if (lastSync != null) {
      final utcDate = lastSync.toUtc().toIso8601String().split('.')[0];
      domain.add(['write_date', '>', utcDate]);
    }

    final result = await _executeRpc('/web/dataset/search_read', 'call', {
      'model': 'res.partner',
      'fields': ['id', 'name', 'email', 'phone', 'mobile', 'city', 'write_date'],
      'domain': domain,
      'limit': limit,
      'offset': offset,
      'sort': 'id ASC',
      'context': {},
    });

    if (result != null && result['records'] is List) {
      final records = List<Map<String, dynamic>>.from(result['records']);
      developer.log('✅ ${records.length} clientes recibidos en este lote.', name: 'OdooService');
      return records;
    }
    return [];
  }

  Future<int> createCliente(Map<String, dynamic> data) async {
    developer.log('➕ Creando cliente en Odoo: ${data['name']}', name: 'OdooService');
    final newId = await _executeRpc('/web/dataset/call_kw/res.partner/create', 'call', {
        'args': [data],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'create',
    });
    developer.log('✅ Cliente creado con ID: $newId', name: 'OdooService');
    return newId;
  }

  Future<void> updateCliente(int odooId, Map<String, dynamic> data) async {
    developer.log('✏️ Actualizando cliente Odoo ID: $odooId', name: 'OdooService');
    await _executeRpc('/web/dataset/call_kw/res.partner/write', 'call', {
        'args': [[odooId], data],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'write',
    });
    developer.log('✅ Cliente actualizado.', name: 'OdooService');
  }

  Future<void> deleteCliente(int odooId) async {
    developer.log('🗑️ Eliminando cliente Odoo ID: $odooId', name: 'OdooService');
     await _executeRpc('/web/dataset/call_kw/res.partner/unlink', 'call', {
        'args': [[odooId]],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'unlink',
    });
    developer.log('✅ Cliente eliminado.', name: 'OdooService');
  }
  
  void dispose() {
    _client.close();
  }
}

--------------------------------
### FILE: lib/main.dart
--------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/local/app_database.dart';
import 'data/clientes_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/clientes_provider.dart';
import 'pages/login_page.dart';
import 'widgets/main_scaffold.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  final AppDatabase database = AppDatabase.instance;

  // Crear el AuthProvider aquí para poder llamar a tryAutoLogin
  final authProvider = AuthProvider(sharedPreferences: sharedPreferences);
  await authProvider.tryAutoLogin(); // Llamada única al inicio

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: database),
        Provider.value(value: sharedPreferences),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(sharedPreferences: sharedPreferences),
        ),

        // ProxyProvider que construye ClientesRepository
        ProxyProvider<AuthProvider, ClientesRepository>(
          update: (context, auth, previous) => ClientesRepository(
            odooService: auth.odooService,
            clientesDao: database.clientesDao,
            sharedPreferences: sharedPreferences,
          ),
        ),

        // ProxyProvider para ClientesProvider
        ChangeNotifierProxyProvider<AuthProvider, ClientesProvider>(
          create: (context) => ClientesProvider(
            repository: context.read<ClientesRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) {
            final repository = context.read<ClientesRepository>();
            previous?.updateDependencies(repository, auth);
            return previous ?? ClientesProvider(repository: repository, authProvider: auth);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Clientes Offline-First',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: authProvider.isLoggedIn
              ? const MainScaffold()
              : const LoginPage(),
        );
      },
    );
  }
}

--------------------------------
### FILE: lib/pages/cliente_edit_page.dart
--------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/providers/clientes_provider.dart';

class ClienteEditPage extends StatefulWidget {
  final Cliente? cliente;

  const ClienteEditPage({super.key, this.cliente});

  @override
  State<ClienteEditPage> createState() => _ClienteEditPageState();
}

class _ClienteEditPageState extends State<ClienteEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;

  bool get _isEditing => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cliente?.name ?? '');
    _emailController = TextEditingController(text: widget.cliente?.email ?? '');
    _phoneController = TextEditingController(text: widget.cliente?.phone ?? '');
    _cityController = TextEditingController(text: widget.cliente?.city ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ClientesProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);

    try {
      if (_isEditing) {
        final updatedCliente = widget.cliente!.copyWith(
          name: _nameController.text.trim(),
          email: Value(_emailController.text.trim()),
          phone: Value(_phoneController.text.trim()),
          city: Value(_cityController.text.trim()),
        );
        await provider.updateCliente(updatedCliente);
      } else {
        await provider.createCliente(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _phoneController.text.trim(),
          _cityController.text.trim(),
        );
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Cliente actualizado' : 'Cliente creado'),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
      navigator.pop();

    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar cliente' : 'Nuevo cliente'),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildProfileHeader(colorScheme, theme.textTheme),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _nameController,
                labelText: 'Nombre completo',
                hintText: 'Juan García López',
                icon: Icons.person_outline_rounded,
                validator: (value) => (value == null || value.isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 25),
              _buildTextField(
                controller: _phoneController,
                labelText: 'Teléfono',
                hintText: '+34 623 377 364',
                icon: Icons.smartphone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 25),
              _buildTextField(
                controller: _emailController,
                labelText: 'Correo electrónico',
                hintText: 'juan.garcia@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 25),
              _buildTextField(
                controller: _cityController,
                labelText: 'Ciudad',
                hintText: 'Madrid, España',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveCliente,
        elevation: 4,
        child: const Icon(Icons.check_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: colorScheme.surface.withAlpha(128),
            child: Icon(
              Icons.person_outline_rounded,
              size: 45,
              color: colorScheme.onSurface.withAlpha(128),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            child: Text(
              'Cambiar foto',
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            labelText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

--------------------------------
### FILE: lib/pages/clientes_page.dart
--------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/pages/cliente_edit_page.dart';
import 'package:myapp/providers/clientes_provider.dart';
import 'package:myapp/providers/navigation_provider.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ClientesView();
  }
}

void _navigateToCliente(BuildContext context, {Cliente? cliente}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => ClienteEditPage(cliente: cliente),
    ),
  );
}

class _ClientesView extends StatefulWidget {
  const _ClientesView();

  @override
  State<_ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<_ClientesView> {
  Timer? _messageTimer;

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ClientesProvider>(
      builder: (context, provider, child) {
        final filteredClientes = _filterClientes(
            provider.clientes, 
            context.watch<NavigationProvider>().searchQuery
        );

        return Column(
          children: [
            _buildSyncStatus(provider),
            
            Expanded(
              child: provider.isLoading && provider.clientes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => provider.syncClientes(),
                      child: filteredClientes.isEmpty
                          ? _buildEmptyState(context.watch<NavigationProvider>().searchQuery)
                          : _buildClientesList(context, filteredClientes),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<Cliente> _filterClientes(List<Cliente> clientes, String searchQuery) {
    if (searchQuery.isEmpty) return clientes;
    final query = searchQuery.toLowerCase();
    return clientes.where((c) {
        final name = c.name.toLowerCase();
        final email = c.email?.toLowerCase() ?? '';
        final phone = c.phone?.toLowerCase() ?? '';
        return name.contains(query) || email.contains(query) || phone.contains(query);
    }).toList();
  }

  Widget _buildSyncStatus(ClientesProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (provider.syncMessage == null) {
      return const SizedBox.shrink();
    }

    final message = provider.syncMessage!;
    final isLoading = provider.isLoading;
    final isError = message.startsWith('❌');

    if (!isLoading) {
      _messageTimer?.cancel();
      _messageTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          // Implementación futura: El provider debería limpiar su propio mensaje.
        }
      });
    }
    
    return Material(
      elevation: 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
            gradient: isError
                ? null
                : LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: isError ? colorScheme.errorContainer : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  if (isLoading) SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)),
                  if (!isLoading) Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? colorScheme.error : colorScheme.onPrimary, size: 16),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message, style: theme.textTheme.bodySmall?.copyWith(color: isError ? colorScheme.onErrorContainer : colorScheme.onPrimary))),
                ],
              ),
              if (isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(String searchQuery) => ListView(
    children: [ 
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Icon(searchQuery.isEmpty ? Icons.people_outline : Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withAlpha(128)),
            const SizedBox(height: 16),
            Text(searchQuery.isEmpty ? 'No hay clientes' : 'No se encontraron resultados', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(179))),
            const SizedBox(height: 24),
            if (searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: () => context.read<ClientesProvider>().syncClientes(),
                icon: const Icon(Icons.sync),
                label: const Text('Sincronizar ahora'),
              )
          ],
        ),
      )
    ]
  );

  ListView _buildClientesList(BuildContext context, List<Cliente> clientes) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: clientes.length,
      itemBuilder: (context, i) {
        final cliente = clientes[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _navigateToCliente(context, cliente: cliente),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      cliente.name.isNotEmpty ? cliente.name[0].toUpperCase() : '?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (cliente.phone?.isNotEmpty == true)
                          Text(
                            cliente.phone!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

--------------------------------
### FILE: lib/pages/login_page.dart
--------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController(text: 'https://tumburu.es');
  final _dbController = TextEditingController(text: 'betat1');
  final _emailController = TextEditingController(text: 'duvalsoft@gmail.com');
  final _passwordController = TextEditingController(text: 'Odi1@99TU');

  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      final success = await authProvider.login(
        _urlController.text.trim(),
        _dbController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!success) {
        throw 'Credenciales incorrectas o error del servidor.';
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: ${e.toString()}'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _dbController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          _buildHeader(colorScheme, theme.textTheme),
                          const SizedBox(height: 30),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildCustomTextField(controller: _urlController, labelText: 'URL DEL SERVIDOR', icon: Icons.link_rounded, validator: (v) => v!.isEmpty ? 'La URL no puede estar vacía' : null, colorScheme: colorScheme, textTheme: theme.textTheme, keyboardType: TextInputType.url),
                                const SizedBox(height: 20),
                                _buildCustomTextField(controller: _dbController, labelText: 'BASE DE DATOS', icon: Icons.storage_rounded, validator: (v) => v!.isEmpty ? 'La base de datos no puede estar vacía' : null, colorScheme: colorScheme, textTheme: theme.textTheme),
                                const SizedBox(height: 20),
                                _buildCustomTextField(controller: _emailController, labelText: 'CORREO ELECTRÓNICO', icon: Icons.email_outlined, validator: (v) => v!.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v) ? 'Formato de correo no válido' : null, colorScheme: colorScheme, textTheme: theme.textTheme, keyboardType: TextInputType.emailAddress),
                                const SizedBox(height: 20),
                                _buildCustomTextField(controller: _passwordController, labelText: 'CONTRASEÑA', icon: Icons.lock_outline_rounded, isPassword: true, validator: (v) => v!.isEmpty ? 'La contraseña no puede estar vacía' : null, colorScheme: colorScheme, textTheme: theme.textTheme),
                              ],
                            ),
                          ),
                          const Spacer(flex: 3),
                          _buildConnectButton(colorScheme, theme.textTheme),
                          const SizedBox(height: 12),
                          _buildForgotPasswordLink(theme.textTheme, colorScheme),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface.withAlpha(128),
            boxShadow: [BoxShadow(color: colorScheme.primary.withAlpha(77), blurRadius: 10, spreadRadius: 2)],
            border: Border.all(color: colorScheme.onSurface.withAlpha(26), width: 2),
          ),
          child: Icon(Icons.pets, color: colorScheme.primary, size: 50),
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            Text('Tumburú', style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Container(
              width: 50,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        Text('Conecta con tu cuenta para continuar', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withAlpha(178))),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    bool isPassword = false,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(178), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscureText : false,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onFieldSubmitted: (_) => _login(),
        ),
      ],
    );
  }

  Widget _buildConnectButton(ColorScheme colorScheme, TextTheme textTheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _login,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary], begin: Alignment.centerLeft, end: Alignment.centerRight),
            boxShadow: [BoxShadow(color: colorScheme.primary.withAlpha(102), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: _isLoading
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: colorScheme.onPrimary))
                : Text('CONECTAR', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink(TextTheme textTheme, ColorScheme colorScheme) {
    return TextButton(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función no implementada todavía.'))),
      child: Text('¿Olvidaste tu contraseña?', style: textTheme.bodyMedium),
    );
  }
}

--------------------------------
### FILE: lib/pages/profile_page.dart
--------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  authProvider.userName ?? 'Nombre no disponible',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  authProvider.userLogin ?? 'Login no disponible',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionTitle(context, 'Detalles de la Conexión'),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.cloud_queue,
                title: 'Servidor',
                subtitle: authProvider.serverUrl ?? 'No disponible',
              ),
              const Divider(height: 1),
               _buildInfoTile(
                icon: Icons.storage,
                title: 'Base de Datos',
                subtitle: authProvider.dbName ?? 'No disponible',
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar Sesión'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext ctx) {
                return AlertDialog(
                  title: const Text('Confirmar'),
                  content: const Text('¿Estás seguro de que quieres cerrar la sesión?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    FilledButton(
                      child: const Text('Cerrar Sesión'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        context.read<AuthProvider>().logout(); 
                      },
                    ),
                  ],
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: theme.textTheme.bodyLarge),
    );
  }
}

--------------------------------
### FILE: lib/providers/auth_provider.dart
--------------------------------

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/remote/odoo_service.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences sharedPreferences;
  OdooService? _odooService;

  final _authChangeController = StreamController<bool>.broadcast();
  Stream<bool> get onAuthChanged => _authChangeController.stream;

  OdooService? get odooService => _odooService;
  bool get isLoggedIn => _odooService != null && _odooService!.isUserLoggedIn;
  int? get uid => _odooService?.uid;
  String? get userName => _odooService?.userName;
  String? get userLogin => _odooService?.userLogin;
  String? get serverUrl => _odooService?.url;
  String? get dbName => _odooService?.db;
  
  bool _autoLoginAttempted = false;

  AuthProvider({required this.sharedPreferences});

  Future<bool> login(String url, String db, String email, String password) async {
    try {
      final service = OdooService(serverUrl: url, dbName: db);
      await service.authenticate(email, password);

      if (service.isUserLoggedIn) {
        _odooService = service;
        await _saveSession();
        notifyListeners();
        _authChangeController.add(true);
        return true;
      } else {
        _odooService = null;
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during login: $e');
      }
      rethrow;
    }
  }

  Future<void> _saveSession() async {
    if (_odooService == null) return;
    final service = _odooService!;
    await sharedPreferences.setString('odoo_url', service.url);
    await sharedPreferences.setString('odoo_db', service.dbName);
    await sharedPreferences.setString('odoo_session_id', service.sessionId!);
    await sharedPreferences.setInt('odoo_uid', service.uid!);
    await sharedPreferences.setString('odoo_user_name', service.userName!);
    await sharedPreferences.setString('odoo_user_login', service.userLogin!);
  }

  Future<void> logout() async {
    _odooService?.dispose();
    _odooService = null;
    
    await sharedPreferences.clear();
    
    notifyListeners();
    _authChangeController.add(false);
  }

  Future<void> tryAutoLogin() async {
    if (_autoLoginAttempted) return;
    _autoLoginAttempted = true;

    final url = sharedPreferences.getString('odoo_url');
    final db = sharedPreferences.getString('odoo_db');
    final sessionId = sharedPreferences.getString('odoo_session_id');
    final uid = sharedPreferences.getInt('odoo_uid');
    final userName = sharedPreferences.getString('odoo_user_name');
    final userLogin = sharedPreferences.getString('odoo_user_login');

    if (url != null && db != null && sessionId != null && uid != null && userName != null && userLogin != null) {
      try {
        final service = OdooService(serverUrl: url, dbName: db);
        service.restoreSession(sessionId, uid, userName, userLogin);

        _odooService = service;
        notifyListeners();
        _authChangeController.add(true);
      } catch (e) {
        await logout();
      }
    }
  }

  @override
  void dispose() {
    _authChangeController.close();
    _odooService?.dispose();
    super.dispose();
  }
}

--------------------------------
### FILE: lib/providers/clientes_provider.dart
--------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/data/clientes_repository.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/providers/auth_provider.dart';

class ClientesProvider with ChangeNotifier {
  late ClientesRepository _repository;
  final AuthProvider _authProvider;

  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _error;
  String? _syncMessage;

  StreamSubscription? _clientesSubscription;
  StreamSubscription? _progressSubscription;
  StreamSubscription? _authSubscription;

  ClientesProvider({
    required ClientesRepository repository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _authProvider = authProvider {
    _authSubscription = _authProvider.onAuthChanged.listen((isLoggedIn) {
      if (isLoggedIn) {
        _initialize();
      } else {
        _clearData();
      }
    });
    if (_authProvider.isLoggedIn) {
      _initialize();
    }
  }

  void _initialize() {
    _listenToClientesStream();
    _listenToProgressStream();
    syncClientes();
  }

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get syncMessage => _syncMessage;

  void updateDependencies(ClientesRepository newRepository, AuthProvider newAuthProvider) {
    if (_repository != newRepository) {
      _repository.dispose();
      _repository = newRepository;
      
      if (newAuthProvider.isLoggedIn) {
        _initialize();
      }
    }
  }

  void _listenToClientesStream() {
    _clientesSubscription?.cancel();
    _clientesSubscription = _repository.watchClientes().listen((clientes) {
      _clientes = clientes;
      if (!_isLoading) {
        notifyListeners();
      }
    }, onError: (e) {
      _error = 'Error al leer la base de datos: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToProgressStream() {
    _progressSubscription?.cancel();
    _progressSubscription = _repository.progressStream.listen((message) {
      _syncMessage = message;
      final isFinalMessage = message.startsWith('✅') || message.startsWith('❌') || message.startsWith('👍');
      if (isFinalMessage) {
        _isLoading = false;
        if (message.startsWith('❌')) {
          _error = message;
        }
      } else {
        _isLoading = true;
        _error = null;
      }
      notifyListeners();
    });
  }

  Future<void> syncClientes() async {
    if (_isLoading || !_authProvider.isLoggedIn) return;
    await _repository.syncClientes();
  }

  Future<void> createCliente(String name, String email, String phone, String city) async {
    try {
      await _repository.createCliente(name, email, phone, city);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCliente(Cliente cliente) async {
    try {
      await _repository.updateCliente(cliente);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCliente(Cliente cliente) async {
    try {
      await _repository.deleteCliente(cliente);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _clearData() {
    _clientesSubscription?.cancel();
    _progressSubscription?.cancel();
    _clientes = [];
    _isLoading = false;
    _error = null;
    _syncMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clientesSubscription?.cancel();
    _progressSubscription?.cancel();
    _authSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}

--------------------------------
### FILE: lib/providers/navigation_provider.dart
--------------------------------

import 'package:flutter/material.dart';

// Enum para representar las páginas principales de la aplicación
enum AppPage {
  clientes,
  perfil,
}

class NavigationProvider with ChangeNotifier {
  AppPage _currentPage = AppPage.clientes; // Página inicial
  VoidCallback? _fabAction;
  String _searchQuery = '';
  bool _isSearchActive = false; // <-- NUEVO: Estado para la búsqueda

  // Getters públicos
  AppPage get currentPage => _currentPage;
  VoidCallback? get fabAction => _fabAction;
  String get searchQuery => _searchQuery;
  bool get isSearchActive => _isSearchActive; // <-- NUEVO: Getter para el estado

  // Cambia la página actual
  void changePage(AppPage page) {
    if (_currentPage == page) return; 

    _currentPage = page;
    _fabAction = null; 
    _searchQuery = ''; 
    _isSearchActive = false; // <-- NUEVO: Reseteamos la búsqueda al cambiar de página
    notifyListeners();
  }

  // --- MÉTODOS PARA LA BÚSQUEDA ---

  // Inicia el modo de búsqueda
  void startSearch() {
    if (_isSearchActive) return;
    _isSearchActive = true;
    notifyListeners();
  }

  // Detiene el modo de búsqueda y limpia la consulta
  void stopSearch() {
    if (!_isSearchActive) return;
    _isSearchActive = false;
    _searchQuery = '';
    notifyListeners();
  }

  // Actualiza el texto de la búsqueda
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // --- MÉTODOS PARA EL FAB ---

  void registerFabAction(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabAction = action;
      notifyListeners();
    });
  }

  void unregisterFabAction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabAction = null;
      notifyListeners();
    });
  }
}

--------------------------------
### FILE: lib/providers/theme_provider.dart
--------------------------------

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferences sharedPreferences;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider({required this.sharedPreferences}) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadTheme() {
    final themeIndex = sharedPreferences.getInt('theme_mode');
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    
    await sharedPreferences.setInt('theme_mode', _themeMode.index);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await sharedPreferences.setInt('theme_mode', _themeMode.index);
    notifyListeners();
  }
}

--------------------------------
### FILE: lib/theme/app_theme.dart
--------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primarySeedColor = Colors.redAccent;

  static final TextTheme _appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

  static final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: _appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFF27E5F),
        onPrimary: Colors.white,
        surface: Color(0xFF1C1C1C),
        onSurface: Color(0xFFE8E8E8),
      ),
      
      // Para los inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1C1C),
        border: InputBorder.none,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0x80F27E5F), // Corrected: withOpacity removed
            width: 2,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFF27E5F),
            width: 2,
          ),
        ),
      ),
    );
}

--------------------------------
### FILE: lib/widgets/app_drawer.dart
--------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Leemos los providers una sola vez al inicio del build
    final authProvider = context.watch<AuthProvider>();
    final navigationProvider = context.read<NavigationProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                UserAccountsDrawerHeader(
                  accountName: Text(
                    authProvider.userName ?? 'Usuario',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    )
                  ),
                  accountEmail: Text(
                    authProvider.userLogin ?? 'email@example.com',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    )
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: theme.colorScheme.onPrimary,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                  ),
                ),
                
                _buildDrawerItem(
                  context: context,
                  icon: Icons.people,
                  title: 'Clientes',
                  page: AppPage.clientes,
                  isSelected: navigationProvider.currentPage == AppPage.clientes,
                ),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_circle,
                  title: 'Mi Perfil',
                  page: AppPage.perfil,
                  isSelected: navigationProvider.currentPage == AppPage.perfil,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            title: const Text('Cambiar Tema'),
            onTap: () {
              themeProvider.toggleTheme();
            },
          ),
          const SizedBox(height: 10)
        ],
      ),
    );
  }

  // Widget helper para crear los elementos del menú
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required AppPage page,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        context.read<NavigationProvider>().changePage(page);
        Navigator.pop(context); // Cierra el drawer
      },
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withAlpha(26),
    );
  }
}

--------------------------------
### FILE: lib/widgets/cliente_list_item.dart
--------------------------------

import 'package:flutter/material.dart';
import '../data/local/app_database.dart';

class ClienteListItem extends StatelessWidget {
  final Cliente cliente;

  const ClienteListItem({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            cliente.name.isNotEmpty ? cliente.name[0].toUpperCase() : '?',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(cliente.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cliente.email?.isNotEmpty ?? false)
              Text(cliente.email!),

            if (cliente.phone?.isNotEmpty ?? false)
              Text(cliente.phone!),

            if (cliente.city?.isNotEmpty ?? false)
              Text(cliente.city!),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(context, '/cliente_detalle', arguments: cliente.id);
        },
      ),
    );
  }
}

--------------------------------
### FILE: lib/widgets/main_scaffold.dart
--------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/pages/cliente_edit_page.dart';
import '../providers/navigation_provider.dart';
import '../pages/clientes_page.dart';
import '../pages/profile_page.dart';
import 'app_drawer.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCurrentPageTitle(AppPage page) {
    switch (page) {
      case AppPage.clientes:
        return 'Clientes';
      case AppPage.perfil:
        return 'Mi Perfil';
    }
  }

  Widget _buildCurrentPage(AppPage page) {
    switch (page) {
      case AppPage.clientes:
        return const ClientesPage();
      case AppPage.perfil:
        return const ProfilePage();
    }
  }

  AppBar _buildDefaultAppBar(BuildContext context, NavigationProvider provider) {
    return AppBar(
      title: Text(_getCurrentPageTitle(provider.currentPage)),
      actions: [
        if (provider.currentPage == AppPage.clientes)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => provider.startSearch(),
          ),
      ],
    );
  }

  AppBar _buildSearchAppBar(BuildContext context, NavigationProvider provider) {
    if (provider.searchQuery.isEmpty) {
      _searchController.clear();
    }

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          provider.stopSearch();
          _searchController.clear();
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Buscar...',
          border: InputBorder.none,
        ),
        onChanged: (query) => provider.updateSearchQuery(query),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            provider.updateSearchQuery('');
            _searchController.clear();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        final currentPage = navigationProvider.currentPage;
        final isSearching = navigationProvider.isSearchActive;

        return Scaffold(
          appBar: isSearching && currentPage == AppPage.clientes
              ? _buildSearchAppBar(context, navigationProvider)
              : _buildDefaultAppBar(context, navigationProvider),
          drawer: const AppDrawer(),
          body: _buildCurrentPage(currentPage),
          floatingActionButton: (currentPage == AppPage.clientes && !isSearching)
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const ClienteEditPage()),
                    );
                  },
                  tooltip: 'Nuevo Cliente',
                  child: const Icon(Icons.person_add_alt_1_rounded),
                )
              : null,
        );
      },
    );
  }
}
