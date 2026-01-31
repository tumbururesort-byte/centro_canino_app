
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote/odoo_service.dart';
import 'local/app_database.dart';
import 'local/dao/clientes_dao.dart';
import 'dart:developer' as developer;

class ClientesRepository {
  final OdooService odooService;
  final ClientesDao clientesDao;
  final SharedPreferences sharedPreferences;

  // La clave ahora es pÃºblica para ser accesible en los tests
  static const String lastSyncTimestampKey = 'last_sync_timestamp';

  // Inyectamos SharedPreferences para facilitar las pruebas
  ClientesRepository({
    required this.odooService,
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
    // Usamos la instancia inyectada
    final prefs = sharedPreferences;
    DateTime? lastSync;

    final lastSyncString = prefs.getString(lastSyncTimestampKey);
    if (lastSyncString != null) {
      lastSync = DateTime.parse(lastSyncString);
      developer.log('🕒 Última sincronización: $lastSyncString', name: 'ClientesRepository');
    } else {
      developer.log('🕒 Primera sincronización.', name: 'ClientesRepository');
    }

    try {
      final syncTime = DateTime.now();
      final clientesFromOdoo = await odooService.fetchClientes(lastSync: lastSync);

      if (clientesFromOdoo.isNotEmpty) {
        developer.log('💾 Guardando ${clientesFromOdoo.length} clientes...', name: 'ClientesRepository');
        
        final clientesToSave = clientesFromOdoo.map((clienteData) {
          return ClientesCompanion(
            odooId: Value(clienteData['id'] as int),
            name: Value(_sanitizeString(clienteData['name'], defaultValue: 'Nombre no disponible')),
            email: Value(_sanitizeString(clienteData['email'])),
            phone: Value(_sanitizeString(clienteData['phone'])),
            city: Value(_sanitizeString(clienteData['city'])),
            pendingSync: const Value(false),
          );
        });

        // El mÃ©todo correcto es `insertOrUpdateAll`
        await clientesDao.insertOrUpdateAll(clientesToSave.toList());
        developer.log('✅ Clientes guardados.', name: 'ClientesRepository');
      } else {
        developer.log('👍 No hay clientes nuevos.', name: 'ClientesRepository');
      }
      
      await prefs.setString(lastSyncTimestampKey, syncTime.toIso8601String());
      developer.log('✅ Sincronización finalizada. Nueva marca de tiempo: ${syncTime.toIso8601String()}', name: 'ClientesRepository');

    } catch (e) {
      developer.log('❌ Error durante la sincronización: $e', name: 'ClientesRepository');
      rethrow;
    }
  }

  Future<void> createCliente(String name, String email, String phone, String city) async {
    final clienteData = {'name': name, 'email': email, 'phone': phone, 'city': city, 'customer_rank': 1};
    try {
      final newOdooId = await odooService.createCliente(clienteData);
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
    final clienteData = {'name': cliente.name, 'email': cliente.email, 'phone': cliente.phone, 'city': cliente.city};
    try {
      await odooService.updateCliente(cliente.odooId!, clienteData);
      await clientesDao.updateCliente(cliente);
    } catch (e) {
      developer.log('❌ Error al actualizar el cliente: $e', name: 'ClientesRepository');
      rethrow;
    }
  }

  Future<void> deleteCliente(Cliente cliente) async {
    try {
      await odooService.deleteCliente(cliente.odooId!);
      await clientesDao.deleteCliente(cliente);
    } catch (e) {
      developer.log('❌ Error al eliminar el cliente: $e', name: 'ClientesRepository');
      rethrow;
    }
  }
}
