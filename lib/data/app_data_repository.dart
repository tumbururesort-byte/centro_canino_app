import 'dart:async';
import 'package:drift/drift.dart';
import 'package:myapp/data/local/dao/pet_types_dao.dart';
import 'package:myapp/data/local/dao/tarifas_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote/odoo_service.dart';
import 'local/app_database.dart';
import 'local/dao/clientes_dao.dart';
import 'dart:developer' as developer;

class AppDataRepository {
  final OdooService? odooService;
  final ClientesDao clientesDao;
  final TarifasDao tarifasDao;
  final PetTypesDao petTypesDao;
  final SharedPreferences sharedPreferences;

  var _progressStreamController = StreamController<String>.broadcast();
  Stream<String> get progressStream => _progressStreamController.stream;

  static const String lastSyncTimestampKey = 'last_sync_timestamp';

  AppDataRepository({
    this.odooService,
    required this.clientesDao,
    required this.tarifasDao,
    required this.petTypesDao,
    required this.sharedPreferences,
  });

  String _sanitizeString(dynamic value, {String defaultValue = ''}) {
    if (value is String) return value;
    if (value == false || value == null) return defaultValue;
    return value.toString();
  }

  // Watchers
  Stream<List<Cliente>> watchClientes() => clientesDao.watchAllClientes();
  Stream<List<Tarifa>> watchTarifas() => tarifasDao.watchAllTarifas();
  Stream<List<PetType>> watchPetTypes() => petTypesDao.watchAllPetTypes();

  // Métodos de sincronización individuales y robustos
  Future<bool> syncPetTypes() async {
    if (odooService == null || !odooService!.isUserLoggedIn) return true;
    try {
      _progressStreamController.add('Actualizando razas de mascotas...');
      final petTypesFromOdoo = await odooService!.fetchPetTypes();
      if (petTypesFromOdoo.isNotEmpty) {
        final petTypesToSave = petTypesFromOdoo.map((data) => PetTypesCompanion(
          odooId: Value(data['id'] as int),
          name: Value(_sanitizeString(data['name'])),
        )).toList();
        await petTypesDao.insertOrUpdateAll(petTypesToSave);
        _progressStreamController.add('${petTypesToSave.length} razas actualizadas.');
      }
      return true;
    } catch (e) {
      developer.log('Error sincronizando razas: $e', name: 'AppDataRepository');
      _progressStreamController.add('❌ Error actualizando razas.');
      return false;
    }
  }

  Future<bool> syncTarifas() async {
    if (odooService == null || !odooService!.isUserLoggedIn) return true;
    try {
      _progressStreamController.add('Actualizando lista de tarifas...');
      final tarifasFromOdoo = await odooService!.fetchTarifas();
      if (tarifasFromOdoo.isNotEmpty) {
        final tarifasToSave = tarifasFromOdoo.map((data) => TarifasCompanion(
          odooId: Value(data['id'] as int),
          name: Value(_sanitizeString(data['name'])),
        )).toList();
        await tarifasDao.insertOrUpdateAll(tarifasToSave);
        _progressStreamController.add('${tarifasToSave.length} tarifas actualizadas.');
      }
      return true;
    } catch (e) {
      developer.log('Error sincronizando tarifas: $e', name: 'AppDataRepository');
      _progressStreamController.add('❌ Error actualizando tarifas.');
      return false;
    }
  }

  Future<bool> _syncClientesData() async {
     if (odooService == null || !odooService!.isUserLoggedIn) return true;
    try {
      final lastSync = _getLastSyncDate();
      final totalToSync = await odooService!.countClientes(lastSync: lastSync);

      if (totalToSync == 0) {
        _progressStreamController.add('Clientes al día.');
        return true;
      }

      _progressStreamController.add('$totalToSync clientes para descargar.');

      const chunkSize = 50;
      for (int offset = 0; offset < totalToSync; offset += chunkSize) {
        final message = 'Descargando clientes... ${offset + 1} - ${offset + chunkSize > totalToSync ? totalToSync : offset + chunkSize} de $totalToSync';
        _progressStreamController.add(message);

        final clientesFromOdoo = await odooService!.fetchClientesChunk(lastSync: lastSync, limit: chunkSize, offset: offset);
        if (clientesFromOdoo.isNotEmpty) {
          final clientesToSave = clientesFromOdoo.map((data) => _clienteFromOdooData(data)).toList();
          await clientesDao.insertOrUpdateAll(clientesToSave);
        }
      }
       _progressStreamController.add('Clientes actualizados.');
       return true;
    } catch (e, s) {
      final errorMessage = '❌ Error descargando clientes: $e';
      _progressStreamController.add(errorMessage);
      developer.log(errorMessage, stackTrace: s, name: 'AppDataRepository');
      return false;
    }
  }

  // Orquestador principal de sincronización
  Future<void> syncAllData() async {
    if (_progressStreamController.isClosed) {
      _progressStreamController = StreamController<String>.broadcast();
    }

    if (odooService == null || !odooService!.isUserLoggedIn) {
      _progressStreamController.add("Sincronización pausada. Inicia sesión para continuar.");
      return;
    }

    developer.log('🚀 Iniciando proceso de sincronización completo...', name: 'AppDataRepository');
    _progressStreamController.add('Iniciando sincronización total...');

    bool syncOk = true;

    // 1. Sincronizar cambios locales pendientes
    syncOk &= await _syncPendientes();

    // 2. Sincronizar datos maestros
    syncOk &= await syncPetTypes();
    syncOk &= await syncTarifas();
    
    // 3. Sincronizar datos principales
    syncOk &= await _syncClientesData();
    
    if (syncOk) {
      await _saveLastSyncDate();
      _progressStreamController.add('✅ Sincronización completada.');
    } else {
      _progressStreamController.add('⚠️ Sincronización completada con errores.');
    }
  }

  Future<bool> _syncPendientes() async {
    final pendientes = await clientesDao.getClientesPendientes();
    if (pendientes.isEmpty) return true;

    _progressStreamController.add('Enviando ${pendientes.length} cambios locales...');
    bool allSuccess = true;
    
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
        allSuccess = false;
        developer.log('Error sincronizando cliente ${cliente.id}: $e', name: 'AppDataRepository');
         _progressStreamController.add('⚠️ Error enviando el cliente ${cliente.name}. Se reintentará luego.');
      }
    }
    _progressStreamController.add('Cambios locales enviados.');
    return allSuccess;
  }

  // Métodos de CRUD para Clientes
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
    syncAllData();
  }

  Future<void> updateCliente(Cliente cliente) async {
    final updatedCliente = cliente.copyWith(pendingSync: true);
    await clientesDao.updateCliente(updatedCliente);
    syncAllData();
  }

  Future<void> deleteCliente(Cliente cliente) async {
    final updatedCliente = cliente.copyWith(pendingSync: true, isDeleted: true);
    await clientesDao.updateCliente(updatedCliente);
    syncAllData(); 
  }

  // Métodos de CRUD para Razas
  Future<void> createPetType(String name) async {
    final petType = PetTypesCompanion(
      name: Value(name),
    );
    await petTypesDao.insertPetType(petType);
    syncAllData();
  }

  Future<void> updatePetType(PetType petType) async {
    await petTypesDao.updatePetType(petType);
    syncAllData();
  }

  Future<void> deletePetType(PetType petType) async {
    await petTypesDao.deletePetType(petType);
    syncAllData(); 
  }


  // Helpers
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
