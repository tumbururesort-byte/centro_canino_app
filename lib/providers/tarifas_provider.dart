import 'package:flutter/material.dart';
import 'package:myapp/data/app_data_repository.dart';
import 'package:myapp/data/local/app_database.dart';
import 'dart:async';

class TarifasProvider with ChangeNotifier {
  final AppDataRepository repository;
  List<Tarifa> _tarifas = [];
  StreamSubscription? _tarifasSubscription;

  TarifasProvider({required this.repository}) {
    _listenToTarifasStream();
  }

  List<Tarifa> get tarifas => _tarifas;

  void _listenToTarifasStream() {
    _tarifasSubscription?.cancel();
    _tarifasSubscription = repository.watchTarifas().listen((tarifas) {
      _tarifas = tarifas;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tarifasSubscription?.cancel();
    super.dispose();
  }
}
