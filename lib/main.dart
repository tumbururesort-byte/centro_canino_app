import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odoo Clientes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const OdooClientesPage(),
    );
  }
}

class OdooClientesPage extends StatefulWidget {
  const OdooClientesPage({Key? key}) : super(key: key);

  @override
  State<OdooClientesPage> createState() => _OdooClientesPageState();
}

class _OdooClientesPageState extends State<OdooClientesPage> {
  final _urlController = TextEditingController(text: 'https://tumburu.es');
  final _dbController = TextEditingController(text: 'betat1');
  final _usernameController = TextEditingController(text: 'duvalsoft@gmail.com');
  final _passwordController = TextEditingController();
  
  List<dynamic> clientes = [];
  bool isLoading = false;
  String? error;
  int? userId;

  @override
  void dispose() {
    _urlController.dispose();
    _dbController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> authenticate() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final url = Uri.parse('${_urlController.text}/xmlrpc/2/common');
      
      // Llamada XML-RPC para autenticar (sin user_agent_env para evitar conflicto con website)
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'text/xml',
        },
        body: '''<?xml version="1.0"?>
<methodCall>
  <methodName>login</methodName>
  <params>
    <param><value><string>${_dbController.text}</string></value></param>
    <param><value><string>${_usernameController.text}</string></value></param>
    <param><value><string>${_passwordController.text}</string></value></param>
  </params>
</methodCall>''',
      );

      print('Status autenticación: ${response.statusCode}');
      print('Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        // Parsear respuesta XML
        final uidMatch = RegExp(r'<int>(\d+)</int>').firstMatch(response.body);
        
        if (uidMatch != null) {
          final uid = int.parse(uidMatch.group(1)!);
          
          if (uid > 0) {
            setState(() {
              userId = uid;
            });
            
            await fetchClientes();
          } else {
            throw Exception('Autenticación fallida: credenciales incorrectas');
          }
        } else {
          // Verificar si hay un fault (error)
          if (response.body.contains('<fault>')) {
            throw Exception('Error de autenticación. Verifica tus credenciales.');
          }
          throw Exception('Respuesta inesperada del servidor');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> fetchClientes() async {
    try {
      final url = Uri.parse('${_urlController.text}/xmlrpc/2/object');
      
      // Llamada XML-RPC para buscar clientes
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'text/xml',
        },
        body: '''<?xml version="1.0"?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>${_dbController.text}</string></value></param>
    <param><value><int>$userId</int></value></param>
    <param><value><string>${_passwordController.text}</string></value></param>
    <param><value><string>res.partner</string></value></param>
    <param><value><string>search_read</string></value></param>
    <param>
      <value>
        <array>
          <data>
            <value>
              <array>
                <data>
                  <value>
                    <array>
                      <data>
                        <value><string>customer_rank</string></value>
                        <value><string>&gt;</string></value>
                        <value><int>0</int></value>
                      </data>
                    </array>
                  </value>
                </data>
              </array>
            </value>
          </data>
        </array>
      </value>
    </param>
    <param>
      <value>
        <struct>
          <member>
            <name>fields</name>
            <value>
              <array>
                <data>
                  <value><string>name</string></value>
                  <value><string>email</string></value>
                  <value><string>phone</string></value>
                  <value><string>city</string></value>
                </data>
              </array>
            </value>
          </member>
          <member>
            <name>limit</name>
            <value><int>50</int></value>
          </member>
        </struct>
      </value>
    </param>
  </params>
</methodCall>''',
      );

      print('Respuesta status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parsear XML manualmente para extraer los clientes
        final clientesList = _parseXmlClientes(response.body);
        
        setState(() {
          clientes = clientesList;
          isLoading = false;
        });
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _parseXmlClientes(String xml) {
    final List<Map<String, dynamic>> result = [];
    
    // Extraer cada struct que representa un cliente
    final structRegex = RegExp(r'<struct>(.*?)</struct>', dotAll: true);
    final structs = structRegex.allMatches(xml);
    
    for (var structMatch in structs) {
      final structContent = structMatch.group(1)!;
      final Map<String, dynamic> cliente = {};
      
      // Extraer cada member (campo)
      final memberRegex = RegExp(
        r'<member>\s*<name>(.*?)</name>\s*<value>(?:<string>(.*?)</string>|<int>(.*?)</int>|<boolean>(.*?)</boolean>)',
        dotAll: true,
      );
      
      final members = memberRegex.allMatches(structContent);
      
      for (var member in members) {
        final name = member.group(1)!;
        final stringValue = member.group(2);
        final intValue = member.group(3);
        final boolValue = member.group(4);
        
        if (stringValue != null) {
          cliente[name] = stringValue;
        } else if (intValue != null) {
          cliente[name] = int.parse(intValue);
        } else if (boolValue != null) {
          cliente[name] = boolValue == '1';
        }
      }
      
      if (cliente.isNotEmpty) {
        result.add(cliente);
      }
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odoo - Clientes'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (userId == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conexión Odoo (XML-RPC)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL de Odoo',
                          hintText: 'https://tu-instancia.odoo.com',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dbController,
                        decoration: const InputDecoration(
                          labelText: 'Base de datos',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => authenticate(),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isLoading ? null : authenticate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Conectar'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Conectado (User ID: $userId)'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            userId = null;
                            clientes = [];
                          });
                        },
                        child: const Text('Desconectar'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (clientes.isNotEmpty) ...[
                Text(
                  'Clientes (${clientes.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...clientes.map((cliente) {
                  final name = cliente['name'] ?? 'Sin nombre';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      ),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cliente['email'] != null && cliente['email'] != false)
                            Text('📧 ${cliente['email']}'),
                          if (cliente['phone'] != null && cliente['phone'] != false)
                            Text('📞 ${cliente['phone']}'),
                          if (cliente['city'] != null && cliente['city'] != false)
                            Text('📍 ${cliente['city']}'),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              ] else ...[
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No se encontraron clientes'),
                  ),
                ),
              ],
            ],
            if (error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(error!),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}