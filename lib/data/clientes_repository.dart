
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

  final _progressStreamController = StreamController<String>.broadcast();
  Stream<String> get progressStream => _progressStreamController.stream;

  static const String lastSyncTimestampKey = 'last_sync_timestamp';

  ClientesRepository({
    this.odooService, // OdooService ahora puede ser nulo
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
            return ClientesCompanion(
              odooId: Value(clienteData['id'] as int),
              name: Value(_sanitizeString(clienteData['name'], defaultValue: 'Nombre no disponible')),
              email: Value(_sanitizeString(clienteData['email'])),
              phone: Value(_sanitizeString(clienteData['phone'])),
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
    _progressStreamController.close();
  }

  Future<void> createCliente(String name, String email, String phone, String city) async {
    if (odooService == null) throw Exception("Servicio Odoo no disponible");
    final clienteData = {'name': name, 'email': email, 'phone': phone, 'city': city, 'customer_rank': 1};
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
    final clienteData = {'name': cliente.name, 'email': cliente.email, 'phone': cliente.phone, 'city': cliente.city};
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
