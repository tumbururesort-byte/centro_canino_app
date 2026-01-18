import 'package:drift/drift.dart';
import 'connection/mobile.dart';
import 'clientes_table.dart';
import 'dart:developer' as developer;

part 'app_database.g.dart';

@DriftDatabase(tables: [Clientes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  // Obtener todos los clientes no borrados
  Future<List<Cliente>> getClientes() async {
    developer.log('📊 Consultando clientes en BD local...', name: 'AppDatabase');
    
    final result = await (select(clientes)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
        .get();
    
    developer.log('📊 Encontrados ${result.length} clientes no eliminados', name: 'AppDatabase');
    return result;
  }

  // Obtener clientes pendientes de sincronización
  Future<List<Cliente>> getPendingSync() async {
    developer.log('⏳ Consultando clientes pendientes de sync...', name: 'AppDatabase');
    
    final result = await (select(clientes)
          ..where((c) => c.pendingSync.equals(true)))
        .get();
    
    developer.log('⏳ Encontrados ${result.length} clientes pendientes', name: 'AppDatabase');
    return result;
  }

  // Insertar o actualizar cliente
  Future<int> upsertCliente(ClientesCompanion companion) async {
    developer.log('💾 Upsert cliente: ${companion.name.value}', name: 'AppDatabase');
    
    final result = await into(clientes).insertOnConflictUpdate(companion);
    
    developer.log('✅ Cliente guardado con ID: $result', name: 'AppDatabase');
    return result;
  }

  // Buscar por odooId
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

  // Actualizar múltiples desde remoto
  Future<void> syncFromRemote(List<Map<String, dynamic>> remoteData) async {
    developer.log('🔄 Sincronizando ${remoteData.length} clientes desde remoto...', name: 'AppDatabase');
    
    await batch((batch) {
      for (final data in remoteData) {
        final odooId = data['id'] as int?;
        if (odooId == null) {
          developer.log('⚠️ Cliente sin ID, ignorando', name: 'AppDatabase');
          continue;
        }

        developer.log('  💾 Procesando: ${data['name']} (Odoo ID: $odooId)', name: 'AppDatabase');

        batch.insert(
          clientes,
          ClientesCompanion.insert(
            odooId: Value(odooId),
            name: data['name'] ?? '',
            email: Value(data['email']),
            phone: Value(data['phone']),
            city: Value(data['city']),
            lastSync: Value(DateTime.now()),
            pendingSync: const Value(false),
          ),
          onConflict: DoUpdate((old) {
            return ClientesCompanion.custom(
              name: Variable(data['name'] ?? ''),
              email: Variable(data['email']),
              phone: Variable(data['phone']),
              city: Variable(data['city']),
              lastSync: Variable(DateTime.now()),
              updatedAt: Variable(DateTime.now()),
            );
          }, target: [clientes.odooId]),
        );
      }
    });
    
    developer.log('✅ Batch completado', name: 'AppDatabase');
  }

  // Marcar cliente para eliminación
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

  // Eliminar permanentemente
  Future<void> deleteCliente(int id) async {
    developer.log('🗑️ Eliminando permanentemente cliente ID $id', name: 'AppDatabase');
    
    await (delete(clientes)..where((c) => c.id.equals(id))).go();
    
    developer.log('✅ Cliente eliminado permanentemente', name: 'AppDatabase');
  }
}