
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/providers/clientes_provider.dart';

class ClienteEditPage extends StatefulWidget {
  final Cliente? cliente;

  const ClienteEditPage({super.key, this.cliente});

  @override
  State<ClienteEditPage> createState() => _ClienteEditPageState();
}

class _ClienteEditPageState extends State<ClienteEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;

  bool get _isEditing => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cliente?.name ?? '');
    _emailController = TextEditingController(text: widget.cliente?.email ?? '');
    _phoneController = TextEditingController(text: widget.cliente?.phone ?? '');
    _cityController = TextEditingController(text: widget.cliente?.city ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ClientesProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);

    try {
      if (_isEditing) {
        final updatedCliente = widget.cliente!.copyWith(
          name: _nameController.text.trim(),
          email: Value(_emailController.text.trim()),
          phone: Value(_phoneController.text.trim()),
          city: Value(_cityController.text.trim()),
        );
        await provider.updateCliente(updatedCliente);
      } else {
        await provider.createCliente(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _phoneController.text.trim(),
          _cityController.text.trim(),
        );
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Cliente actualizado' : 'Cliente creado'),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
      navigator.pop();

    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar cliente' : 'Nuevo cliente'),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildProfileHeader(colorScheme, theme.textTheme),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _nameController,
                labelText: 'Nombre completo',
                hintText: 'Juan García López',
                icon: Icons.person_outline_rounded,
                validator: (value) => (value == null || value.isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 25),
              _buildTextField(
                controller: _phoneController,
                labelText: 'Teléfono',
                hintText: '+34 623 377 364',
                icon: Icons.smartphone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 25),
              _buildTextField(
                controller: _emailController,
                labelText: 'Correo electrónico',
                hintText: 'juan.garcia@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 25),
              _buildTextField(
                controller: _cityController,
                labelText: 'Ciudad',
                hintText: 'Madrid, España',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveCliente,
        elevation: 4,
        child: const Icon(Icons.check_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: colorScheme.surface.withOpacity(0.5),
            child: Icon(
              Icons.person_outline_rounded,
              size: 45,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            child: Text(
              'Cambiar foto',
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            labelText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
