
import 'package:flutter/material.dart';
import '../data/remote/odoo_service.dart';

class AuthProvider with ChangeNotifier {
  OdooService? _odooService;

  OdooService? get odooService => _odooService;
  bool get isLoggedIn => _odooService != null && _odooService!.uid != null;
  int? get uid => _odooService?.uid;

  void login(OdooService service) {
    _odooService = service;
    notifyListeners();
  }

  void logout() {
    _odooService?.dispose(); // Cierra el cliente http
    _odooService = null;
    notifyListeners();
  }
}
