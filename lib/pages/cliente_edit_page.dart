import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/providers/clientes_provider.dart';
import 'package:myapp/theme/app_theme.dart';

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
  int? _selectedTarifaId;

  bool get _isEditing => widget.cliente != null;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cliente?.name ?? '');
    _emailController = TextEditingController(text: widget.cliente?.email ?? '');
    _phoneController = TextEditingController(text: widget.cliente?.phone ?? '');
    _cityController = TextEditingController(text: widget.cliente?.city ?? '');
    _selectedTarifaId = widget.cliente?.tarifaId;
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
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    final provider = context.read<ClientesProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (_isEditing) {
        final updatedCliente = widget.cliente!.copyWith(
          name: _nameController.text.trim(),
          email: Value(_emailController.text.trim()),
          phone: Value(_phoneController.text.trim()),
          city: Value(_cityController.text.trim()),
          tarifaId: Value(_selectedTarifaId),
        );
        await provider.updateCliente(updatedCliente);
      } else {
        await provider.createCliente(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _phoneController.text.trim(),
          _cityController.text.trim(),
          _selectedTarifaId,
        );
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Cliente actualizado' : 'Cliente creado'),
          backgroundColor: AppColors.primary,
        ),
      );
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteCliente() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (result == true && mounted) {
      await context.read<ClientesProvider>().deleteCliente(widget.cliente!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente eliminado')));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Text(_isEditing ? 'Editar cliente' : 'Nuevo cliente', style: context.textTheme.titleLarge),
        actions: [
          if (_isEditing) IconButton(icon: const Icon(Icons.delete, color: AppColors.error), onPressed: _deleteCliente),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTextField(controller: _nameController, labelText: 'Nombre', icon: Icons.person, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              _buildTextField(controller: _phoneController, labelText: 'Teléfono', icon: Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(controller: _emailController, labelText: 'Email', icon: Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(controller: _cityController, labelText: 'Ciudad', icon: Icons.location_city),
              const SizedBox(height: 16),
              Consumer<ClientesProvider>(
                builder: (context, provider, child) {
                  return _buildTarifasDropdown(provider.tarifas);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _saveCliente,
        child: _isSaving ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)) : const Icon(Icons.check),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildTarifasDropdown(List<Tarifa> tarifas) {
    final items = tarifas.map((tarifa) {
      return DropdownMenuItem<int>(
        value: tarifa.odooId,
        child: Text(tarifa.name, overflow: TextOverflow.ellipsis),
      );
    }).toList();

    final selectedIdExists = items.any((item) => item.value == _selectedTarifaId);

    return DropdownButtonFormField<int>(
      initialValue: selectedIdExists ? _selectedTarifaId : null,
      items: items,
      onChanged: (value) => setState(() => _selectedTarifaId = value),
      decoration: InputDecoration(
        labelText: 'Tarifa',
        prefixIcon: const Icon(Icons.local_offer, size: 20),
        suffixIcon: _selectedTarifaId != null
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _selectedTarifaId = null))
            : null,
      ),
      hint: const Text('Seleccionar tarifa...'),
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }
}
