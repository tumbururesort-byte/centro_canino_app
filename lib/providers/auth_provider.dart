import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/remote/odoo_service.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences sharedPreferences;
  OdooService? _odooService;

  final _authChangeController = StreamController<bool>.broadcast();
  Stream<bool> get onAuthChanged => _authChangeController.stream;

  OdooService? get odooService => _odooService;
  bool get isLoggedIn => _odooService != null && _odooService!.isUserLoggedIn;
  int? get uid => _odooService?.uid;
  String? get userName => _odooService?.userName;
  String? get userLogin => _odooService?.userLogin;
  String? get serverUrl => _odooService?.url;
  String? get dbName => _odooService?.db;
  
  bool _autoLoginAttempted = false;

  AuthProvider({required this.sharedPreferences});

  /// Intenta hacer login con las credenciales proporcionadas
  Future<bool> login(String url, String db, String email, String password) async {
    try {
      // Limpiar URL de espacios en blanco
      final cleanUrl = url.trim();
      final cleanDb = db.trim();
      final cleanEmail = email.trim();
      
      // Validaciones básicas
      if (cleanUrl.isEmpty || cleanDb.isEmpty || cleanEmail.isEmpty || password.isEmpty) {
        throw Exception('Todos los campos son requeridos');
      }
      
      final service = OdooService(serverUrl: cleanUrl, dbName: cleanDb);
      await service.authenticate(cleanEmail, password);

      if (service.isUserLoggedIn) {
        _odooService = service;
        await _saveSession();
        notifyListeners();
        _authChangeController.add(true);
        
        if (kDebugMode) {
          print('✅ Login exitoso para ${service.userName}');
        }
        return true;
      } else {
        _odooService = null;
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error durante login: $e');
      }
      _odooService = null;
      rethrow;
    }
  }

  /// Guarda la sesión actual en SharedPreferences
  Future<void> _saveSession() async {
    if (_odooService == null || !_odooService!.isUserLoggedIn) return;
    
    final service = _odooService!;
    
    try {
      await Future.wait([
        sharedPreferences.setString('odoo_url', service.url),
        sharedPreferences.setString('odoo_db', service.dbName),
        sharedPreferences.setString('odoo_session_id', service.sessionId!),
        sharedPreferences.setInt('odoo_uid', service.uid!),
        sharedPreferences.setString('odoo_user_name', service.userName!),
        sharedPreferences.setString('odoo_user_login', service.userLogin!),
      ]);
      
      if (kDebugMode) {
        print('💾 Sesión guardada exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al guardar sesión: $e');
      }
    }
  }

  /// Cierra la sesión actual
  Future<void> logout() async {
    try {
      _odooService?.dispose();
      _odooService = null;
      
      await sharedPreferences.clear();
      
      notifyListeners();
      _authChangeController.add(false);
      
      if (kDebugMode) {
        print('👋 Sesión cerrada exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al cerrar sesión: $e');
      }
    }
  }

  /// Intenta restaurar la sesión guardada automáticamente
  Future<void> tryAutoLogin() async {
    if (_autoLoginAttempted) {
      if (kDebugMode) {
        print('⚠️ Auto-login ya fue intentado');
      }
      return;
    }
    
    _autoLoginAttempted = true;

    try {
      final url = sharedPreferences.getString('odoo_url');
      final db = sharedPreferences.getString('odoo_db');
      final sessionId = sharedPreferences.getString('odoo_session_id');
      final uid = sharedPreferences.getInt('odoo_uid');
      final userName = sharedPreferences.getString('odoo_user_name');
      final userLogin = sharedPreferences.getString('odoo_user_login');

      // Verificar que todos los datos necesarios estén presentes
      if (url != null && 
          db != null && 
          sessionId != null && 
          uid != null && 
          userName != null && 
          userLogin != null) {
        
        if (kDebugMode) {
          print('🔄 Intentando restaurar sesión para $userName...');
        }
        
        final service = OdooService(serverUrl: url, dbName: db);
        service.restoreSession(sessionId, uid, userName, userLogin);

        _odooService = service;
        notifyListeners();
        _authChangeController.add(true);
        
        if (kDebugMode) {
          print('✅ Sesión restaurada exitosamente');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ No hay sesión guardada para restaurar');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al restaurar sesión: $e');
      }
      await logout();
    }
  }

  @override
  void dispose() {
    _authChangeController.close();
    _odooService?.dispose();
    super.dispose();
  }
}