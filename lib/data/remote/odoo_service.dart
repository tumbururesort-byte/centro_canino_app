import 'package:http/http.dart' as http;

class OdooService {
  // Autenticar
  Future<int> authenticate({
    required String url,
    required String db,
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$url/xmlrpc/2/common');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'text/xml'},
      body: '''<?xml version="1.0"?>
<methodCall>
  <methodName>authenticate</methodName>
  <params>
    <param><value><string>$db</string></value></param>
    <param><value><string>$username</string></value></param>
    <param><value><string>$password</string></value></param>
    <param><value><struct></struct></value></param>
  </params>
</methodCall>''',
    );

    final match = RegExp(r'<int>(\d+)</int>').firstMatch(response.body);
    if (match == null) throw Exception('Error de autenticación');
    return int.parse(match.group(1)!);
  }

  // Obtener clientes
  Future<List<Map<String, dynamic>>> fetchClientes({
    required String url,
    required String db,
    required int userId,
    required String password,
  }) async {
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

    if (response.statusCode != 200) {
      throw Exception('Error HTTP ${response.statusCode}');
    }
    return _parseXmlClientes(response.body);
  }

  // Crear cliente en Odoo
  Future<int> createCliente({
    required String url,
    required String db,
    required int userId,
    required String password,
    required Map<String, dynamic> data,
  }) async {
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

    final match = RegExp(r'<int>(\d+)</int>').firstMatch(response.body);
    if (match == null) throw Exception('Error creando cliente');
    return int.parse(match.group(1)!);
  }

  // Actualizar cliente
  Future<void> updateCliente({
    required String url,
    required String db,
    required int userId,
    required String password,
    required int odooId,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('$url/xmlrpc/2/object');
    await http.post(
      uri,
      headers: {'Content-Type': 'text/xml'},
      body: '''<?xml version="1.0"?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>$db</string></value></param>
    <param><value><int>$userId</int></value></param>
    <param><value><string>$password</string></value></param>
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
  }

  // Eliminar cliente
  Future<void> deleteCliente({
    required String url,
    required String db,
    required int userId,
    required String password,
    required int odooId,
  }) async {
    final uri = Uri.parse('$url/xmlrpc/2/object');
    await http.post(
      uri,
      headers: {'Content-Type': 'text/xml'},
      body: '''<?xml version="1.0"?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>$db</string></value></param>
    <param><value><int>$userId</int></value></param>
    <param><value><string>$password</string></value></param>
    <param><value><string>res.partner</string></value></param>
    <param><value><string>unlink</string></value></param>
    <param><value><array><data><value><array><data>
      <value><int>$odooId</int></value>
    </data></array></value></data></array></value></param>
  </params>
</methodCall>''',
    );
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
    final result = <Map<String, dynamic>>[];
    final structRegex = RegExp(r'<struct>(.*?)</struct>', dotAll: true);
    final structs = structRegex.allMatches(xml);

    for (final struct in structs) {
      final cliente = <String, dynamic>{};
      final memberRegex = RegExp(
        r'<member>\s*<name>(.*?)</name>\s*<value>(?:<string>(.*?)</string>|<int>(.*?)</int>)',
        dotAll: true,
      );
      for (final m in memberRegex.allMatches(struct.group(1)!)) {
        final key = m.group(1)!;
        final stringVal = m.group(2);
        final intVal = m.group(3);
        
        if (intVal != null) {
          cliente[key] = int.parse(intVal);
        } else if (stringVal != null && stringVal.isNotEmpty) {
          cliente[key] = stringVal;
        }
      }
      if (cliente.isNotEmpty) result.add(cliente);
    }
    return result;
  }
}