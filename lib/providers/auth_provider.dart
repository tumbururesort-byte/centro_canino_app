import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/remote/odoo_service.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences sharedPreferences;
  OdooService? _odooService;

  OdooService? get odooService => _odooService;
  bool get isLoggedIn => _odooService != null && _odooService!.uid != null;
  int? get uid => _odooService?.uid;

  bool _autoLoginAttempted = false; // Para evitar reintentos infinitos

  AuthProvider({required this.sharedPreferences});

  Future<void> login(OdooService service) async {
    _odooService = service;

    // Guardar sesión
    await sharedPreferences.setString('odoo_url', service.url);
    await sharedPreferences.setString('odoo_db', service.dbName);
    await sharedPreferences.setString('odoo_session_id', service.sessionId!);
    await sharedPreferences.setInt('odoo_uid', service.uid!);

    notifyListeners();
  }

  Future<void> logout() async {
    _odooService?.dispose();
    _odooService = null;

    // Limpiar sesión guardada
    await sharedPreferences.remove('odoo_url');
    await sharedPreferences.remove('odoo_db');
    await sharedPreferences.remove('odoo_session_id');
    await sharedPreferences.remove('odoo_uid');

    notifyListeners();
  }

  // Intenta loguearse automáticamente al iniciar la app.
  Future<void> tryAutoLogin() async {
    if (_autoLoginAttempted) return;
    _autoLoginAttempted = true;

    final url = sharedPreferences.getString('odoo_url');
    final db = sharedPreferences.getString('odoo_db');
    final sessionId = sharedPreferences.getString('odoo_session_id');
    final uid = sharedPreferences.getInt('odoo_uid');

    if (url != null && db != null && sessionId != null && uid != null) {
      try {
        // Creamos una instancia de OdooService con los datos guardados
        final service = OdooService(serverUrl: url, dbName: db);
        // Restauramos la sesión
        service.restoreSession(sessionId, uid);

        _odooService = service;
        notifyListeners();
      } catch (e) {
        // Si falla la restauración, limpiamos las credenciales corruptas
        await logout();
      }
    }
  }
}
