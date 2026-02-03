
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

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
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          _buildHeader(colorScheme, theme.textTheme),
                          const SizedBox(height: 30),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildCustomTextField(controller: _urlController, labelText: 'URL DEL SERVIDOR', icon: Icons.link_rounded, validator: (v) => v!.isEmpty ? 'La URL no puede estar vacía' : null, colorScheme: colorScheme, textTheme: theme.textTheme, keyboardType: TextInputType.url),
                                const SizedBox(height: 20),
                                _buildCustomTextField(controller: _dbController, labelText: 'BASE DE DATOS', icon: Icons.storage_rounded, validator: (v) => v!.isEmpty ? 'La base de datos no puede estar vacía' : null, colorScheme: colorScheme, textTheme: theme.textTheme),
                                const SizedBox(height: 20),
                                _buildCustomTextField(controller: _emailController, labelText: 'CORREO ELECTRÓNICO', icon: Icons.email_outlined, validator: (v) => v!.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v) ? 'Formato de correo no válido' : null, colorScheme: colorScheme, textTheme: theme.textTheme, keyboardType: TextInputType.emailAddress),
                                const SizedBox(height: 20),
                                _buildCustomTextField(controller: _passwordController, labelText: 'CONTRASEÑA', icon: Icons.lock_outline_rounded, isPassword: true, validator: (v) => v!.isEmpty ? 'La contraseña no puede estar vacía' : null, colorScheme: colorScheme, textTheme: theme.textTheme),
                              ],
                            ),
                          ),
                          const Spacer(flex: 3),
                          _buildConnectButton(colorScheme, theme.textTheme),
                          const SizedBox(height: 12),
                          _buildForgotPasswordLink(theme.textTheme, colorScheme),
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

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface.withAlpha(128),
            boxShadow: [BoxShadow(color: colorScheme.primary.withAlpha(77), blurRadius: 10, spreadRadius: 2)],
            border: Border.all(color: colorScheme.onSurface.withAlpha(26), width: 2),
          ),
          child: Icon(Icons.pets, color: colorScheme.primary, size: 50),
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            Text('Tumburú', style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Container(
              width: 50,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        Text('Conecta con tu cuenta para continuar', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withAlpha(178))),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    bool isPassword = false,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(178), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscureText : false,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onFieldSubmitted: (_) => _login(),
        ),
      ],
    );
  }

  Widget _buildConnectButton(ColorScheme colorScheme, TextTheme textTheme) {
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
            gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary], begin: Alignment.centerLeft, end: Alignment.centerRight),
            boxShadow: [BoxShadow(color: colorScheme.primary.withAlpha(102), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: _isLoading
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: colorScheme.onPrimary))
                : Text('CONECTAR', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink(TextTheme textTheme, ColorScheme colorScheme) {
    return TextButton(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función no implementada todavía.'))),
      child: Text('¿Olvidaste tu contraseña?', style: textTheme.bodyMedium),
    );
  }
}
