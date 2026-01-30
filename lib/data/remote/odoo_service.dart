import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class OdooService {
  // Verificar información del usuario autenticado
  Future<Map<String, dynamic>> getUserInfo({
    required String url,
    required String db,
    required int userId,
    required String password,
  }) async {
    developer.log('👤 Obteniendo información del usuario UID: $userId', name: 'OdooService');
    
    final uri = Uri.parse('$url/xmlrpc/2/object');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'text/xml'},
      body: '''<?xml version="1.0"?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>$db</string></value></param>
    <param><value><int>$userId</int></value></param>
    <param><value><string>$password</string></value></param>
    <param><value><string>res.users</string></value></param>
    <param><value><string>read</string></value></param>
    <param>
      <value><array><data>
        <value><array><data><value><int>$userId</int></value></data></array></value>
      </data></array></value>
    </param>
    <param>
      <value><struct>
        <member><name>fields</name><value><array><data>
          <value><string>id</string></value>
          <value><string>name</string></value>
          <value><string>login</string></value>
          <value><string>groups_id</string></value>
        </data></array></value></member>
      </struct></value>
    </param>
  </params>
</methodCall>''',
    );

    developer.log('📥 User Info Status: ${response.statusCode}', name: 'OdooService');
    developer.log('📥 User Info Response (primeros 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}', name: 'OdooService');
    
    // Verificar si hay un error en la respuesta
    if (response.body.contains('<fault>')) {
      developer.log('❌ Error obteniendo info del usuario', name: 'OdooService');
      final errorMsg = _extractFaultString(response.body);
      throw Exception('Error obteniendo info del usuario: $errorMsg');
    }
    
    return {};
  }

  // Autenticar
  Future<Map<String, dynamic>> authenticate({
    required String url,
    required String db,
    required String username,
    required String password,
  }) async {
    developer.log('🔐 Autenticando en $url/xmlrpc/2/common', name: 'OdooService');
    developer.log('DB: $db, User: $username', name: 'OdooService');
    
    try {
      final uri = Uri.parse('$url/xmlrpc/2/common');
      developer.log('🌐 URI: $uri', name: 'OdooService');
      developer.log('   Host: ${uri.host}', name: 'OdooService');
      developer.log('   Port: ${uri.port}', name: 'OdooService');
      developer.log('   Scheme: ${uri.scheme}', name: 'OdooService');
      
      final requestBody = '''<?xml version="1.0"?>
<methodCall>
  <methodName>login</methodName>
  <params>
    <param><value><string>$db</string></value></param>
    <param><value><string>$username</string></value></param>
    <param><value><string>$password</string></value></param>
  </params>
</methodCall>''';
      
      developer.log('📤 Enviando petición HTTP...', name: 'OdooService');
      developer.log('📄 XML Request:', name: 'OdooService');
      developer.log(requestBody, name: 'OdooService');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'text/xml',
          'User-Agent': 'Dart/3.0 (dart:io)',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          developer.log('⏰ TIMEOUT: La petición tardó más de 30 segundos', name: 'OdooService');
          throw Exception('Timeout: El servidor no respondió en 30 segundos');
        },
      );

      developer.log('📥 Status code: ${response.statusCode}', name: 'OdooService');

      if (response.statusCode != 200) {
        developer.log('❌ Error HTTP: ${response.statusCode}', name: 'OdooService');
        developer.log('Response completa: ${response.body}', name: 'OdooService');
        throw Exception('Error HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      // Primero intentar extraer el UID
      final match = RegExp(r'<int>(\d+)</int>').firstMatch(response.body);
      if (match == null) {
        developer.log('❌ Error: No se pudo extraer UID de la respuesta', name: 'OdooService');
        developer.log('Response completa: ${response.body}', name: 'OdooService');
        
        // Si no hay UID, AHORA sí verificar si es un fault
        if (response.body.contains('<fault>')) {
          developer.log('⚠️ La respuesta contiene un FAULT de Odoo', name: 'OdooService');
          final errorMsg = _extractFaultString(response.body);
          throw Exception('Autenticación fallida: $errorMsg');
        }
        
        throw Exception('Error de autenticación: No se encontró UID en la respuesta');
      }
      
      final uid = int.parse(match.group(1)!);
      developer.log('✅ Autenticación exitosa - UID: $uid', name: 'OdooService');
      
      // Extraer el session_id de las cookies
      final rawCookie = response.headers['set-cookie'];
      String? sessionId;
      if (rawCookie != null) {
        final cookie = rawCookie.split(';').firstWhere((c) => c.trim().startsWith('session_id='), orElse: () => '');
        if (cookie.isNotEmpty) {
          sessionId = cookie.split('=')[1];
        }
      }

      if (sessionId == null) {
        throw Exception('Error: No se pudo encontrar session_id en la respuesta');
      }

      developer.log('🔑 Session ID: $sessionId', name: 'OdooService');

      return {'uid': uid, 'session_id': sessionId};
      
    } catch (e) {
      developer.log('❌ EXCEPCIÓN en authenticate: $e', name: 'OdooService');
      developer.log('Tipo de error: ${e.runtimeType}', name: 'OdooService');
      rethrow;
    }
  }

  // ✅ NUEVO: Extraer mensaje de error de un fault
  String _extractFaultString(String xml) {
    final match = RegExp(r'<name>faultString</name>\s*<value><string>(.*?)</string>', dotAll: true).firstMatch(xml);
    if (match != null) {
      return match.group(1) ?? 'Error desconocido';
    }
    return 'Error desconocido';
  }

  // Obtener clientes
  Future<List<Map<String, dynamic>>> fetchClientes({
    required String url,
    required String db,
    required int userId,
    required String sessionId,
  }) async {
    developer.log('📡 Obteniendo clientes de Odoo...', name: 'OdooService');
    developer.log('URL: $url/xmlrpc/2/object', name: 'OdooService');
    developer.log('DB: $db, UID: $userId', name: 'OdooService');
    
    final uri = Uri.parse('$url/xmlrpc/2/object');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'text/xml',
        'Cookie': 'session_id=$sessionId', 
      },
      body: '''<?xml version="1.0"?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>$db</string></value></param>
    <param><value><int>$userId</int></value></param>
    <param><value><string></string></value></param> <!-- Password is now empty -->
    <param><value><string>res.partner</string></value></param>
    <param><value><string>search_read</string></value></param>
    <param>
      <value><array><data><value><array><data><value><array><data>
        <value><string>customer_rank</string></value>
        <value><string>&gt;</string></value>
        <value><int>0</int></value>
      </data></array></value></data></array></value></data></array></value>
    </param>
    <param>
      <value><struct>
        <member><name>fields</name><value><array><data>
          <value><string>id</string></value>
          <value><string>name</string></value>
          <value><string>email</string></value>
          <value><string>phone</string></value>
          <value><string>city</string></value>
        </data></array></value></member>
        <member><name>limit</name><value><int>200</int></value></member>
      </struct></value>
    </param>
  </params>
</methodCall>''',
    );

    developer.log('📥 Status code: ${response.statusCode}', name: 'OdooService');
    
    if (response.statusCode != 200) {
      developer.log('❌ Error HTTP ${response.statusCode}', name: 'OdooService');
      developer.log('Response: ${response.body}', name: 'OdooService');
      throw Exception('Error HTTP ${response.statusCode}');
    }
    
    // ✅ CRÍTICO: Verificar si la respuesta es un error ANTES de parsear
    if (response.body.contains('<fault>')) {
      developer.log('❌ Odoo devolvió un error (fault)', name: 'OdooService');
      developer.log('Response completa: ${response.body}', name: 'OdooService');
      
      final errorMsg = _extractFaultString(response.body);
      developer.log('❌ Mensaje de error: $errorMsg', name: 'OdooService');
      
      // Lanzar excepción con el mensaje de error
      throw Exception('Error de Odoo: $errorMsg');
    }
    
    developer.log('📥 Response recibida (primeros 1000 chars):', name: 'OdooService');
    developer.log(response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length), name: 'OdooService');
    
    final clientes = _parseXmlClientes(response.body);
    developer.log('✅ Clientes parseados: ${clientes.length}', name: 'OdooService');
    
    if (clientes.isNotEmpty) {
      developer.log('📋 Primer cliente de ejemplo:', name: 'OdooService');
      developer.log(clientes.first.toString(), name: 'OdooService');
    } else {
      developer.log('⚠️ No se encontraron clientes', name: 'OdooService');
    }
    
    return clientes;
  }

  // Crear cliente en Odoo
  Future<int> createCliente({
    required String url,
    required String db,
    required int userId,
    required String sessionId,
    required Map<String, dynamic> data,
  }) async {
    developer.log('➕ Creando cliente en Odoo: ${data['name']}', name: 'OdooService');
    
    final uri = Uri.parse('$url/xmlrpc/2/object');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'text/xml',
        'Cookie': 'session_id=$sessionId',
      },
      body: '''<?xml version="1.0"?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>$db</string></value></param>
    <param><value><int>$userId</int></value></param>
    <param><value><string></string></value></param>
    <param><value><string>res.partner</string></value></param>
    <param><value><string>create</string></value></param>
    <param><value><array><data><value><struct>
      <member><name>name</name><value><string>${_escape(data['name'])}</string></value></member>
      ${data['email'] != null ? '<member><name>email</name><value><string>${_escape(data['email'])}</string></value></member>' : ''}
      ${data['phone'] != null ? '<member><name>phone</name><value><string>${_escape(data['phone'])}</string></value></member>' : ''}
      ${data['city'] != null ? '<member><name>city</name><value><string>${_escape(data['city'])}</string></value></member>' : ''}
    </struct></value></data></array></value></param>
  </params>
</methodCall>''',
    );

    developer.log('📥 Response: ${response.body}', name: 'OdooService');

    // ✅ Verificar errores
    if (response.body.contains('<fault>')) {
      final errorMsg = _extractFaultString(response.body);
      developer.log('❌ Error creando cliente: $errorMsg', name: 'OdooService');
      throw Exception('Error creando cliente: $errorMsg');
    }

    final match = RegExp(r'<int>(\d+)</int>').firstMatch(response.body);
    if (match == null) {
      developer.log('❌ Error creando cliente - No se encontró ID', name: 'OdooService');
      throw Exception('Error creando cliente: No se encontró ID en la respuesta');
    }
    
    final newId = int.parse(match.group(1)!);
    developer.log('✅ Cliente creado con ID: $newId', name: 'OdooService');
    return newId;
  }

  // Actualizar cliente
  Future<void> updateCliente({
    required String url,
    required String db,
    required int userId,
    required String sessionId,
    required int odooId,
    required Map<String, dynamic> data,
  }) async {
    developer.log('✏️ Actualizando cliente Odoo ID: $odooId', name: 'OdooService');
    
    final uri = Uri.parse('$url/xmlrpc/2/object');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'text/xml',
        'Cookie': 'session_id=$sessionId',
      },
      body: '''<?xml version="1.0"?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>$db</string></value></param>
    <param><value><int>$userId</int></value></param>
    <param><value><string></string></value></param>
    <param><value><string>res.partner</string></value></param>
    <param><value><string>write</string></value></param>
    <param><value><array><data>
      <value><array><data><value><int>$odooId</int></value></data></array></value>
      <value><struct>
        <member><name>name</name><value><string>${_escape(data['name'])}</string></value></member>
        ${data['email'] != null ? '<member><name>email</name><value><string>${_escape(data['email'])}</string></value></member>' : ''}
        ${data['phone'] != null ? '<member><name>phone</name><value><string>${_escape(data['phone'])}</string></value></member>' : ''}
        ${data['city'] != null ? '<member><name>city</name><value><string>${_escape(data['city'])}</string></value></member>' : ''}
      </struct></value>
    </data></array></value></param>
  </params>
</methodCall>''',
    );
    
    developer.log('📥 Response: ${response.body}', name: 'OdooService');
    
    // ✅ Verificar errores
    if (response.body.contains('<fault>')) {
      final errorMsg = _extractFaultString(response.body);
      developer.log('❌ Error actualizando cliente: $errorMsg', name: 'OdooService');
      throw Exception('Error actualizando cliente: $errorMsg');
    }
    
    developer.log('✅ Cliente actualizado', name: 'OdooService');
  }

  // Eliminar cliente
  Future<void> deleteCliente({
    required String url,
    required String db,
    required int userId,
    required String sessionId,
    required int odooId,
  }) async {
    developer.log('🗑️ Eliminando cliente Odoo ID: $odooId', name: 'OdooService');
    
    final uri = Uri.parse('$url/xmlrpc/2/object');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'text/xml',
        'Cookie': 'session_id=$sessionId',
      },
      body: '''<?xml version="1.0"?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>$db</string></value></param>
    <param><value><int>$userId</int></value></param>
    <param><value><string></string></value></param>
    <param><value><string>res.partner</string></value></param>
    <param><value><string>unlink</string></value></param>
    <param><value><array><data><value><array><data>
      <value><int>$odooId</int></value>
    </data></array></value></data></array></value></param>
  </params>
</methodCall>''',
    );
    
    developer.log('📥 Response: ${response.body}', name: 'OdooService');
    
    // ✅ Verificar errores
    if (response.body.contains('<fault>')) {
      final errorMsg = _extractFaultString(response.body);
      developer.log('❌ Error eliminando cliente: $errorMsg', name: 'OdooService');
      throw Exception('Error eliminando cliente: $errorMsg');
    }
    
    developer.log('✅ Cliente eliminado', name: 'OdooService');
  }

  String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  List<Map<String, dynamic>> _parseXmlClientes(String xml) {
    developer.log('🔍 Parseando XML de clientes...', name: 'OdooService');
    
    final result = <Map<String, dynamic>>[];
    final structRegex = RegExp(r'<struct>(.*?)</struct>', dotAll: true);
    final structs = structRegex.allMatches(xml);

    developer.log('📊 Structs encontrados: ${structs.length}', name: 'OdooService');

    for (final struct in structs) {
      final cliente = <String, dynamic>{};
      final memberRegex = RegExp(
        r'<member>\s*<name>(.*?)</name>\s*<value>(?:<string>(.*?)</string>|<int>(.*?)</int>)',
        dotAll: true,
      );
      final members = memberRegex.allMatches(struct.group(1)!);
      
      developer.log('  🔸 Members en struct: ${members.length}', name: 'OdooService');
      
      for (final m in members) {
        final key = m.group(1)!;
        final stringVal = m.group(2);
        final intVal = m.group(3);
        
        if (intVal != null) {
          cliente[key] = int.parse(intVal);
          developer.log('    - $key: $intVal (int)', name: 'OdooService');
        } else if (stringVal != null && stringVal.isNotEmpty) {
          cliente[key] = stringVal;
          developer.log('    - $key: $stringVal (string)', name: 'OdooService');
        }
      }
      
      // ✅ IMPORTANTE: Solo agregar si tiene un ID válido (es un cliente real, no un error)
      if (cliente.isNotEmpty && cliente.containsKey('id')) {
        developer.log('  ✅ Cliente parseado: $cliente', name: 'OdooService');
        result.add(cliente);
      } else {
        developer.log('  ⚠️ Struct ignorado (no es un cliente válido): $cliente', name: 'OdooService');
      }
    }
    
    developer.log('✅ Total clientes parseados: ${result.length}', name: 'OdooService');
    return result;
  }
}
