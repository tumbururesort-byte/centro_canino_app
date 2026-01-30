import 'local/app_database.dart';
import 'remote/odoo_service.dart';
import 'package:drift/drift.dart';
import 'dart:developer' as developer;

class ClientesRepository {
  final AppDatabase db;
  final OdooService remote;

  ClientesRepository(this.db, this.remote);

  // Obtener clientes offline
  Future<List<Cliente>> getClientesOffline() async {
    developer.log('📱 Obteniendo clientes de BD local...', name: 'Repository');
    final clientes = await db.getClientes();
    developer.log('📱 Clientes locales: ${clientes.length}', name: 'Repository');
    
    if (clientes.isNotEmpty) {
      developer.log('📋 Ejemplos de clientes locales:', name: 'Repository');
      for (var i = 0; i < (clientes.length > 3 ? 3 : clientes.length); i++) {
        developer.log('  - ${clientes[i].name} (ID: ${clientes[i].id}, Odoo ID: ${clientes[i].odooId})', name: 'Repository');
      }
    }
    
    return clientes;
  }

  // Sincronización completa
  Future<void> syncClientes({
    required String url,
    required String dbName,
    required int userId,
    required String sessionId,
  }) async {
    developer.log('🔄 Iniciando sincronización completa...', name: 'Repository');
    
    // 1. Push: enviar cambios locales
    developer.log('⬆️ PASO 1: Push de cambios locales', name: 'Repository');
    await _pushLocalChanges(url: url, dbName: dbName, userId: userId, sessionId: sessionId);

    // 2. Pull: obtener datos remotos
    developer.log('⬇️ PASO 2: Pull de datos remotos', name: 'Repository');
    final remoteClientes = await remote.fetchClientes(
      url: url,
      db: dbName,
      userId: userId,
      sessionId: sessionId,
    );
    
    developer.log('📥 Clientes recibidos de Odoo: ${remoteClientes.length}', name: 'Repository');

    // 3. Actualizar BD local
    developer.log('💾 PASO 3: Actualizando BD local con datos remotos', name: 'Repository');
    await db.syncFromRemote(remoteClientes);
    
    // 4. Verificar que se guardaron
    final savedClientes = await db.getClientes();
    developer.log('✅ Clientes guardados en BD local: ${savedClientes.length}', name: 'Repository');
    
    developer.log('🎉 Sincronización completa finalizada', name: 'Repository');
  }

  Future<void> _pushLocalChanges({
    required String url,
    required String dbName,
    required int userId,
    required String sessionId,
  }) async {
    final pending = await db.getPendingSync();
    developer.log('⏳ Clientes pendientes de sincronizar: ${pending.length}', name: 'Repository');

    for (final cliente in pending) {
      try {
        if (cliente.isDeleted && cliente.odooId != null) {
          developer.log('🗑️ Eliminando cliente remoto: ${cliente.name} (Odoo ID: ${cliente.odooId})', name: 'Repository');
          
          await remote.deleteCliente(
            url: url,
            db: dbName,
            userId: userId,
            sessionId: sessionId,
            odooId: cliente.odooId!,
          );
          await db.deleteCliente(cliente.id);
          
          developer.log('✅ Cliente eliminado localmente', name: 'Repository');
          
        } else if (cliente.odooId == null) {
          developer.log('➕ Creando cliente remoto: ${cliente.name}', name: 'Repository');
          
          final newOdooId = await remote.createCliente(
            url: url,
            db: dbName,
            userId: userId,
            sessionId: sessionId,
            data: {
              'name': cliente.name,
              'email': cliente.email,
              'phone': cliente.phone,
              'city': cliente.city,
            },
          );
          
          developer.log('✅ Cliente creado con Odoo ID: $newOdooId', name: 'Repository');
          
          await db.upsertCliente(ClientesCompanion(
            id: Value(cliente.id),
            odooId: Value(newOdooId),
            pendingSync: const Value(false),
            lastSync: Value(DateTime.now()),
          ));
          
        } else {
          developer.log('✏️ Actualizando cliente remoto: ${cliente.name} (Odoo ID: ${cliente.odooId})', name: 'Repository');
          
          await remote.updateCliente(
            url: url,
            db: dbName,
            userId: userId,
            sessionId: sessionId,
            odooId: cliente.odooId!,
            data: {
              'name': cliente.name,
              'email': cliente.email,
              'phone': cliente.phone,
              'city': cliente.city,
            },
          );
          
          developer.log('✅ Cliente actualizado', name: 'Repository');
          
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

  // CRUD local
  Future<void> createCliente(String name, {String? email, String? phone, String? city}) async {
    developer.log('➕ Creando cliente local: $name', name: 'Repository');
    
    await db.upsertCliente(ClientesCompanion.insert(
      name: name,
      email: Value(email),
      phone: Value(phone),
      city: Value(city),
      pendingSync: const Value(true),
    ));
    
    developer.log('✅ Cliente creado localmente (pendiente de sync)', name: 'Repository');
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
    
    developer.log('✅ Cliente actualizado localmente (pendiente de sync)', name: 'Repository');
  }

  Future<void> deleteCliente(Cliente cliente) async {
    developer.log('🗑️ Eliminando cliente: ${cliente.name}', name: 'Repository');
    
    if (cliente.odooId != null) {
      developer.log('  Marcando para eliminación remota (Odoo ID: ${cliente.odooId})', name: 'Repository');
      await db.markForDeletion(cliente.id);
    } else {
      developer.log('  Eliminación local directa (sin Odoo ID)', name: 'Repository');
      await db.deleteCliente(cliente.id);
    }
    
    developer.log('✅ Cliente eliminado', name: 'Repository');
  }
}