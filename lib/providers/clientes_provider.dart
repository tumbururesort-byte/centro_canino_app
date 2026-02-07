import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:myapp/data/app_data_repository.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/data/local/app_database.dart';
import 'dart:developer' as developer;

class ClientesProvider with ChangeNotifier {
  final AppDataRepository repository;
  final AuthProvider authProvider;
  
  List<Cliente> _clientes = [];
  List<Tarifa> _tarifas = [];
  bool _isLoading = false;
  String? _error;
  String? _syncMessage;

  StreamSubscription? _clientesSubscription;
  StreamSubscription? _tarifasSubscription;

  ClientesProvider({required this.repository, required this.authProvider}) {
    _listenToStreams();
    authProvider.addListener(_onAuthChange);
    _onAuthChange(); 
  }

  List<Cliente> get clientes => _clientes;
  List<Tarifa> get tarifas => _tarifas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get syncMessage => _syncMessage;

  void _listenToStreams() {
    _clientesSubscription?.cancel();
    _clientesSubscription = repository.watchClientes().listen((clientesList) {
      _clientes = clientesList;
      notifyListeners();
    }, onError: (e) {
      _error = "Error al cargar clientes: $e";
      notifyListeners();
    });

    _tarifasSubscription?.cancel();
    _tarifasSubscription = repository.watchTarifas().listen((tarifasList) {
      _tarifas = tarifasList;
      notifyListeners();
    }, onError: (e) {
      _error = "Error al cargar tarifas: $e";
      notifyListeners();
    });
  }

  void _onAuthChange() {
    if (authProvider.isLoggedIn) {
      syncAllData();
      repository.progressStream.listen((message) {
        _syncMessage = message;
        _isLoading = !message.contains('completada') && !message.contains('Error') && !message.contains('pausada');
        notifyListeners();
      }, onDone: () {
        _isLoading = false;
        _syncMessage = null;
        notifyListeners();
      }, onError: (e) {
        _error = "Error en el stream de progreso: $e";
        _isLoading = false;
        notifyListeners();
      });
    } else {
      _clientes = [];
      _tarifas = [];
      _syncMessage = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }

  Future<void> syncAllData() async {
    if (!authProvider.isLoggedIn) {
      _error = "Debes iniciar sesión para sincronizar.";
      notifyListeners();
      return;
    }
    
    _error = null;
    _isLoading = true;
    notifyListeners();
    
    try {
      await repository.syncAllData();
    } catch (e, s) {
      _error = e.toString();
      developer.log('Error en syncAllData', error: e, stackTrace: s, name: 'ClientesProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCliente(String name, String email, String phone, String city, int? tarifaId) async {
    try {
      await repository.createCliente(name, email, phone, city, tarifaId);
    } catch (e) {
      _error = 'Error al crear cliente: $e';
      notifyListeners();
    }
  }

  Future<void> updateCliente(Cliente cliente) async {
    try {
      await repository.updateCliente(cliente);
    } catch (e) {
      _error = 'Error al actualizar cliente: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCliente(Cliente cliente) async {
    try {
      await repository.deleteCliente(cliente);
    } catch (e) {
      _error = 'Error al eliminar cliente: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _clientesSubscription?.cancel();
    _tarifasSubscription?.cancel();
    authProvider.removeListener(_onAuthChange);
    super.dispose();
  }
}
