
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/data/clientes_repository.dart';
import 'package:myapp/data/local/app_database.dart';

class ClientesProvider with ChangeNotifier {
  late ClientesRepository _repository;
  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _error;
  
  String? _syncMessage;

  StreamSubscription? _clientesSubscription;
  StreamSubscription? _progressSubscription;

  ClientesProvider({required ClientesRepository repository}) {
    _repository = repository;
    _listenToClientesStream();
    _listenToProgressStream();
    syncClientes();
  }

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get syncMessage => _syncMessage;

  void updateRepository(ClientesRepository newRepository) {
    // Primero, nos aseguramos de limpiar los recursos del repositorio antiguo
    _repository.dispose(); 

    _repository = newRepository;
    // Reinicia todas las escuchas con el nuevo repositorio
    _listenToClientesStream();
    _listenToProgressStream();
    syncClientes(); 
  }

  void _listenToClientesStream() {
    _clientesSubscription?.cancel();
    _clientesSubscription = _repository.watchClientes().listen((clientes) {
      _clientes = clientes;
      if (!_isLoading) {
        notifyListeners();
      }
    }, onError: (e) {
      _error = 'Error al leer la base de datos: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToProgressStream() {
    _progressSubscription?.cancel();
    _progressSubscription = _repository.progressStream.listen((message) {
      _syncMessage = message;
      final isFinalMessage = message.startsWith('✅') || message.startsWith('❌') || message.startsWith('👍');
      if (isFinalMessage) {
        _isLoading = false;
        if (message.startsWith('❌')) {
          _error = message;
        }
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
    try {
      await _repository.createCliente(name, email, phone, city);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCliente(Cliente cliente) async {
    try {
      await _repository.updateCliente(cliente);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCliente(Cliente cliente) async {
    try {
      await _repository.deleteCliente(cliente);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _clientesSubscription?.cancel();
    _progressSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
