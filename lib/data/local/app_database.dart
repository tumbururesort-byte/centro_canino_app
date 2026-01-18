import 'package:drift/drift.dart';
import 'connection/unsupported.dart' 
  if (dart.library.html) 'connection/web.dart' 
  if (dart.library.io) 'connection/mobile.dart';
import 'clientes_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Clientes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  // Obtener todos los clientes no borrados
  Future<List<Cliente>> getClientes() {
    return (select(clientes)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
        .get();
  }

  // Obtener clientes pendientes de sincronización
  Future<List<Cliente>> getPendingSync() {
    return (select(clientes)..where((c) => c.pendingSync.equals(true))).get();
  }

  // Insertar o actualizar cliente
  Future<int> upsertCliente(ClientesCompanion companion) {
    return into(clientes).insertOnConflictUpdate(companion);
  }

  // Buscar por odooId
  Future<Cliente?> findByOdooId(int odooId) {
    return (select(clientes)..where((c) => c.odooId.equals(odooId)))
        .getSingleOrNull();
  }

  // Actualizar múltiples desde remoto
  Future<void> syncFromRemote(List<Map<String, dynamic>> remoteData) async {
    await batch((batch) {
      for (final data in remoteData) {
        final odooId = data['id'] as int?;
        if (odooId == null) continue;

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
            // Solo actualizar si no hay cambios pendientes locales
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
  }

  // Marcar cliente para eliminación
  Future<void> markForDeletion(int id) {
    return (update(clientes)..where((c) => c.id.equals(id))).write(
      const ClientesCompanion(
        isDeleted: Value(true),
        pendingSync: Value(true),
      ),
    );
  }

  // Eliminar permanentemente
  Future<void> deleteCliente(int id) {
    return (delete(clientes)..where((c) => c.id.equals(id))).go();
  }
}
