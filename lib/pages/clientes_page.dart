import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../data/local/app_database.dart';
import '../data/clientes_repository.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  bool syncing = false;
  String? error;
  List<Cliente> clientes = [];
  DateTime? lastSync;

  late ClientesRepository repo;

  @override
  void initState() {
    super.initState();
    repo = ClientesRepository(AppDatabase());
    _loadLocalClientes();
    // Registramos la acción del FAB. Le pasamos un método anónimo que llama al nuestro.
    // Lo hacemos así para poder pasarle parámetros si fuera necesario en el futuro.
    context.read<NavigationProvider>().registerFabAction(() => _showClienteDialog());
  }

  @override
  void dispose() {
    // Es MUY importante anular el registro para evitar errores y memory leaks.
    context.read<NavigationProvider>().unregisterFabAction();
    super.dispose();
  }

  Future<void> _loadLocalClientes() async {
    try {
      developer.log('Cargando clientes locales', name: 'ClientesPage');
      final local = await repo.getClientesOffline();
      if (mounted) {
        setState(() => clientes = local);
      }
    } catch (e, s) {
      developer.log('Error al cargar clientes locales', name: 'ClientesPage', error: e, stackTrace: s);
      if (mounted) {
        setState(() => error = 'Error cargando clientes: $e');
      }
    }
  }

  Future<void> _syncClientes() async {
    setState(() {
      syncing = true;
      error = null;
    });

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (!authProvider.isLoggedIn) {
      developer.log('Intento de sincronización sin estar logueado', name: 'ClientesPage', level: 800);
      setState(() => syncing = false);
      return;
    }

    try {
      developer.log('Iniciando sincronización', name: 'ClientesPage');
      await repo.syncClientes(remote: authProvider.odooService!); 
      setState(() => lastSync = DateTime.now());
      await _loadLocalClientes();

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Sincronización completada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      developer.log('Error en la sincronización', name: 'ClientesPage', error: e, stackTrace: stackTrace, level: 1000);
      String errorMessage = e.toString();
      if (errorMessage.contains('Access Denied')) {
        errorMessage = 'Acceso denegado. Por favor, revisa los permisos del usuario en Odoo.';
      } else if (errorMessage.contains('Failed host lookup')) {
        errorMessage = 'No se pudo conectar al servidor. Verifica la URL y tu conexión a internet.';
      }

      setState(() => error = errorMessage);
    } finally {
      setState(() {
        syncing = false;
      });
    }
  }

   Future<void> _showClienteDialog({Cliente? cliente}) async {
    final nameController = TextEditingController(text: cliente?.name);
    final emailController = TextEditingController(text: cliente?.email);
    final phoneController = TextEditingController(text: cliente?.phone);
    final cityController = TextEditingController(text: cliente?.city);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        return AlertDialog(
          title: Text(cliente == null ? 'Nuevo Cliente' : 'Editar Cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre *')),
                const SizedBox(height: 8),
                TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Teléfono')),
                const SizedBox(height: 8),
                TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'Ciudad')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => navigator.pop(false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('El nombre es obligatorio')),
                  );
                  return;
                }

                try {
                  if (cliente == null) {
                    await repo.createCliente(
                      nameController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      phone: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      city: cityController.text.trim().isEmpty
                          ? null
                          : cityController.text.trim(),
                    );
                  } else {
                    await repo.updateCliente(
                      cliente.id,
                      name: nameController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      phone: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      city: cityController.text.trim().isEmpty
                          ? null
                          : cityController.text.trim(),
                    );
                  }
                  navigator.pop(true);
                } catch (e,s) {
                   developer.log('Error al guardar cliente', name: 'ClientesPage', error: e, stackTrace: s);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _loadLocalClientes();
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text(
                cliente == null ? 'Cliente creado' : 'Cliente actualizado')),
      );
    }
  }

  Future<void> _deleteCliente(Cliente cliente) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('¿Eliminar "${cliente.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
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
        await repo.deleteCliente(cliente);
        await _loadLocalClientes();

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Cliente eliminado')),
        );
      } catch (e,s) {
        developer.log('Error al eliminar cliente', name: 'ClientesPage', error: e, stackTrace: s);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();
    final searchQuery = navigationProvider.searchQuery.toLowerCase();

    final List<Cliente> filteredClientes;
    if (searchQuery.isEmpty) {
      filteredClientes = clientes;
    } else {
      filteredClientes = clientes.where((c) {
        final name = c.name.toLowerCase();
        final email = c.email?.toLowerCase() ?? '';
        final phone = c.phone?.toLowerCase() ?? '';
        final city = c.city?.toLowerCase() ?? '';
        return name.contains(searchQuery) ||
               email.contains(searchQuery) ||
               phone.contains(searchQuery) || 
               city.contains(searchQuery);
      }).toList();
    }

    return Column(
      children: [
         if (error != null)
            Card(
              margin: const EdgeInsets.all(8),
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Error',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => error = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        Expanded(
          child: filteredClientes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                        size: 64, 
                        color: Colors.grey.shade400
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isEmpty ? 'No hay clientes' : 'No se encontraron resultados',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600)
                      ),
                      if (searchQuery.isEmpty)
                        ...[
                          const SizedBox(height: 8),
                          Text(
                            'Sincroniza para cargar clientes\no crea uno nuevo',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredClientes.length,
                  itemBuilder: (context, i) {
                    final c = filteredClientes[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: c.pendingSync ? Colors.orange.shade50 : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: c.pendingSync
                                  ? Colors.orange
                                  : Theme.of(context).primaryColor,
                              child: Text(c.name[0].toUpperCase(),
                                  style:
                                      const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  if (c.email != null)
                                    Text('📧 ${c.email}',
                                        style:
                                            const TextStyle(fontSize: 13, color: Colors.black54)),
                                  if (c.phone != null)
                                    Text('📞 ${c.phone}',
                                        style:
                                            const TextStyle(fontSize: 13, color: Colors.black54)),
                                  if (c.city != null)
                                    Text('📍 ${c.city}',
                                        style:
                                            const TextStyle(fontSize: 13, color: Colors.black54)),
                                  const SizedBox(height: 6),
                                   if (c.pendingSync)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                            '⏳ Pendiente de sincronización',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                ],
                              ),
                            ),
                            IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 20, color: Colors.grey),
                                onPressed: () =>
                                    _showClienteDialog(cliente: c)),
                            IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 20, color: Colors.redAccent),
                                onPressed: () => _deleteCliente(c)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
