import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'data/local/app_database.dart';
import 'data/clientes_repository.dart';
import 'data/remote/odoo_service.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MaterialApp(
      title: 'Clientes Offline-First',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(textTheme),
      ),
      home: const OdooClientesPage(),
    );
  }
}

class OdooClientesPage extends StatefulWidget {
  const OdooClientesPage({super.key});

  @override
  State<OdooClientesPage> createState() => _OdooClientesPageState();
}

class _OdooClientesPageState extends State<OdooClientesPage> {
  final _url = TextEditingController(text: 'https://tumburu.es');
  final _db = TextEditingController(text: 'betat1');
  final _user = TextEditingController(text: 'duvalsoft@gmail.com');
  final _pass = TextEditingController(text: 'Odi1@99TU');
  bool loading = false;
  bool syncing = false;
  String? error;
  List<Cliente> clientes = [];
  DateTime? lastSync;

  late ClientesRepository repo;

  @override
  void initState() {
    super.initState();
    // El repositorio ahora solo necesita la base de datos
    repo = ClientesRepository(AppDatabase());
    // Cargamos clientes locales al iniciar
    _loadLocalClientes();
  }

  Future<void> _loadLocalClientes() async {
    try {
      debugPrint('🔄 Cargando clientes locales...');
      final local = await repo.getClientesOffline();
      debugPrint('✅ Clientes cargados: ${local.length}');
      if (mounted) {
        setState(() => clientes = local);
      }
    } catch (e) {
      debugPrint('❌ Error cargando clientes: $e');
      if (mounted) {
        setState(() => error = 'Error cargando clientes: $e');
      }
    }
  }

  // NUEVO FLUJO DE LOGIN
  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();

    try {
      debugPrint('🔑 Iniciando login...');

      // 1. Crear instancia del servicio
      final odooService = OdooService(
        serverUrl: _url.text.trim(),
        dbName: _db.text.trim(),
      );

      // 2. Autenticar
      await odooService.authenticate(
        _user.text.trim(),
        _pass.text,
      );
      
      debugPrint('✅ Login exitoso - UID: ${odooService.uid}');

      // 3. Guardar el servicio completo en el provider
      authProvider.login(odooService);

      // 4. Iniciar sincronización
      await _syncClientes();

    } catch (e, stackTrace) {
      debugPrint('❌ Error en login: $e');
      debugPrint('Stack: $stackTrace');

      setState(() {
        error = 'Error de conexión: ${e.toString()}';
        loading = false;
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } 
  }

  // NUEVO FLUJO DE SINCRONIZACIÓN
  Future<void> _syncClientes() async {
    setState(() {
      syncing = true;
      error = null;
    });

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (!authProvider.isLoggedIn) {
      setState(() => syncing = false);
      return;
    }

    try {
      debugPrint('🔄 Iniciando sincronización con UID: ${authProvider.uid}');
      
      // Pasar el servicio autenticado al repositorio
      await repo.syncClientes(remote: authProvider.odooService!); 

      debugPrint('✅ Sincronización completada');
      setState(() => lastSync = DateTime.now());

      await _loadLocalClientes();

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Sincronización completada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error sincronizando: $e');
      debugPrint('Stack trace: $stackTrace');
      // ... (el resto del manejo de errores es igual)
      setState(() => error = e.toString());
    } finally {
      setState(() {
        syncing = false;
        loading = false;
      });
    }
  }

  // El resto de la UI y la lógica de dialogs no necesitan cambios significativos,
  // ya que operan sobre el `repo` local, y la sincronización se encarga del resto.

  // ... [El resto de la clase _OdooClientesPageState sin cambios] ...
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
                } catch (e) {
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
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final pendingCount = clientes.where((c) => c.pendingSync).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clientes Offline-First'),
            if (lastSync != null)
              Text('Última sync: ${_formatTime(lastSync!)}',
                  style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Chip(
                  label: Text('$pendingCount pendientes'),
                  backgroundColor: Colors.orange),
            ),
          if (authProvider.isLoggedIn)
            IconButton(
              icon: syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync),
              onPressed: syncing ? null : _syncClientes,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!authProvider.isLoggedIn) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Configuración Odoo',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                          controller: _url,
                          decoration: const InputDecoration(
                              labelText: 'URL', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(
                          controller: _db,
                          decoration: const InputDecoration(
                              labelText: 'Base de datos',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(
                          controller: _user,
                          decoration: const InputDecoration(
                              labelText: 'Usuario',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pass,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder()),
                        onSubmitted: (_) => login(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : login,
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Conectar y Sincronizar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.cloud_done, color: Colors.green),
                  title: Text('Conectado (UID: ${authProvider.uid})'),
                  trailing: TextButton(
                      onPressed: () {
                        context.read<AuthProvider>().logout();
                        setState(() {
                          clientes = [];
                          lastSync = null;
                        });
                      },
                      child: const Text('Desconectar')),
                ),
              ),
            ],
            if (error != null)
              Card(
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
            const SizedBox(height: 16),
            Expanded(
              child: clientes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No hay clientes',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Text(
                            !authProvider.isLoggedIn
                                ? 'Conecta para sincronizar\no crea uno nuevo'
                                : 'Sincroniza para cargar clientes\no crea uno nuevo',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: clientes.length,
                      itemBuilder: (context, i) {
                        final c = clientes[i];
                        return Card(
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
                                      : Colors.blue,
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
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      if (c.email != null)
                                        Text('📧 ${c.email}',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      if (c.phone != null)
                                        Text('📞 ${c.phone}',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      if (c.city != null)
                                        Text('📍 ${c.city}',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text(
                                          'ID Local: ${c.id} | ID Odoo: ${c.odooId ?? "pendiente"}',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade700,
                                              fontFamily: 'monospace'),
                                        ),
                                      ),
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _showClienteDialog(), child: const Icon(Icons.add)),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'hace ${diff.inSeconds}s';
    if (diff.inHours < 1) return 'hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }
}
