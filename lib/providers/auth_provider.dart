
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/remote/odoo_service.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences sharedPreferences;
  OdooService? _odooService;

  OdooService? get odooService => _odooService;
  bool get isLoggedIn => _odooService != null && _odooService!.uid != null;
  int? get uid => _odooService?.uid;
  String? get userName => _odooService?.userName;
  String? get userLogin => _odooService?.userLogin;
  String? get serverUrl => _odooService?.url;
  String? get dbName => _odooService?.db;
  
  bool _autoLoginAttempted = false;

  AuthProvider({required this.sharedPreferences});

  Future<void> login(OdooService service) async {
    _odooService = service;
    
    await sharedPreferences.setString('odoo_url', service.url);
    await sharedPreferences.setString('odoo_db', service.dbName);
    await sharedPreferences.setString('odoo_session_id', service.sessionId!);
    await sharedPreferences.setInt('odoo_uid', service.uid!);
    await sharedPreferences.setString('odoo_user_name', service.userName!);
    await sharedPreferences.setString('odoo_user_login', service.userLogin!);
    
    notifyListeners();
  }

  Future<void> logout() async {
    _odooService?.dispose();
    _odooService = null;
    
    await sharedPreferences.clear(); // Limpiamos todo por simplicidad
    
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    if (_autoLoginAttempted) return;
    _autoLoginAttempted = true;

    final url = sharedPreferences.getString('odoo_url');
    final db = sharedPreferences.getString('odoo_db');
    final sessionId = sharedPreferences.getString('odoo_session_id');
    final uid = sharedPreferences.getInt('odoo_uid');
    final userName = sharedPreferences.getString('odoo_user_name');
    final userLogin = sharedPreferences.getString('odoo_user_login');

    if (url != null && db != null && sessionId != null && uid != null && userName != null && userLogin != null) {
      try {
        final service = OdooService(serverUrl: url, dbName: db);
        service.restoreSession(sessionId, uid, userName, userLogin);

        _odooService = service;
        notifyListeners();
      } catch (e) {
        await logout();
      }
    }
  }
}
