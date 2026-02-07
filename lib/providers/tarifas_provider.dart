import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/data/clientes_repository.dart';

class TarifasProvider with ChangeNotifier {
  final ClientesRepository _repository;
  StreamSubscription? _tarifasSubscription;
  StreamSubscription? _progressSubscription;

  List<Tarifa> _tarifas = [];
  List<Tarifa> get tarifas => _tarifas;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _syncMessage;
  String? get syncMessage => _syncMessage;

  TarifasProvider(this._repository) {
    _listenToTarifas();
    _listenToProgress();
  }

  void _listenToTarifas() {
    _tarifasSubscription?.cancel();
    _tarifasSubscription = _repository.watchTarifas().listen((tarifas) {
      _tarifas = tarifas;
      notifyListeners();
    });
  }

  void _listenToProgress() {
    _progressSubscription?.cancel();
    _progressSubscription = _repository.progressStream.listen((message) {
      _syncMessage = message;
      notifyListeners();
    });
  }

  Future<void> syncTarifas() async {
    _isLoading = true;
    _error = null;
    _syncMessage = 'Iniciando sincronización de tarifas...';
    notifyListeners();

    try {
      await _repository.syncTarifas();
    } catch (e) {
      _error = 'Error al sincronizar tarifas: $e';
    } finally {
      _isLoading = false;
      _syncMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tarifasSubscription?.cancel();
    _progressSubscription?.cancel();
    super.dispose();
  }
}
