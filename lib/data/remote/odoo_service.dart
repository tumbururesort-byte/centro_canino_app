import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:async';

class OdooService {
  final String serverUrl;
  final String dbName;
  late http.Client _client;
  String? _sessionId;
  int? uid;
  String? userName;
  String? userLogin;

  String get url => serverUrl;
  String get db => dbName;
  String? get sessionId => _sessionId;
  
  /// Returns true if the user is currently authenticated.
  bool get isUserLoggedIn => uid != null && _sessionId != null;

  OdooService({required this.serverUrl, required this.dbName}) {
    _client = http.Client();
  }

  void restoreSession(String newSessionId, int newUid, String newUserName, String newUserLogin) {
    _sessionId = newSessionId;
    uid = newUid;
    userName = newUserName;
    userLogin = newUserLogin;
    developer.log('🔄 Sesión restaurada para $userName. UID: $uid', name: 'OdooService');
  }

  Future<void> authenticate(String email, String password) async {
    final url = Uri.parse('$serverUrl/web/session/authenticate');
    
    final requestBody = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'db': dbName,
        'login': email,
        'password': password,
        'context': {},
      },
    });

    developer.log('🔐 Autenticando en $url para la base de datos $dbName', name: 'OdooService');
    
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          _sessionId = rawCookie.split(';').firstWhere(
            (c) => c.trim().startsWith('session_id='),
            orElse: () => ''
          ).split('=').last;
        }
        
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData.containsKey('error')) {
          final error = responseData['error'];
          developer.log('❌ Error de Odoo: ${error['message']}', name: 'OdooService');
          throw Exception('Error de Odoo: ${error['data']['debug']}');
        }

        final result = responseData['result'];
        if (result != null && result['uid'] != false) {
          uid = result['uid'];
          userName = result['name'];
          userLogin = result['username'];

          developer.log('✅ Autenticación exitosa para $userName. UID: $uid', name: 'OdooService');
        } else {
          // Si no hay UID, consideramos la autenticación fallida.
          _sessionId = null; // Borramos el sessionId si lo hubiera
          throw Exception('Credenciales incorrectas o respuesta inesperada.');
        }
      } else {
        developer.log('❌ Error HTTP ${response.statusCode}: ${response.body}', name: 'OdooService');
        throw Exception('Error de conexión con el servidor: ${response.statusCode}');
      }
    } on TimeoutException {
      developer.log('❌ Timeout en la autenticación', name: 'OdooService');
      throw Exception('El servidor no respondió a tiempo. Verifique la URL y su conexión.');
    } catch (e) {
      developer.log('❌ Excepción en authenticate: $e', name: 'OdooService');
      rethrow;
    }
  }

  Future<dynamic> _executeRpc(String path, String method, Map<String, dynamic> params) async {
    if (!isUserLoggedIn) {
      throw Exception('No autenticado. Por favor, inicie sesión primero.');
    }

    final url = Uri.parse('$serverUrl$path');
    final requestBody = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': params,
    });

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 45));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        if (responseData.containsKey('error')) {
          final error = responseData['error'];
          developer.log('❌ Error RPC de Odoo: ${error['message']}', name: 'OdooService', error: error);
          throw Exception('Error RPC: ${error['data']['debug']}');
        }
        return responseData['result'];
      } else {
        throw Exception('Error en la llamada RPC: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Excepción en _executeRpc: $e', name: 'OdooService');
      rethrow;
    }
  }
  Future<int> countClientes({DateTime? lastSync}) async {
    developer.log('🔍 Contando clientes para sincronizar...', name: 'OdooService');
    List<dynamic> domain = [
      ['customer_rank', '>', 0]
    ];
    if (lastSync != null) {
      final utcDate = lastSync.toUtc().toIso8601String().split('.')[0];
      domain.add(['write_date', '>', utcDate]);
    }
    final result = await _executeRpc('/web/dataset/call_kw/res.partner/search_count', 'call', {
        'args': [domain],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'search_count',
    });
    developer.log('✅ Conteo finalizado: $result clientes.', name: 'OdooService');
    return result is int ? result : 0;
  }

  Future<List<Map<String, dynamic>>> fetchClientesChunk({
    DateTime? lastSync,
    required int limit,
    required int offset,
  }) async {
    final syncLog = lastSync != null ? 'modificados desde ${lastSync.toIso8601String()}' : 'TODOS';
    developer.log('📡 Obteniendo clientes (lote de $limit a partir de $offset) $syncLog...', name: 'OdooService');

    List<dynamic> domain = [
      ['customer_rank', '>', 0]
    ];
    if (lastSync != null) {
      final utcDate = lastSync.toUtc().toIso8601String().split('.')[0];
      domain.add(['write_date', '>', utcDate]);
    }

    final result = await _executeRpc('/web/dataset/search_read', 'call', {
      'model': 'res.partner',
      'fields': ['id', 'name', 'email', 'phone', 'city', 'write_date'],
      'domain': domain,
      'limit': limit,
      'offset': offset,
      'sort': 'id ASC',
      'context': {},
    });

    if (result != null && result['records'] is List) {
      final records = List<Map<String, dynamic>>.from(result['records']);
      developer.log('✅ ${records.length} clientes recibidos en este lote.', name: 'OdooService');
      return records;
    }
    return [];
  }

  Future<int> createCliente(Map<String, dynamic> data) async {
    developer.log('➕ Creando cliente en Odoo: ${data['name']}', name: 'OdooService');
    final newId = await _executeRpc('/web/dataset/call_kw/res.partner/create', 'call', {
        'args': [data],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'create',
    });
    developer.log('✅ Cliente creado con ID: $newId', name: 'OdooService');
    return newId;
  }

  Future<void> updateCliente(int odooId, Map<String, dynamic> data) async {
    developer.log('✏️ Actualizando cliente Odoo ID: $odooId', name: 'OdooService');
    await _executeRpc('/web/dataset/call_kw/res.partner/write', 'call', {
        'args': [[odooId], data],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'write',
    });
    developer.log('✅ Cliente actualizado.', name: 'OdooService');
  }

  Future<void> deleteCliente(int odooId) async {
    developer.log('🗑️ Eliminando cliente Odoo ID: $odooId', name: 'OdooService');
     await _executeRpc('/web/dataset/call_kw/res.partner/unlink', 'call', {
        'args': [[odooId]],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'unlink',
    });
    developer.log('✅ Cliente eliminado.', name: 'OdooService');
  }
  
  void dispose() {
    _client.close();
  }
}
