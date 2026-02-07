import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/data/clientes_repository.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/providers/auth_provider.dart';

class ClientesProvider with ChangeNotifier {
  final ClientesRepository _repository;
  final AuthProvider _authProvider;

  List<Cliente> _clientes = [];
  List<Tarifa> _tarifas = [];
  bool _isLoading = false;
  String? _error;
  String? _syncMessage;

  StreamSubscription? _clientesSubscription;
  StreamSubscription? _tarifasSubscription;
  StreamSubscription? _progressSubscription;
  StreamSubscription? _authSubscription;

  ClientesProvider({
    required ClientesRepository repository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _authProvider = authProvider {
    _authSubscription = _authProvider.onAuthChanged.listen((isLoggedIn) {
      if (isLoggedIn) {
        _initialize();
      } else {
        _clearData();
      }
    });
    
    if (_authProvider.isLoggedIn) {
      _initialize();
    }
  }

  void _initialize() {
    _listenToClientesStream();
    _listenToTarifasStream();
    _listenToProgressStream();
    syncClientes();
  }

  List<Cliente> get clientes => _clientes;
  List<Tarifa> get tarifas => _tarifas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get syncMessage => _syncMessage;

  void _listenToClientesStream() {
    _clientesSubscription?.cancel();
    _clientesSubscription = _repository.watchClientes().listen(
      (clientes) {
        _clientes = clientes;
        if (!_isLoading) {
          notifyListeners();
        }
      },
      onError: (e) {
        _error = 'Error al leer la base de datos: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _listenToTarifasStream() {
    _tarifasSubscription?.cancel();
    _tarifasSubscription = _repository.watchTarifas().listen(
      (tarifas) {
        _tarifas = tarifas;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Error al leer las tarifas: $e';
        notifyListeners();
      },
    );
  }

  void _listenToProgressStream() {
    _progressSubscription?.cancel();
    _progressSubscription = _repository.progressStream.listen((message) {
      _syncMessage = message;
      final isFinalMessage = message.startsWith('✅') || message.startsWith('❌') || message.startsWith('👍');
      
      if (isFinalMessage) {
        _isLoading = false;
        _error = message.startsWith('❌') ? message : null;
      } else {
        _isLoading = true;
        _error = null;
      }
      
      notifyListeners();
    });
  }

  Future<void> syncClientes() async {
    if (_isLoading) return;
    await _repository.syncClientes();
  }

  Future<void> createCliente(String name, String email, String phone, String city, int? tarifaId) async {
    if (name.trim().isEmpty) throw Exception('El nombre es obligatorio');
    await _repository.createCliente(name.trim(), email.trim(), phone.trim(), city.trim(), tarifaId);
  }

  Future<void> updateCliente(Cliente cliente) async {
    if (cliente.name.trim().isEmpty) throw Exception('El nombre es obligatorio');
    await _repository.updateCliente(cliente);
  }

  Future<void> deleteCliente(Cliente cliente) async {
    await _repository.deleteCliente(cliente);
  }

  void _clearData() {
    _clientesSubscription?.cancel();
    _tarifasSubscription?.cancel();
    _progressSubscription?.cancel();
    _clientes = [];
    _tarifas = [];
    _isLoading = false;
    _error = null;
    _syncMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clientesSubscription?.cancel();
    _tarifasSubscription?.cancel();
    _progressSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
