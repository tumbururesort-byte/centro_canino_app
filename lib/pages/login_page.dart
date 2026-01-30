import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../data/remote/odoo_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _url = TextEditingController(text: 'https://tumburu.es');
  final _db = TextEditingController(text: 'betat1');
  final _user = TextEditingController(text: 'duvalsoft@gmail.com');
  final _pass = TextEditingController(text: 'Odi1@99TU');
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();

    try {
      debugPrint('🔑 Iniciando login...');

      final odooService = OdooService(
        serverUrl: _url.text.trim(),
        dbName: _db.text.trim(),
      );

      await odooService.authenticate(
        _user.text.trim(),
        _pass.text,
      );
      
      debugPrint('✅ Login exitoso - UID: \${odooService.uid}');

      authProvider.login(odooService);

    } catch (e, stackTrace) {
      debugPrint('❌ Error en login: $e');
      debugPrint('Stack: $stackTrace');

      setState(() {
        error = 'Error de conexión: \${e.toString()}';
        loading = false;
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: \${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de Sesión'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Configuración Odoo',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _url,
                      decoration: const InputDecoration(
                          labelText: 'URL', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _db,
                      decoration: const InputDecoration(
                          labelText: 'Base de datos',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _user,
                      decoration: const InputDecoration(
                          labelText: 'Usuario',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder()),
                    onSubmitted: (_) => login(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)
                        )
                      ),
                      onPressed: loading ? null : login,
                      child: loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(strokeWidth: 3, color: Colors.white,))
                          : const Text('Conectar'),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
