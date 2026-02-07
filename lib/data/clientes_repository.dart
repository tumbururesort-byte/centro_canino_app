import 'dart:async';
import 'package:drift/drift.dart';
import 'package:myapp/data/local/dao/tarifas_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote/odoo_service.dart';
import 'local/app_database.dart';
import 'local/dao/clientes_dao.dart';
import 'dart:developer' as developer;

class ClientesRepository {
  final OdooService? odooService;
  final ClientesDao clientesDao;
  final TarifasDao tarifasDao;
  final SharedPreferences sharedPreferences;

  var _progressStreamController = StreamController<String>.broadcast();
  Stream<String> get progressStream => _progressStreamController.stream;

  static const String lastSyncTimestampKey = 'last_sync_timestamp';

  ClientesRepository({
    this.odooService,
    required this.clientesDao,
    required this.tarifasDao, 
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

  Stream<List<Tarifa>> watchTarifas() {
    return tarifasDao.watchAllTarifas();
  }

  Future<void> syncTarifas() async {
    if (odooService == null || !odooService!.isUserLoggedIn) return;
    try {
      _progressStreamController.add('Actualizando lista de tarifas...');
      final tarifasFromOdoo = await odooService!.fetchTarifas();
      if (tarifasFromOdoo.isNotEmpty) {
        final tarifasToSave = tarifasFromOdoo.map((data) => TarifasCompanion(
          odooId: Value(data['id'] as int),
          name: Value(_sanitizeString(data['name'])),
        )).toList();
        await tarifasDao.insertOrUpdateAll(tarifasToSave);
        _progressStreamController.add('Lista de tarifas actualizada.');
      }
    } catch (e) {
      developer.log('Error sincronizando tarifas: $e', name: 'ClientesRepository');
       _progressStreamController.add('❌ Error actualizando tarifas.');
    }
  }

  Future<void> syncClientes() async {
    if (_progressStreamController.isClosed) {
      _progressStreamController = StreamController<String>.broadcast();
    }

    if (odooService == null || !odooService!.isUserLoggedIn) {
      _progressStreamController.add("Sincronización pausada. Inicia sesión para continuar.");
      return;
    }

    developer.log('🚀 Iniciando proceso de sincronización...', name: 'ClientesRepository');
    _progressStreamController.add('Iniciando sincronización...');

    try {
      await _syncPendientes();

      final lastSync = _getLastSyncDate();
      final totalToSync = await odooService!.countClientes(lastSync: lastSync);
      
      if (totalToSync == 0) {
         _progressStreamController.add('👍 ¡Todo está al día!');
        await _saveLastSyncDate();
        return;
      }

      _progressStreamController.add('$totalToSync clientes para descargar.');

      const chunkSize = 50;
      for (int offset = 0; offset < totalToSync; offset += chunkSize) {
        final message = 'Descargando... ${offset + 1} - ${offset + chunkSize > totalToSync ? totalToSync : offset + chunkSize} de $totalToSync';
        _progressStreamController.add(message);

        final clientesFromOdoo = await odooService!.fetchClientesChunk(lastSync: lastSync, limit: chunkSize, offset: offset);
        if (clientesFromOdoo.isNotEmpty) {
          final clientesToSave = clientesFromOdoo.map((data) => _clienteFromOdooData(data)).toList();
          await clientesDao.insertOrUpdateAll(clientesToSave);
        }
      }
      
      await _saveLastSyncDate();
      _progressStreamController.add('✅ Sincronización completada.');

    } catch (e, s) {
      final errorMessage = '❌ Error durante la sincronización: $e';
      _progressStreamController.add(errorMessage);
      developer.log(errorMessage, stackTrace: s, name: 'ClientesRepository');
    }
  }

  Future<void> _syncPendientes() async {
    final pendientes = await clientesDao.getClientesPendientes();
    if (pendientes.isEmpty) return;

    _progressStreamController.add('Enviando ${pendientes.length} cambios locales...');
    
    for (final cliente in pendientes) {
      try {
        if (cliente.isDeleted) {
          if (cliente.odooId != null) {
            await odooService!.deleteCliente(cliente.odooId!);
          }
          await clientesDao.deleteCliente(cliente);
        } else if (cliente.odooId == null) {
          final newId = await odooService!.createCliente(_clienteToOdooData(cliente));
          final updatedCliente = cliente.copyWith(odooId: Value(newId), pendingSync: false);
          await clientesDao.updateCliente(updatedCliente);
        } else {
          await odooService!.updateCliente(cliente.odooId!, _clienteToOdooData(cliente));
          final updatedCliente = cliente.copyWith(pendingSync: false);
          await clientesDao.updateCliente(updatedCliente);
        }
      } catch (e) {
        developer.log('Error sincronizando cliente ${cliente.id}: $e', name: 'ClientesRepository');
      }
    }
    _progressStreamController.add('Cambios locales enviados.');
  }

  Future<void> createCliente(String name, String email, String phone, String city, int? tarifaId) async {
    final cliente = ClientesCompanion(
      name: Value(name),
      email: Value(email),
      phone: Value(phone),
      city: Value(city),
      tarifaId: Value(tarifaId),
      pendingSync: const Value(true),
    );
    await clientesDao.insertCliente(cliente);
    syncClientes();
  }

  Future<void> updateCliente(Cliente cliente) async {
    final updatedCliente = cliente.copyWith(pendingSync: true);
    await clientesDao.updateCliente(updatedCliente);
    syncClientes();
  }

  Future<void> deleteCliente(Cliente cliente) async {
    final updatedCliente = cliente.copyWith(pendingSync: true, isDeleted: true);
    await clientesDao.updateCliente(updatedCliente);
    syncClientes(); 
  }

  DateTime? _getLastSyncDate() {
    final lastSyncString = sharedPreferences.getString(lastSyncTimestampKey);
    return lastSyncString != null ? DateTime.parse(lastSyncString) : null;
  }

  Future<void> _saveLastSyncDate() async {
    await sharedPreferences.setString(lastSyncTimestampKey, DateTime.now().toIso8601String());
  }

  ClientesCompanion _clienteFromOdooData(Map<String, dynamic> data) {
    final mobile = _sanitizeString(data['mobile']);
    final phone = _sanitizeString(data['phone']);
    final pricelist = data['property_product_pricelist'];
    final int? tarifaOdooId = (pricelist is List && pricelist.isNotEmpty) ? pricelist[0] as int : null;

    return ClientesCompanion(
      odooId: Value(data['id'] as int),
      name: Value(_sanitizeString(data['name'], defaultValue: 'Nombre no disponible')),
      email: Value(_sanitizeString(data['email'])),
      phone: Value(mobile.isNotEmpty ? mobile : phone),
      city: Value(_sanitizeString(data['city'])),
      tarifaId: Value(tarifaOdooId),
      pendingSync: const Value(false),
    );
  }

  Map<String, dynamic> _clienteToOdooData(Cliente cliente) {
    return {
      'name': cliente.name,
      'email': cliente.email?.isNotEmpty == true ? cliente.email : false,
      'mobile': cliente.phone?.isNotEmpty == true ? cliente.phone : false,
      'city': cliente.city?.isNotEmpty == true ? cliente.city : false,
      'property_product_pricelist': cliente.tarifaId ?? false,
      'customer_rank': 1,
    };
  }

  void dispose() {
    if (!_progressStreamController.isClosed) {
      _progressStreamController.close();
    }
  }
}
