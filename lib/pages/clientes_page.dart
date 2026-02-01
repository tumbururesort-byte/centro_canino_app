
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/providers/clientes_provider.dart';
import 'package:myapp/providers/navigation_provider.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ClientesView();
  }
}

class _ClientesView extends StatefulWidget {
  const _ClientesView();

  @override
  State<_ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<_ClientesView> {
  Timer? _messageTimer;

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<void> _showClienteDialog({Cliente? cliente}) async {
    if (!mounted) return;

    final nameController = TextEditingController(text: cliente?.name);
    final emailController = TextEditingController(text: cliente?.email);
    final phoneController = TextEditingController(text: cliente?.phone);
    final cityController = TextEditingController(text: cliente?.city);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<ClientesProvider>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(cliente == null ? 'Nuevo Cliente' : 'Editar Cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre *')),
                const SizedBox(height: 8),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Teléfono')),
                const SizedBox(height: 8),
                TextField(controller: cityController, decoration: const InputDecoration(labelText: 'Ciudad')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                
                final navigator = Navigator.of(ctx);

                try {
                  if (cliente == null) {
                    await provider.createCliente(
                      nameController.text.trim(),
                      emailController.text.trim(),
                      phoneController.text.trim(),
                      cityController.text.trim(),
                    );
                  } else {
                    final updatedCliente = cliente.copyWith(
                      name: nameController.text.trim(),
                      email: Value(emailController.text.trim()),
                      phone: Value(phoneController.text.trim()),
                      city: Value(cityController.text.trim()),
                    );
                    await provider.updateCliente(updatedCliente);
                  }
                  navigator.pop(true);
                } catch (e) {
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(cliente == null ? 'Cliente creado' : 'Cliente actualizado'),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _deleteCliente(Cliente cliente) async {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<ClientesProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('¿Eliminar "${cliente.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.deleteCliente(cliente);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Cliente eliminado')));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ClientesProvider>(
      builder: (context, provider, child) {
        final filteredClientes = _filterClientes(
            provider.clientes, 
            context.watch<NavigationProvider>().searchQuery
        );

        return Column(
          children: [
            _buildSyncStatus(provider),
            
            Expanded(
              child: provider.isLoading && provider.clientes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => provider.syncClientes(),
                      child: filteredClientes.isEmpty
                          ? _buildEmptyState(context.watch<NavigationProvider>().searchQuery)
                          : _buildClientesList(filteredClientes),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<Cliente> _filterClientes(List<Cliente> clientes, String searchQuery) {
    if (searchQuery.isEmpty) return clientes;
    final query = searchQuery.toLowerCase();
    return clientes.where((c) {
        final name = c.name.toLowerCase();
        final email = c.email?.toLowerCase() ?? '';
        final phone = c.phone?.toLowerCase() ?? '';
        return name.contains(query) || email.contains(query) || phone.contains(query);
    }).toList();
  }

  Widget _buildSyncStatus(ClientesProvider provider) {
    if (provider.syncMessage == null) {
      return const SizedBox.shrink();
    }

    final message = provider.syncMessage!;
    final isLoading = provider.isLoading;
    final isError = message.startsWith('❌');

    if (!isLoading) {
      _messageTimer?.cancel();
      _messageTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          // Implementación futura: El provider debería limpiar su propio mensaje.
        }
      });
    }
    
    return Material(
      elevation: 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: isError ? Colors.red.shade100 : Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  if (isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  if (!isLoading) Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? Colors.red : Colors.green, size: 16),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
                ],
              ),
              if (isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(String searchQuery) => ListView(
    children: [ 
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Icon(searchQuery.isEmpty ? Icons.people_outline : Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(searchQuery.isEmpty ? 'No hay clientes' : 'No se encontraron resultados', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            if (searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: () => context.read<ClientesProvider>().syncClientes(),
                icon: const Icon(Icons.sync),
                label: const Text('Sincronizar ahora'),
              )
          ],
        ),
      )
    ]
  );

  ListView _buildClientesList(List<Cliente> clientes) => ListView.builder(
    itemCount: clientes.length,
    itemBuilder: (context, i) {
      final cliente = clientes[i];
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(child: Text(cliente.name.isNotEmpty ? cliente.name[0] : '?')),
          title: Text(cliente.name),
          // --- CAMBIO PRINCIPAL AQUÍ ---
          subtitle: Text(cliente.phone?.isNotEmpty == true ? cliente.phone! : 'Sin teléfono'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.grey), onPressed: () => _showClienteDialog(cliente: cliente)),
              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), onPressed: () => _deleteCliente(cliente)),
            ],
          ),
        ),
      );
    },
  );
}
