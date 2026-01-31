import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();

    try {
      final odooService = OdooService(
        serverUrl: _url.text.trim(),
        dbName: _db.text.trim(),
      );

      await odooService.authenticate(
        _user.text.trim(),
        _pass.text,
      );
      
      authProvider.login(odooService);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_sync_rounded,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              Text(
                'Conectar a Odoo',
                style: GoogleFonts.oswald(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión para sincronizar tus datos',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildTextField(_url, 'URL del Servidor', Icons.dns_rounded),
              const SizedBox(height: 16),
              _buildTextField(_db, 'Nombre de la Base de Datos', Icons.storage_rounded),
              const SizedBox(height: 16),
              _buildTextField(_user, 'Correo Electrónico', Icons.email_rounded),
              const SizedBox(height: 16),
              _buildTextField(_pass, 'Contraseña', Icons.lock_rounded, obscureText: true),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login_rounded),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                  onPressed: _loading ? null : _login,
                  label: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
                        )
                      : const Text('CONECTAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        // Usamos el color recomendado por Material 3 para superficies de contenedores
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      onSubmitted: (_) {
        if (!_loading) _login();
      },
    );
  }
}
