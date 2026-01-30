import 'local/app_database.dart';
import 'remote/odoo_service.dart';
import 'package:drift/drift.dart';
import 'dart:developer' as developer;

class ClientesRepository {
  final AppDatabase db;

  // OdooService ya no se pasa en el constructor.
  ClientesRepository(this.db);

  Future<List<Cliente>> getClientesOffline() async {
    developer.log('📱 Obteniendo clientes de BD local...', name: 'Repository');
    final clientes = await db.getClientes();
    developer.log('📱 Clientes locales: ${clientes.length}', name: 'Repository');
    return clientes;
  }

  // AHORA RECIBE EL SERVICIO AUTENTICADO
  Future<void> syncClientes({required OdooService remote}) async {
    developer.log('🔄 Iniciando sincronización completa...', name: 'Repository');
    
    // 1. Push: enviar cambios locales
    developer.log('⬆️ PASO 1: Push de cambios locales', name: 'Repository');
    await _pushLocalChanges(remote: remote);

    // 2. Pull: obtener datos remotos
    developer.log('⬇️ PASO 2: Pull de datos remotos', name: 'Repository');
    final remoteClientes = await remote.fetchClientes(); // SIN PARÁMETROS
    
    developer.log('📥 Clientes recibidos de Odoo: ${remoteClientes.length}', name: 'Repository');

    // 3. Actualizar BD local
    developer.log('💾 PASO 3: Actualizando BD local con datos remotos', name: 'Repository');
    await db.syncFromRemote(remoteClientes);
    
    developer.log('🎉 Sincronización completa finalizada', name: 'Repository');
  }

  Future<void> _pushLocalChanges({required OdooService remote}) async {
    final pending = await db.getPendingSync();
    developer.log('⏳ Clientes pendientes de sincronizar: ${pending.length}', name: 'Repository');

    for (final cliente in pending) {
      try {
        if (cliente.isDeleted && cliente.odooId != null) {
          developer.log('🗑️ Eliminando cliente remoto: ${cliente.name} (Odoo ID: ${cliente.odooId})', name: 'Repository');
          await remote.deleteCliente(cliente.odooId!); // SIN PARÁMETROS EXTRA
          await db.deleteCliente(cliente.id);
          
        } else if (cliente.odooId == null) {
          developer.log('➕ Creando cliente remoto: ${cliente.name}', name: 'Repository');
          final newOdooId = await remote.createCliente({ // SIN PARÁMETROS EXTRA
            'name': cliente.name,
            'email': cliente.email,
            'phone': cliente.phone,
            'city': cliente.city,
          });
          
          await db.upsertCliente(ClientesCompanion(
            id: Value(cliente.id),
            odooId: Value(newOdooId),
            pendingSync: const Value(false),
            lastSync: Value(DateTime.now()),
          ));
          
        } else {
          developer.log('✏️ Actualizando cliente remoto: ${cliente.name} (Odoo ID: ${cliente.odooId})', name: 'Repository');
          await remote.updateCliente(cliente.odooId!, { // SIN PARÁMETROS EXTRA
            'name': cliente.name,
            'email': cliente.email,
            'phone': cliente.phone,
            'city': cliente.city,
          });
          
          await db.upsertCliente(ClientesCompanion(
            id: Value(cliente.id),
            pendingSync: const Value(false),
            lastSync: Value(DateTime.now()),
          ));
        }
      } catch (e) {
        developer.log('❌ Error procesando cliente ${cliente.name}: $e', name: 'Repository');
      }
    }
  }

  // --- Métodos CRUD locales sin cambios ---
  Future<void> createCliente(String name, {String? email, String? phone, String? city}) async {
    developer.log('➕ Creando cliente local: $name', name: 'Repository');
    await db.upsertCliente(ClientesCompanion.insert(
      name: name,
      email: Value(email),
      phone: Value(phone),
      city: Value(city),
      pendingSync: const Value(true),
    ));
  }

  Future<void> updateCliente(int id, {required String name, String? email, String? phone, String? city}) async {
    developer.log('✏️ Actualizando cliente local ID: $id', name: 'Repository');
    await db.upsertCliente(ClientesCompanion(
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
    developer.log('🗑️ Eliminando cliente: ${cliente.name}', name: 'Repository');
    if (cliente.odooId != null) {
      await db.markForDeletion(cliente.id);
    } else {
      await db.deleteCliente(cliente.id);
    }
  }
}
