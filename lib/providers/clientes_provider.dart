
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/data/clientes_repository.dart';
import 'package:myapp/data/local/app_database.dart';

class ClientesProvider with ChangeNotifier {
  late ClientesRepository _repository;
  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _clientesSubscription;

  ClientesProvider({required ClientesRepository repository}) {
    _repository = repository;
    // 1. Escuchar los datos de la base de datos local inmediatamente.
    _listenToClientesStream();
    // 2. Iniciar la sincronizaciÃ³n automÃ¡tica en segundo plano.
    syncClientes(); 
  }

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // MÃ©todo para que el ProxyProvider actualice el repositorio
  void updateRepository(ClientesRepository newRepository) {
    _repository = newRepository;
    // Reinicia la escucha y la sincronizaciÃ³n si el repositorio cambia
    _listenToClientesStream();
    syncClientes(); 
  }

  void _listenToClientesStream() {
    _clientesSubscription?.cancel(); // Cancela la suscripciÃ³n anterior
    _clientesSubscription = _repository.watchClientes().listen((clientes) {
      _clientes = clientes;
      // Solo notificar si no estamos en medio de una operaciÃ³n de carga inicial.
      // Esto evita un parpadeo en la UI.
      if (!_isLoading) {
        notifyListeners();
      }
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> syncClientes() async {
    if (_isLoading) return; // No sincronizar si ya estÃ¡ en proceso

    // Mostrar indicador de carga solo si es la primera vez (no hay clientes).
    // Las sincronizaciones de fondo serÃ¡n silenciosas.
    if (_clientes.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    _error = null;

    try {
      await _repository.syncClientes();
    } catch (e) {
      // En una app real, podrÃ­as querer registrar este error en un servicio
      // de logging en lugar de siempre mostrarlo al usuario, para que los fallos
      // de fondo no sean intrusivos.
      _error = e.toString();
    } finally {
      // Si estÃ¡bamos en el estado de carga inicial, lo desactivamos.
      if (_isLoading) {
        _isLoading = false;
      }
      // Notificamos a la UI para que se actualice con los nuevos datos o el error.
      notifyListeners();
    }
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
    super.dispose();
  }
}
