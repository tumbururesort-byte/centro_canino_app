import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http_client;
import 'data/local/app_database.dart';
import 'data/clientes_repository.dart';
import 'data/remote/odoo_service.dart';

void main() {
  runApp(const MyApp());
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
  int? userId;
  bool loading = false;
  bool syncing = false;
  String? error;
  List<Cliente> clientes = [];
  DateTime? lastSync;

  late ClientesRepository repo;

  @override
  void initState() {
    super.initState();
    repo = ClientesRepository(AppDatabase(), OdooService());
    // ✅ CAMBIO: Solo cargar clientes locales si ya hay una sesión activa
    // NO cargar clientes automáticamente al iniciar
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

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      debugPrint('🔑 Iniciando login...');

      // PRUEBA DE CONECTIVIDAD PRIMERO
      debugPrint('🧪 Probando conectividad básica...');
      try {
        final testResponse =
            await http_client.get(Uri.parse(_url.text.trim())).timeout(
                  const Duration(seconds: 10),
                );
        debugPrint('✅ Conectividad OK - Status: ${testResponse.statusCode}');
      } catch (e) {
        debugPrint('⚠️ Advertencia en test de conectividad: $e');
      }

      final uid = await repo.remote.authenticate(
        url: _url.text.trim(),
        db: _db.text.trim(),
        username: _user.text.trim(),
        password: _pass.text,
      );

      debugPrint('✅ Login exitoso - UID: $uid');

      // ✅ CAMBIO: Eliminar la verificación getUserInfo si no es necesaria
      // O moverla DESPUÉS de asignar el userId

      // Asignar userId primero
      setState(() => userId = uid);

      // Sincronizar pasando directamente el uid
      await _syncClientesWithUid(uid);
    } catch (e, stackTrace) {
      debugPrint('❌ Error en login: $e');
      debugPrint('Stack: $stackTrace');

      setState(() {
        error = 'Error de conexión: ${e.toString()}';
        loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _syncClientesWithUid(int uid) async {
    setState(() {
      syncing = true;
      error = null;
    });

    try {
      debugPrint('🔄 Iniciando sincronización con UID: $uid');

      await repo.syncClientes(
        url: _url.text.trim(),
        dbName: _db.text.trim(),
        userId: uid,
        password: _pass.text,
      );

      debugPrint('✅ Sincronización completada');
      setState(() => lastSync = DateTime.now());

      // ✅ IMPORTANTE: Solo cargar clientes DESPUÉS de sincronizar exitosamente
      await _loadLocalClientes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sincronización completada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error sincronizando: $e');
      debugPrint('Stack trace: $stackTrace');

      String errorMsg = e.toString();

      // Detectar diferentes tipos de errores
      if (errorMsg.contains('Access Denied') ||
          errorMsg.contains('faultCode')) {
        errorMsg = '''
⚠️ ERROR DE PERMISOS EN ODOO

El usuario no tiene acceso a los clientes.

Solución:
1. Ve a Odoo → Configuración → Usuarios
2. Edita el usuario: ${_user.text}
3. Asigna uno de estos grupos:
   • Ventas / Usuario
   • Ventas / Administrador
   • Contactos / Usuario

Después vuelve a intentar la sincronización.
''';
      }

      setState(() => error = errorMsg);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${errorMsg.split('\n')[0]}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 7),
            action: SnackBarAction(
              label: 'Ver detalles',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Error de Sincronización'),
                    content: SingleChildScrollView(
                      child: Text(errorMsg),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      setState(() {
        syncing = false;
        loading = false;
      });
    }
  }

  Future<void> syncClientes() async {
    if (userId == null) return;
    await _syncClientesWithUid(userId!);
  }

  Future<void> _showClienteDialog({Cliente? cliente}) async {
    final nameController = TextEditingController(text: cliente?.name);
    final emailController = TextEditingController(text: cliente?.email);
    final phoneController = TextEditingController(text: cliente?.phone);
    final cityController = TextEditingController(text: cliente?.city);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
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

                await _loadLocalClientes();
                if (ctx.mounted) Navigator.pop(ctx);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(cliente == null
                            ? 'Cliente creado'
                            : 'Cliente actualizado')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCliente(Cliente cliente) async {
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (userId != null)
            IconButton(
              icon: syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync),
              onPressed: syncing ? null : syncClientes,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (userId == null) ...[
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
                  title: Text('Conectado (UID: $userId)'),
                  trailing: TextButton(
                      onPressed: () => setState(() => userId = null),
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
                            userId == null
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
