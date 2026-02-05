import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/data/clientes_repository.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/providers/auth_provider.dart';

class ClientesProvider with ChangeNotifier {
  late ClientesRepository _repository;
  final AuthProvider _authProvider;

  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _error;
  String? _syncMessage;

  StreamSubscription? _clientesSubscription;
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
    _listenToProgressStream();
    syncClientes();
  }

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get syncMessage => _syncMessage;

  void updateDependencies(ClientesRepository newRepository, AuthProvider newAuthProvider) {
    if (_repository != newRepository) {
      _repository.dispose();
      _repository = newRepository;
      
      if (newAuthProvider.isLoggedIn) {
        _initialize();
      }
    }
  }

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

  Future<void> createCliente(String name, String email, String phone, String city) async {
    if (name.trim().isEmpty) throw Exception('El nombre es obligatorio');
    await _repository.createCliente(name.trim(), email.trim(), phone.trim(), city.trim());
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
    _progressSubscription?.cancel();
    _clientes = [];
    _isLoading = false;
    _error = null;
    _syncMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clientesSubscription?.cancel();
    _progressSubscription?.cancel();
    _authSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
