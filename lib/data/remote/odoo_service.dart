
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

  OdooService({required this.serverUrl, required this.dbName}) {
    _client = http.Client();
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

        if (_sessionId != null && responseData['result'] != null && responseData['result']['uid'] != false) {
          uid = responseData['result']['uid'];
          developer.log('✅ Autenticación exitosa. UID: $uid, SessionID: $_sessionId', name: 'OdooService');
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

  // MODIFICADO para aceptar una fecha de sincronización
  Future<List<Map<String, dynamic>>> fetchClientes({DateTime? lastSync}) async {
    if (lastSync != null) {
      developer.log('📡 Obteniendo clientes modificados desde ${lastSync.toIso8601String()}...', name: 'OdooService');
    } else {
      developer.log('📡 Obteniendo TODOS los clientes de Odoo...', name: 'OdooService');
    }

    // Construimos el dominio base
    List<dynamic> domain = [
      ['customer_rank', '>', 0]
    ];

    // Si hay una fecha de última sincronización, la añadimos al filtro
    if (lastSync != null) {
      // Formateamos la fecha a UTC para Odoo
      final utcDate = lastSync.toUtc().toIso8601String().split('.')[0];
      domain.add(['write_date', '>', utcDate]);
    }

    final result = await _executeRpc('/web/dataset/search_read', 'call', {
      'model': 'res.partner',
      // Añadimos 'write_date' para poder filtrar
      'fields': ['id', 'name', 'email', 'phone', 'city', 'write_date'],
      'domain': domain,
      'limit': false,
      'sort': '',
      'context': {},
    });

    if (result != null && result['records'] is List) {
      final records = List<Map<String, dynamic>>.from(result['records']);
      developer.log('✅ ${records.length} clientes recibidos.', name: 'OdooService');
      return records;
    }
    return [];
  }

  Future<int> createCliente(Map<String, dynamic> data) async {
    developer.log('➕ Creando cliente en Odoo: ${data['name']}', name: 'OdooService');
    final newId = await _executeRpc('/web/dataset/call_kw/res.partner/create', 'call', {
        'args': [data],
        'kwargs': {},
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
        'kwargs': {},
        'model': 'res.partner',
        'method': 'write',
    });
    developer.log('✅ Cliente actualizado.', name: 'OdooService');
  }

  Future<void> deleteCliente(int odooId) async {
    developer.log('🗑️ Eliminando cliente Odoo ID: $odooId', name: 'OdooService');
     await _executeRpc('/web/dataset/call_kw/res.partner/unlink', 'call', {
        'args': [[odooId]],
        'kwargs': {},
        'model': 'res.partner',
        'method': 'unlink',
    });
    developer.log('✅ Cliente eliminado.', name: 'OdooService');
  }
  
  void dispose() {
    _client.close();
  }
}
