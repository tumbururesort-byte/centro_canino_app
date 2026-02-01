
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'dart:convert'; // Necesario para utf8
import 'dart:async'; // Necesario para TimeoutException

class OdooService {
  final String serverUrl;
  final String dbName;
  late http.Client _client;
  String? _sessionId;
  int? uid;
  String? userName;
  String? userLogin;

  // GETTERS para acceder al estado
  String get url => serverUrl;
  String get db => dbName;
  String? get sessionId => _sessionId;

  OdooService({required this.serverUrl, required this.dbName}) {
    _client = http.Client();
  }

  // Restaura la sesión desde datos guardados
  void restoreSession(String newSessionId, int newUid, String newUserName, String newUserLogin) {
    _sessionId = newSessionId;
    uid = newUid;
    userName = newUserName;
    userLogin = newUserLogin;
    developer.log('🔄 Sesión restaurada para $userName. UID: $uid', name: 'OdooService');
  }

  // Autenticar y guardar la sesión
  Future<int> authenticate(String username, String password) async {
    final url = Uri.parse('$serverUrl/web/session/authenticate');
    
    final requestBody = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'db': dbName,
        'login': username,
        'password': password,
        'context': {},
      },
    });

    developer.log('🔐 Autenticando en $url', name: 'OdooService');
    
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          final cookie = rawCookie.split(';').firstWhere(
                (c) => c.trim().startsWith('session_id='),
                orElse: () => '',
              );
          if (cookie.isNotEmpty) {
            _sessionId = cookie.split('=')[1];
          }
        }
        
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData.containsKey('error')) {
            final error = responseData['error'];
            developer.log('❌ Error de Odoo: ${error['message']}', name: 'OdooService');
            throw Exception('Error de Odoo: ${error['data']['debug']}');
        }

        final result = responseData['result'];
        if (_sessionId != null && result != null && result['uid'] != false) {
          uid = result['uid'];
          userName = result['name']; // Guardar nombre de usuario
          userLogin = result['username']; // Guardar login

          developer.log('✅ Autenticación exitosa para $userName. UID: $uid', name: 'OdooService');
          return uid!;
        } else {
          throw Exception('No se pudo obtener UID o Session ID de la respuesta.');
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
    if (_sessionId == null || uid == null) {
      throw Exception('No autenticado. Por favor, inicie sesión primero.');
    }

    final url = Uri.parse('$serverUrl$path');
    final requestBody = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': params,
    });

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
        developer.log('❌ Error RPC de Odoo: ${error['message']}', name: 'OdooService');
        throw Exception('Error RPC: ${error['data']['debug']}');
      }
      return responseData['result'];
    } else {
      throw Exception('Error en la llamada RPC: ${response.statusCode}');
    }
  }

  // --- NUEVO MÉTODO ---
  // Cuenta el número de clientes que cumplen con el criterio de sincronización.
  Future<int> countClientes({DateTime? lastSync}) async {
    developer.log('🔍 Contando clientes para sincronizar...', name: 'OdooService');

    // El dominio es idéntico al de fetch para asegurar consistencia
    List<dynamic> domain = [
      ['customer_rank', '>', 0]
    ];
    if (lastSync != null) {
      final utcDate = lastSync.toUtc().toIso8601String().split('.')[0];
      domain.add(['write_date', '>', utcDate]);
    }

    final result = await _executeRpc('/web/dataset/call_kw/res.partner/search_count', 'call', {
        'args': [domain],
        'kwargs': {
          'context': {},
        },
        'model': 'res.partner',
        'method': 'search_count',
    });

    developer.log('✅ Conteo finalizado: $result clientes.', name: 'OdooService');
    return result is int ? result : 0;
  }

  // --- MODIFICADO ---
  // Obtiene un "trozo" (chunk) de clientes usando limit y offset.
  Future<List<Map<String, dynamic>>> fetchClientesChunk({
    DateTime? lastSync,
    required int limit,
    required int offset,
  }) async {
    if (lastSync != null) {
      developer.log('📡 Obteniendo clientes (lote de $limit a partir de $offset) modificados desde ${lastSync.toIso8601String()}...', name: 'OdooService');
    } else {
      developer.log('📡 Obteniendo TODOS los clientes de Odoo (lote de $limit a partir de $offset)...', name: 'OdooService');
    }

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
      'limit': limit,  // Usar el límite pasado por parámetro
      'offset': offset, // Usar el offset pasado por parámetro
      'sort': 'id ASC', // Es buena práctica ordenar para obtener resultados consistentes
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
        'kwargs': {
          'context': {},
        },
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
        'kwargs': {
          'context': {},
        },
        'model': 'res.partner',
        'method': 'write',
    });
    developer.log('✅ Cliente actualizado.', name: 'OdooService');
  }

  Future<void> deleteCliente(int odooId) async {
    developer.log('🗑️ Eliminando cliente Odoo ID: $odooId', name: 'OdooService');
     await _executeRpc('/web/dataset/call_kw/res.partner/unlink', 'call', {
        'args': [[odooId]],
        'kwargs': {
          'context': {},
        },
        'model': 'res.partner',
        'method': 'unlink',
    });
    developer.log('✅ Cliente eliminado.', name: 'OdooService');
  }
  
  void dispose() {
    _client.close();
  }
}
