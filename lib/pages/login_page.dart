import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController(text: 'https://tumburu.es');
  final _dbController = TextEditingController(text: 'betat1');
  final _emailController = TextEditingController(text: 'duvalsoft@gmail.com');
  final _passwordController = TextEditingController(text: 'Odi1@99TU');

  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final success = await authProvider.login(
        _urlController.text.trim(),
        _dbController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!success) {
        throw 'Credenciales incorrectas o error del servidor.';
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: ${e.toString()}'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _dbController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          _buildHeader(),
                          const SizedBox(height: 30),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildCustomTextField(
                                  controller: _urlController,
                                  labelText: 'URL DEL SERVIDOR',
                                  icon: Icons.link_rounded,
                                  keyboardType: TextInputType.url,
                                  validator: (value) =>
                                      value!.isEmpty ? 'La URL no puede estar vacía' : null,
                                ),
                                const SizedBox(height: 20),
                                _buildCustomTextField(
                                  controller: _dbController,
                                  labelText: 'BASE DE DATOS',
                                  icon: Icons.storage_rounded,
                                  validator: (value) =>
                                      value!.isEmpty ? 'La base de datos no puede estar vacía' : null,
                                ),
                                const SizedBox(height: 20),
                                _buildCustomTextField(
                                  controller: _emailController,
                                  labelText: 'CORREO ELECTRÓNICO',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value!.isEmpty) return 'El correo no puede estar vacío';
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Formato de correo no válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildCustomTextField(
                                  controller: _passwordController,
                                  labelText: 'CONTRASEÑA',
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  validator: (value) =>
                                      value!.isEmpty ? 'La contraseña no puede estar vacía' : null,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(flex: 3),
                          _buildConnectButton(),
                          const SizedBox(height: 12),
                          _buildForgotPasswordLink(),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF37B67).withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white12, width: 2),
          ),
          child: const Icon(
            Icons.pets,
            color: Color(0xFFF37B67),
            size: 50,
          ),
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            Text(
              'Tumburú',
              style: GoogleFonts.heebo(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 50,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF37B67), Color(0xFFE84C88)],
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Conecta con tu cuenta para continuar',
          style: GoogleFonts.heebo(
            fontSize: 16,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: GoogleFonts.heebo(
            color: Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscureText : false,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF37B67), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onFieldSubmitted: (_) => _login(),
        ),
      ],
    );
  }

  Widget _buildConnectButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _login,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFFF37B67), Color(0xFFE84C88)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF37B67).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                  )
                : Text(
                    'CONECTAR',
                    style: GoogleFonts.heebo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Función no implementada todavía.')),
        );
      },
      child: Text(
        '¿Olvidaste tu contraseña?',
        style: GoogleFonts.heebo(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
