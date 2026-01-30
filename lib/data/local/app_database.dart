
import 'package:drift/drift.dart';
import 'connection/mobile.dart';
import 'clientes_table.dart';
import 'dart:developer' as developer;

part 'app_database.g.dart';

@DriftDatabase(tables: [Clientes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        developer.log('‼️ Ejecutando migración de BD desde v$from a v$to. Borrando todas las tablas.', name: 'AppDatabase');
        final tables = allTables.toList();
        for (final table in tables) {
          await m.deleteTable(table.actualTableName);
          await m.createTable(table);
        }
      },
    );
  }

  Future<List<Cliente>> getClientes() async {
    developer.log('📊 Consultando clientes en BD local...', name: 'AppDatabase');
    final result = await (select(clientes)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
        .get();
    developer.log('📊 Encontrados ${result.length} clientes no eliminados', name: 'AppDatabase');
    return result;
  }

  Future<List<Cliente>> getPendingSync() async {
    developer.log('⏳ Consultando clientes pendientes de sync...', name: 'AppDatabase');
    final result = await (select(clientes)
          ..where((c) => c.pendingSync.equals(true)))
        .get();
    developer.log('⏳ Encontrados ${result.length} clientes pendientes', name: 'AppDatabase');
    return result;
  }

  Future<int> upsertCliente(ClientesCompanion companion) async {
    developer.log('💾 Upsert cliente: ${companion.name.value}', name: 'AppDatabase');
    final result = await into(clientes).insertOnConflictUpdate(companion);
    developer.log('✅ Cliente guardado con ID: $result', name: 'AppDatabase');
    return result;
  }

  Future<Cliente?> findByOdooId(int odooId) async {
    developer.log('🔍 Buscando cliente con Odoo ID: $odooId', name: 'AppDatabase');
    final result = await (select(clientes)
          ..where((c) => c.odooId.equals(odooId)))
        .getSingleOrNull();
    if (result != null) {
      developer.log('✅ Cliente encontrado: ${result.name}', name: 'AppDatabase');
    } else {
      developer.log('⚠️ Cliente no encontrado', name: 'AppDatabase');
    }
    return result;
  }

  Future<void> syncFromRemote(List<Map<String, dynamic>> remoteData) async {
    developer.log('🔄 Sincronizando ${remoteData.length} clientes desde remoto...', name: 'AppDatabase');

    await batch((batch) {
      for (final data in remoteData) {
        final odooId = data['id'] as int?;
        if (odooId == null) {
          developer.log('⚠️ Cliente sin ID, ignorando', name: 'AppDatabase');
          continue;
        }

        // --- VALIDACIÓN Y LIMPIEZA DE DATOS ---
        final name = data['name'];
        if (name is! String || name.isEmpty) {
          developer.log('⚠️ Cliente con Odoo ID $odooId no tiene nombre válido ($name). Ignorando.', name: 'AppDatabase');
          continue; // Ignorar registros sin un nombre de tipo String válido
        }

        final email = data['email'];
        final phone = data['phone'];
        final city = data['city'];
        
        // Convertir `false` u otros tipos a `null` para campos de texto opcionales
        final safeEmail = email is String ? email : null;
        final safePhone = phone is String ? phone : null;
        final safeCity = city is String ? city : null;
        
        developer.log('  💾 Procesando: "$name" (Odoo ID: $odooId)', name: 'AppDatabase');

        batch.insert(
          clientes,
          ClientesCompanion.insert(
            odooId: Value(odooId),
            name: name,
            email: Value(safeEmail),
            phone: Value(safePhone),
            city: Value(safeCity),
            lastSync: Value(DateTime.now()),
            pendingSync: const Value(false),
          ),
          onConflict: DoUpdate((old) {
            return ClientesCompanion.custom(
              name: Variable(name),
              email: Variable(safeEmail),
              phone: Variable(safePhone),
              city: Variable(safeCity),
              lastSync: Variable(DateTime.now()),
              updatedAt: Variable(DateTime.now()),
            );
          }, target: [clientes.odooId]),
        );
      }
    });

    developer.log('✅ Batch completado', name: 'AppDatabase');
  }

  Future<void> markForDeletion(int id) async {
    developer.log('🗑️ Marcando cliente ID $id para eliminación', name: 'AppDatabase');
    await (update(clientes)..where((c) => c.id.equals(id))).write(
      const ClientesCompanion(
        isDeleted: Value(true),
        pendingSync: Value(true),
      ),
    );
    developer.log('✅ Cliente marcado para eliminación', name: 'AppDatabase');
  }

  Future<void> deleteCliente(int id) async {
    developer.log('🗑️ Eliminando permanentemente cliente ID $id', name: 'AppDatabase');
    await (delete(clientes)..where((c) => c.id.equals(id))).go();
    developer.log('✅ Cliente eliminado permanentemente', name: 'AppDatabase');
  }
}
