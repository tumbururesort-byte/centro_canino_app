
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  int? _uid;
  String? _sessionId;
  // Agrega aquí otros datos de sesión que necesites, como el nombre de usuario, etc.

  int? get uid => _uid;
  String? get sessionId => _sessionId;
  bool get isLoggedIn => _uid != null;

  void login(int uid, String sessionId) {
    _uid = uid;
    _sessionId = sessionId;
    // Notifica a los listeners que el estado ha cambiado.
    notifyListeners();
  }

  void logout() {
    _uid = null;
    _sessionId = null;
    notifyListeners();
  }
}
