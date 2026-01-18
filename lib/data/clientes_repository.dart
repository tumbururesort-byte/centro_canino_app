import 'local/app_database.dart';
import 'remote/odoo_service.dart';
import 'package:drift/drift.dart';

class ClientesRepository {
  final AppDatabase db;
  final OdooService remote;

  ClientesRepository(this.db, this.remote);

  // Obtener clientes offline
  Future<List<Cliente>> getClientesOffline() {
    return db.getClientes();
  }

  // Sincronización completa
  Future<void> syncClientes({
    required String url,
    required String dbName,
    required int userId,
    required String password,
  }) async {
    // 1. Push: enviar cambios locales
    await _pushLocalChanges(url: url, dbName: dbName, userId: userId, password: password);

    // 2. Pull: obtener datos remotos
    final remoteClientes = await remote.fetchClientes(
      url: url,
      db: dbName,
      userId: userId,
      password: password,
    );

    // 3. Actualizar BD local
    await db.syncFromRemote(remoteClientes);
  }

  Future<void> _pushLocalChanges({
    required String url,
    required String dbName,
    required int userId,
    required String password,
  }) async {
    final pending = await db.getPendingSync();

    for (final cliente in pending) {
      try {
        if (cliente.isDeleted && cliente.odooId != null) {
          // Eliminar en remoto
          await remote.deleteCliente(
            url: url,
            db: dbName,
            userId: userId,
            password: password,
            odooId: cliente.odooId!,
          );
          await db.deleteCliente(cliente.id);
        } else if (cliente.odooId == null) {
          // Crear en remoto
          final newOdooId = await remote.createCliente(
            url: url,
            db: dbName,
            userId: userId,
            password: password,
            data: {
              'name': cliente.name,
              'email': cliente.email,
              'phone': cliente.phone,
              'city': cliente.city,
            },
          );
          
          await db.upsertCliente(ClientesCompanion(
            id: Value(cliente.id),
            odooId: Value(newOdooId),
            pendingSync: const Value(false),
            lastSync: Value(DateTime.now()),
          ));
        } else {
          // Actualizar en remoto
          await remote.updateCliente(
            url: url,
            db: dbName,
            userId: userId,
            password: password,
            odooId: cliente.odooId!,
            data: {
              'name': cliente.name,
              'email': cliente.email,
              'phone': cliente.phone,
              'city': cliente.city,
            },
          );
          
          await db.upsertCliente(ClientesCompanion(
            id: Value(cliente.id),
            pendingSync: const Value(false),
            lastSync: Value(DateTime.now()),
          ));
        }
      } catch (e) {
        // Manejar el error de forma más robusta en producción
      }
    }
  }

  // CRUD local
  Future<void> createCliente(String name, {String? email, String? phone, String? city}) {
    return db.upsertCliente(ClientesCompanion.insert(
      name: name,
      email: Value(email),
      phone: Value(phone),
      city: Value(city),
      pendingSync: const Value(true),
    ));
  }

  Future<void> updateCliente(int id, {required String name, String? email, String? phone, String? city}) {
    return db.upsertCliente(ClientesCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      phone: Value(phone),
      city: Value(city),
      pendingSync: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> deleteCliente(Cliente cliente) async {
    if (cliente.odooId != null) {
      await db.markForDeletion(cliente.id);
    } else {
      await db.deleteCliente(cliente.id);
    }
  }
}
