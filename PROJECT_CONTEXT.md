]633;E;echo "# Proyecto Flutter – Contexto para IA";8241afb0-6147-4f3a-89bb-dcc1d45dd1b3]633;C# Proyecto Flutter – Contexto para IA

## pubspec.yaml
```yaml
name: myapp
description: "App offline-first de clientes con Odoo"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Database (solo SQLite nativo para Android)
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.8.0
  
  # HTTP para Odoo
  http: ^1.6.0
  
  # UI
  google_fonts: ^8.0.0
  xml: ^6.6.1
  provider: ^6.1.5+1
  shared_preferences: ^2.5.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  
  # Code generation
  drift_dev: ^2.14.0
  build_runner: ^2.10.5
  mockito: ^5.6.3
  flutter_launcher_icons: ^0.14.4

flutter:
  uses-material-design: true
  assets:
    - assets/images/

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/launcher_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/launcher_icon.png"
```

## Código fuente (lib/)

### FILE: lib/data/clientes_repository.dart
```dart
import 'dart:async';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote/odoo_service.dart';
import 'local/app_database.dart';
import 'local/dao/clientes_dao.dart';
import 'dart:developer' as developer;

class ClientesRepository {
  final OdooService? odooService;
  final ClientesDao clientesDao;
  final SharedPreferences sharedPreferences;

  var _progressStreamController = StreamController<String>.broadcast();
  Stream<String> get progressStream => _progressStreamController.stream;

  static const String lastSyncTimestampKey = 'last_sync_timestamp';

  ClientesRepository({
    this.odooService,
    required this.clientesDao,
    required this.sharedPreferences,
  });

  String _sanitizeString(dynamic value, {String defaultValue = ''}) {
    if (value is String) return value;
    if (value == false || value == null) return defaultValue;
    return value.toString();
  }

  Stream<List<Cliente>> watchClientes() {
    return clientesDao.watchAllClientes();
  }

  Future<void> syncClientes() async {
    if (_progressStreamController.isClosed) {
      _progressStreamController = StreamController<String>.broadcast();
    }

    if (odooService == null || !odooService!.isUserLoggedIn) {
      _progressStreamController.add("Sincronización pausada. Inicia sesión para continuar.");
      return;
    }

    developer.log('🚀 Iniciando proceso de sincronización...', name: 'ClientesRepository');
    _progressStreamController.add('Iniciando sincronización...');

    try {
      await _syncPendientes();

      final lastSync = _getLastSyncDate();
      final totalToSync = await odooService!.countClientes(lastSync: lastSync);
      
      if (totalToSync == 0) {
        _progressStreamController.add('👍 ¡Todo está al día!');
        await _saveLastSyncDate();
        return;
      }

      _progressStreamController.add('$totalToSync clientes para descargar.');

      const chunkSize = 50;
      for (int offset = 0; offset < totalToSync; offset += chunkSize) {
        final message = 'Descargando... ${offset + 1} - ${offset + chunkSize > totalToSync ? totalToSync : offset + chunkSize} de $totalToSync';
        _progressStreamController.add(message);

        final clientesFromOdoo = await odooService!.fetchClientesChunk(lastSync: lastSync, limit: chunkSize, offset: offset);
        if (clientesFromOdoo.isNotEmpty) {
          final clientesToSave = clientesFromOdoo.map((data) => _clienteFromOdooData(data)).toList();
          await clientesDao.insertOrUpdateAll(clientesToSave);
        }
      }
      
      await _saveLastSyncDate();
      _progressStreamController.add('✅ Sincronización completada.');

    } catch (e, s) {
      final errorMessage = '❌ Error durante la sincronización: $e';
      _progressStreamController.add(errorMessage);
      developer.log(errorMessage, stackTrace: s, name: 'ClientesRepository');
    }
  }

  Future<void> _syncPendientes() async {
    final pendientes = await clientesDao.getClientesPendientes();
    if (pendientes.isEmpty) return;

    _progressStreamController.add('Enviando ${pendientes.length} cambios locales...');
    
    for (final cliente in pendientes) {
      try {
        if (cliente.isDeleted) {
          if (cliente.odooId != null) {
            await odooService!.deleteCliente(cliente.odooId!);
          }
          await clientesDao.deleteCliente(cliente);
        } else if (cliente.odooId == null) {
          final newId = await odooService!.createCliente(_clienteToOdooData(cliente));
          final updatedCliente = cliente.copyWith(odooId: Value(newId), pendingSync: false);
          await clientesDao.updateCliente(updatedCliente);
        } else {
          await odooService!.updateCliente(cliente.odooId!, _clienteToOdooData(cliente));
          final updatedCliente = cliente.copyWith(pendingSync: false);
          await clientesDao.updateCliente(updatedCliente);
        }
      } catch (e) {
        developer.log('Error sincronizando cliente ${cliente.id}: $e', name: 'ClientesRepository');
      }
    }
    _progressStreamController.add('Cambios locales enviados.');
  }

  Future<void> createCliente(String name, String email, String phone, String city) async {
    final cliente = ClientesCompanion(
      name: Value(name),
      email: Value(email),
      phone: Value(phone),
      city: Value(city),
      pendingSync: const Value(true),
    );
    await clientesDao.insertCliente(cliente);
    syncClientes();
  }

  Future<void> updateCliente(Cliente cliente) async {
    final updatedCliente = cliente.copyWith(pendingSync: true);
    await clientesDao.updateCliente(updatedCliente);
    syncClientes();
  }

  Future<void> deleteCliente(Cliente cliente) async {
    final updatedCliente = cliente.copyWith(pendingSync: true, isDeleted: true);
    await clientesDao.updateCliente(updatedCliente);
    syncClientes(); 
  }

  DateTime? _getLastSyncDate() {
    final lastSyncString = sharedPreferences.getString(lastSyncTimestampKey);
    return lastSyncString != null ? DateTime.parse(lastSyncString) : null;
  }

  Future<void> _saveLastSyncDate() async {
    await sharedPreferences.setString(lastSyncTimestampKey, DateTime.now().toIso8601String());
  }

  ClientesCompanion _clienteFromOdooData(Map<String, dynamic> data) {
    final mobile = _sanitizeString(data['mobile']);
    final phone = _sanitizeString(data['phone']);
    return ClientesCompanion(
      odooId: Value(data['id'] as int),
      name: Value(_sanitizeString(data['name'], defaultValue: 'Nombre no disponible')),
      email: Value(_sanitizeString(data['email'])),
      phone: Value(mobile.isNotEmpty ? mobile : phone),
      city: Value(_sanitizeString(data['city'])),
      pendingSync: const Value(false),
    );
  }

  Map<String, dynamic> _clienteToOdooData(Cliente cliente) {
    return {
      'name': cliente.name,
      'email': cliente.email?.isNotEmpty == true ? cliente.email : false,
      'mobile': cliente.phone?.isNotEmpty == true ? cliente.phone : false,
      'city': cliente.city?.isNotEmpty == true ? cliente.city : false,
      'customer_rank': 1,
    };
  }

  void dispose() {
    if (!_progressStreamController.isClosed) {
      _progressStreamController.close();
    }
  }
}
```
---

### FILE: lib/data/local/app_database.dart
```dart
import 'package:drift/drift.dart';
import 'connection/mobile.dart';
import 'clientes_table.dart';
import 'dao/clientes_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Clientes], daos: [ClientesDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(openConnection());

  static final AppDatabase _instance = AppDatabase._();

  static AppDatabase get instance => _instance;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        // La forma correcta es usar `allTables` de la propia base de datos.
        // Primero, borramos todas las tablas.
        for (final table in allTables) {
          await m.drop(table);
        }

        // Luego, las volvemos a crear.
        for (final table in allTables) {
          await m.create(table);
        }
      },
    );
  }
}
```
---

### FILE: lib/data/local/clientes_table.dart
```dart
import 'package:drift/drift.dart';

@DataClassName('Cliente')
class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get odooId => integer().unique().nullable()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get city => text().nullable()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
```
---

### FILE: lib/data/local/connection/mobile.dart
```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'clientes.sqlite'));
    return NativeDatabase(file);
  });
}```
---

### FILE: lib/data/local/dao/clientes_dao.dart
```dart
import 'package:drift/drift.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/data/local/clientes_table.dart';

part 'clientes_dao.g.dart';

@DriftAccessor(tables: [Clientes])
class ClientesDao extends DatabaseAccessor<AppDatabase> with _$ClientesDaoMixin {
  ClientesDao(super.db);

  Stream<List<Cliente>> watchAllClientes() => (select(clientes)..where((c) => c.isDeleted.equals(false))).watch();

  Future<void> insertCliente(ClientesCompanion cliente) => into(clientes).insert(cliente);

  Future<void> insertOrUpdateAll(List<ClientesCompanion> clientesList) {
    return batch((batch) {
      batch.insertAll(
        clientes,
        clientesList,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> updateCliente(Cliente cliente) => update(clientes).replace(cliente);
  
  Future<void> deleteCliente(Cliente cliente) => delete(clientes).delete(cliente);

  Future<List<Cliente>> getClientesPendientes() {
    return (select(clientes)..where((c) => c.pendingSync.equals(true))).get();
  }
}
```
---

### FILE: lib/data/remote/odoo_service.dart
```dart
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:async';

class OdooService {
  final String serverUrl;
  final String dbName;
  late http.Client _client;
  String? _sessionId;
  int? uid;
  String? userName;
  String? userLogin;

  String get url => serverUrl;
  String get db => dbName;
  String? get sessionId => _sessionId;
  
  /// Returns true if the user is currently authenticated.
  bool get isUserLoggedIn => uid != null && _sessionId != null;

  OdooService({required this.serverUrl, required this.dbName}) {
    _client = http.Client();
  }

  void restoreSession(String newSessionId, int newUid, String newUserName, String newUserLogin) {
    _sessionId = newSessionId;
    uid = newUid;
    userName = newUserName;
    userLogin = newUserLogin;
    developer.log('🔄 Sesión restaurada para $userName. UID: $uid', name: 'OdooService');
  }

  Future<void> authenticate(String email, String password) async {
    final url = Uri.parse('$serverUrl/web/session/authenticate');
    
    final requestBody = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'db': dbName,
        'login': email,
        'password': password,
        'context': {},
      },
    });

    developer.log('🔐 Autenticando en $url para la base de datos $dbName', name: 'OdooService');
    
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          _sessionId = rawCookie.split(';').firstWhere(
            (c) => c.trim().startsWith('session_id='),
            orElse: () => ''
          ).split('=').last;
        }
        
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData.containsKey('error')) {
          final error = responseData['error'];
          developer.log('❌ Error de Odoo: ${error['message']}', name: 'OdooService');
          throw Exception('Error de Odoo: ${error['data']['debug']}');
        }

        final result = responseData['result'];
        if (result != null && result['uid'] != false) {
          uid = result['uid'];
          userName = result['name'];
          userLogin = result['username'];

          developer.log('✅ Autenticación exitosa para $userName. UID: $uid', name: 'OdooService');
        } else {
          // Si no hay UID, consideramos la autenticación fallida.
          _sessionId = null; // Borramos el sessionId si lo hubiera
          throw Exception('Credenciales incorrectas o respuesta inesperada.');
        }
      } else {
        developer.log('❌ Error HTTP ${response.statusCode}: ${response.body}', name: 'OdooService');
        throw Exception('Error de conexión con el servidor: ${response.statusCode}');
      }
    } on TimeoutException {
      developer.log('❌ Timeout en la autenticación', name: 'OdooService');
      throw Exception('El servidor no respondió a tiempo. Verifique la URL y su conexión.');
    } catch (e) {
      developer.log('❌ Excepción en authenticate: $e', name: 'OdooService');
      rethrow;
    }
  }

  Future<dynamic> _executeRpc(String path, String method, Map<String, dynamic> params) async {
    if (!isUserLoggedIn) {
      throw Exception('No autenticado. Por favor, inicie sesión primero.');
    }

    final url = Uri.parse('$serverUrl$path');
    final requestBody = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': params,
    });

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 45));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        if (responseData.containsKey('error')) {
          final error = responseData['error'];
          developer.log('❌ Error RPC de Odoo: ${error['message']}', name: 'OdooService', error: error);
          throw Exception('Error RPC: ${error['data']['debug']}');
        }
        return responseData['result'];
      } else {
        throw Exception('Error en la llamada RPC: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Excepción en _executeRpc: $e', name: 'OdooService');
      rethrow;
    }
  }
  Future<int> countClientes({DateTime? lastSync}) async {
    developer.log('🔍 Contando clientes para sincronizar...', name: 'OdooService');
    List<dynamic> domain = [
      ['customer_rank', '>', 0]
    ];
    if (lastSync != null) {
      final utcDate = lastSync.toUtc().toIso8601String().split('.')[0];
      domain.add(['write_date', '>', utcDate]);
    }
    final result = await _executeRpc('/web/dataset/call_kw/res.partner/search_count', 'call', {
        'args': [domain],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'search_count',
    });
    developer.log('✅ Conteo finalizado: $result clientes.', name: 'OdooService');
    return result is int ? result : 0;
  }

  Future<List<Map<String, dynamic>>> fetchClientesChunk({
    DateTime? lastSync,
    required int limit,
    required int offset,
  }) async {
    final syncLog = lastSync != null ? 'modificados desde ${lastSync.toIso8601String()}' : 'TODOS';
    developer.log('📡 Obteniendo clientes (lote de $limit a partir de $offset) $syncLog...', name: 'OdooService');

    List<dynamic> domain = [
      ['customer_rank', '>', 0]
    ];
    if (lastSync != null) {
      final utcDate = lastSync.toUtc().toIso8601String().split('.')[0];
      domain.add(['write_date', '>', utcDate]);
    }

    final result = await _executeRpc('/web/dataset/search_read', 'call', {
      'model': 'res.partner',
      'fields': ['id', 'name', 'email', 'phone', 'mobile', 'city', 'write_date'],
      'domain': domain,
      'limit': limit,
      'offset': offset,
      'sort': 'id ASC',
      'context': {},
    });

    if (result != null && result['records'] is List) {
      final records = List<Map<String, dynamic>>.from(result['records']);
      developer.log('✅ ${records.length} clientes recibidos en este lote.', name: 'OdooService');
      return records;
    }
    return [];
  }

  Future<int> createCliente(Map<String, dynamic> data) async {
    developer.log('➕ Creando cliente en Odoo: ${data['name']}', name: 'OdooService');
    final newId = await _executeRpc('/web/dataset/call_kw/res.partner/create', 'call', {
        'args': [data],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'create',
    });
    developer.log('✅ Cliente creado con ID: $newId', name: 'OdooService');
    return newId;
  }

  Future<void> updateCliente(int odooId, Map<String, dynamic> data) async {
    developer.log('✏️ Actualizando cliente Odoo ID: $odooId', name: 'OdooService');
    await _executeRpc('/web/dataset/call_kw/res.partner/write', 'call', {
        'args': [[odooId], data],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'write',
    });
    developer.log('✅ Cliente actualizado.', name: 'OdooService');
  }

  Future<void> deleteCliente(int odooId) async {
    developer.log('🗑️ Eliminando cliente Odoo ID: $odooId', name: 'OdooService');
     await _executeRpc('/web/dataset/call_kw/res.partner/unlink', 'call', {
        'args': [[odooId]],
        'kwargs': {'context': {}},
        'model': 'res.partner',
        'method': 'unlink',
    });
    developer.log('✅ Cliente eliminado.', name: 'OdooService');
  }
  
  void dispose() {
    _client.close();
  }
}
```
---

### FILE: lib/main.dart
```dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/local/app_database.dart';
import 'data/clientes_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/clientes_provider.dart';
import 'pages/login_page.dart';
import 'widgets/main_scaffold.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  final AppDatabase database = AppDatabase.instance;

  // Crear el AuthProvider aquí para poder llamar a tryAutoLogin
  final authProvider = AuthProvider(sharedPreferences: sharedPreferences);
  await authProvider.tryAutoLogin(); // Llamada única al inicio

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: database),
        Provider.value(value: sharedPreferences),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(sharedPreferences: sharedPreferences),
        ),

        // ProxyProvider que construye ClientesRepository
        ProxyProvider<AuthProvider, ClientesRepository>(
          update: (context, auth, previous) => ClientesRepository(
            odooService: auth.odooService,
            clientesDao: database.clientesDao,
            sharedPreferences: sharedPreferences,
          ),
        ),

        // ProxyProvider para ClientesProvider
        ChangeNotifierProxyProvider<AuthProvider, ClientesProvider>(
          create: (context) => ClientesProvider(
            repository: context.read<ClientesRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) {
            final repository = context.read<ClientesRepository>();
            previous?.updateDependencies(repository, auth);
            return previous ?? ClientesProvider(repository: repository, authProvider: auth);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Clientes Offline-First',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: authProvider.isLoggedIn
              ? const MainScaffold()
              : const LoginPage(),
        );
      },
    );
  }
}
```
---

### FILE: lib/pages/cliente_edit_page.dart
```dart
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

  bool get _isEditing => widget.cliente != null;
  bool _isSaving = false;

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
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

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
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteCliente() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Eliminar cliente',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este cliente?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await context.read<ClientesProvider>().deleteCliente(widget.cliente!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente eliminado'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Editar cliente' : 'Nuevo cliente',
          style: context.textTheme.titleLarge,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: _deleteCliente,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildProfileHeader(),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Nombre completo',
                      icon: Icons.person,
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      labelText: 'Teléfono',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      labelText: 'Correo electrónico',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cityController,
                      labelText: 'Ciudad',
                      icon: Icons.location_on,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _saveCliente,
        backgroundColor: _isSaving
            ? AppColors.primary.withAlpha(128)
            : AppColors.primary,
        elevation: 4,
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final avatarColor = _isEditing 
        ? AppTheme.getAvatarColor(widget.cliente!.name)
        : AppColors.primary;
    
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          child: Center(
            child: _isEditing && widget.cliente!.name.isNotEmpty
                ? Text(
                    widget.cliente!.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // Funcionalidad para cambiar foto (futura implementación)
          },
          child: Text(
            'Cambiar foto',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ),
      ],
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
}```
---

### FILE: lib/pages/clientes_page.dart
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/pages/cliente_edit_page.dart';
import 'package:myapp/providers/clientes_provider.dart';
import 'package:myapp/providers/navigation_provider.dart';
import 'package:myapp/theme/app_theme.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ClientesView();
  }
}

void _navigateToCliente(BuildContext context, {Cliente? cliente}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => ClienteEditPage(cliente: cliente),
    ),
  );
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientesProvider>(
      builder: (context, provider, child) {
        final filteredClientes = _filterClientes(
          provider.clientes,
          context.watch<NavigationProvider>().searchQuery,
        );

        return Container(
          color: AppColors.backgroundDark,
          child: Column(
            children: [
              _buildSyncStatus(provider),
              Expanded(
                child: provider.isLoading && provider.clientes.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.syncClientes(),
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceDark,
                        child: filteredClientes.isEmpty
                            ? _buildEmptyState(
                                context.watch<NavigationProvider>().searchQuery,
                              )
                            : _buildClientesList(context, filteredClientes),
                      ),
              ),
            ],
          ),
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
          // El mensaje se limpiará automáticamente
        }
      });
    }

    return Container(
      color: isError ? AppColors.error : AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              if (!isLoading)
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String searchQuery) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                size: 80,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                searchQuery.isEmpty
                    ? 'No hay clientes'
                    : 'No se encontraron resultados',
                style: context.textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (searchQuery.isEmpty) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.read<ClientesProvider>().syncClientes(),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar ahora'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  ListView _buildClientesList(BuildContext context, List<Cliente> clientes) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: clientes.length,
      itemBuilder: (context, i) {
        final cliente = clientes[i];
        return Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider,
                width: 1,
              ),
            ),
          ),
          child: Material(
            color: AppColors.backgroundDark,
            child: InkWell(
              onTap: () => _navigateToCliente(context, cliente: cliente),
              splashColor: AppColors.surfaceDark,
              highlightColor: AppColors.surfaceDark,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Avatar con iniciales
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.getAvatarColor(cliente.name),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          cliente.name.isNotEmpty
                              ? cliente.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Información del cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.name,
                            style: context.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cliente.phone?.isNotEmpty == true
                                ? cliente.phone!
                                : cliente.email ?? 'Sin información',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}```
---

### FILE: lib/pages/login_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

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

  @override
  void dispose() {
    _urlController.dispose();
    _dbController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final success = await authProvider.login(
        _urlController.text.trim(),
        _dbController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!success && mounted) {
        throw Exception('Credenciales incorrectas');
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      _buildHeader(),
                      const SizedBox(height: 50),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _urlController,
                              labelText: 'URL del servidor',
                              icon: Icons.link,
                              keyboardType: TextInputType.url,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _dbController,
                              labelText: 'Base de datos',
                              icon: Icons.storage,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _emailController,
                              labelText: 'Correo electrónico',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              labelText: 'Contraseña',
                              icon: Icons.lock,
                              isPassword: true,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _buildLoginButton(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(77),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.pets,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Tumburú',
          style: context.textTheme.displayLarge?.copyWith(
            fontSize: 32,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conecta con tu cuenta',
          style: context.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      onFieldSubmitted: (_) => _login(),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('CONECTAR'),
      ),
    );
  }
}```
---

### FILE: lib/pages/profile_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clientes_provider.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Container(
      color: AppColors.backgroundDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildProfileHeader(authProvider),
          const SizedBox(height: 16),
          _buildSectionTitle('Información de la cuenta'),
          _buildInfoCard([
            _buildInfoTile(
              icon: Icons.person,
              title: 'Nombre',
              subtitle: authProvider.userName ?? 'No disponible',
            ),
            const Divider(color: AppColors.divider, height: 1),
            _buildInfoTile(
              icon: Icons.email,
              title: 'Usuario',
              subtitle: authProvider.userLogin ?? 'No disponible',
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('Conexión'),
          _buildInfoCard([
            _buildInfoTile(
              icon: Icons.cloud,
              title: 'Servidor',
              subtitle: authProvider.serverUrl ?? 'No disponible',
            ),
            const Divider(color: AppColors.divider, height: 1),
            _buildInfoTile(
              icon: Icons.storage,
              title: 'Base de datos',
              subtitle: authProvider.dbName ?? 'No disponible',
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('Sincronización'),
          _buildSyncButton(),
          const SizedBox(height: 32),
          _buildLogoutButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            authProvider.userName ?? 'Nombre no disponible',
            style: context.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.userLogin ?? 'Login no disponible',
            style: context.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: context.textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon, color: AppColors.textSecondary, size: 24),
      title: Text(
        title,
        style: context.textTheme.bodySmall,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () async {
            final provider = context.read<ClientesProvider>();
            await provider.syncClientes();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronización iniciada'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.sync, color: AppColors.textSecondary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sincronizar datos',
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Actualizar clientes desde el servidor',
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('CERRAR SESIÓN'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext ctx) {
                return AlertDialog(
                  backgroundColor: AppColors.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: const Text(
                    '¿Estás seguro de que quieres cerrar la sesión?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        context.read<AuthProvider>().logout();
                      },
                    ),
                  ],
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}```
---

### FILE: lib/providers/auth_provider.dart
```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/remote/odoo_service.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences sharedPreferences;
  OdooService? _odooService;

  final _authChangeController = StreamController<bool>.broadcast();
  Stream<bool> get onAuthChanged => _authChangeController.stream;

  OdooService? get odooService => _odooService;
  bool get isLoggedIn => _odooService != null && _odooService!.isUserLoggedIn;
  int? get uid => _odooService?.uid;
  String? get userName => _odooService?.userName;
  String? get userLogin => _odooService?.userLogin;
  String? get serverUrl => _odooService?.url;
  String? get dbName => _odooService?.db;
  
  bool _autoLoginAttempted = false;

  AuthProvider({required this.sharedPreferences});

  /// Intenta hacer login con las credenciales proporcionadas
  Future<bool> login(String url, String db, String email, String password) async {
    try {
      // Limpiar URL de espacios en blanco
      final cleanUrl = url.trim();
      final cleanDb = db.trim();
      final cleanEmail = email.trim();
      
      // Validaciones básicas
      if (cleanUrl.isEmpty || cleanDb.isEmpty || cleanEmail.isEmpty || password.isEmpty) {
        throw Exception('Todos los campos son requeridos');
      }
      
      final service = OdooService(serverUrl: cleanUrl, dbName: cleanDb);
      await service.authenticate(cleanEmail, password);

      if (service.isUserLoggedIn) {
        _odooService = service;
        await _saveSession();
        notifyListeners();
        _authChangeController.add(true);
        
        if (kDebugMode) {
          print('✅ Login exitoso para ${service.userName}');
        }
        return true;
      } else {
        _odooService = null;
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error durante login: $e');
      }
      _odooService = null;
      rethrow;
    }
  }

  /// Guarda la sesión actual en SharedPreferences
  Future<void> _saveSession() async {
    if (_odooService == null || !_odooService!.isUserLoggedIn) return;
    
    final service = _odooService!;
    
    try {
      await Future.wait([
        sharedPreferences.setString('odoo_url', service.url),
        sharedPreferences.setString('odoo_db', service.dbName),
        sharedPreferences.setString('odoo_session_id', service.sessionId!),
        sharedPreferences.setInt('odoo_uid', service.uid!),
        sharedPreferences.setString('odoo_user_name', service.userName!),
        sharedPreferences.setString('odoo_user_login', service.userLogin!),
      ]);
      
      if (kDebugMode) {
        print('💾 Sesión guardada exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al guardar sesión: $e');
      }
    }
  }

  /// Cierra la sesión actual
  Future<void> logout() async {
    try {
      _odooService?.dispose();
      _odooService = null;
      
      await sharedPreferences.clear();
      
      notifyListeners();
      _authChangeController.add(false);
      
      if (kDebugMode) {
        print('👋 Sesión cerrada exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al cerrar sesión: $e');
      }
    }
  }

  /// Intenta restaurar la sesión guardada automáticamente
  Future<void> tryAutoLogin() async {
    if (_autoLoginAttempted) {
      if (kDebugMode) {
        print('⚠️ Auto-login ya fue intentado');
      }
      return;
    }
    
    _autoLoginAttempted = true;

    try {
      final url = sharedPreferences.getString('odoo_url');
      final db = sharedPreferences.getString('odoo_db');
      final sessionId = sharedPreferences.getString('odoo_session_id');
      final uid = sharedPreferences.getInt('odoo_uid');
      final userName = sharedPreferences.getString('odoo_user_name');
      final userLogin = sharedPreferences.getString('odoo_user_login');

      // Verificar que todos los datos necesarios estén presentes
      if (url != null && 
          db != null && 
          sessionId != null && 
          uid != null && 
          userName != null && 
          userLogin != null) {
        
        if (kDebugMode) {
          print('🔄 Intentando restaurar sesión para $userName...');
        }
        
        final service = OdooService(serverUrl: url, dbName: db);
        service.restoreSession(sessionId, uid, userName, userLogin);

        _odooService = service;
        notifyListeners();
        _authChangeController.add(true);
        
        if (kDebugMode) {
          print('✅ Sesión restaurada exitosamente');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ No hay sesión guardada para restaurar');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al restaurar sesión: $e');
      }
      await logout();
    }
  }

  @override
  void dispose() {
    _authChangeController.close();
    _odooService?.dispose();
    super.dispose();
  }
}```
---

### FILE: lib/providers/clientes_provider.dart
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/data/clientes_repository.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/providers/auth_provider.dart';

class ClientesProvider with ChangeNotifier {
  late ClientesRepository _repository;
  final AuthProvider _authProvider;

  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _error;
  String? _syncMessage;

  StreamSubscription? _clientesSubscription;
  StreamSubscription? _progressSubscription;
  StreamSubscription? _authSubscription;

  ClientesProvider({
    required ClientesRepository repository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _authProvider = authProvider {
    _authSubscription = _authProvider.onAuthChanged.listen((isLoggedIn) {
      if (isLoggedIn) {
        _initialize();
      } else {
        _clearData();
      }
    });
    
    if (_authProvider.isLoggedIn) {
      _initialize();
    }
  }

  void _initialize() {
    _listenToClientesStream();
    _listenToProgressStream();
    syncClientes();
  }

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get syncMessage => _syncMessage;

  void updateDependencies(ClientesRepository newRepository, AuthProvider newAuthProvider) {
    if (_repository != newRepository) {
      _repository.dispose();
      _repository = newRepository;
      
      if (newAuthProvider.isLoggedIn) {
        _initialize();
      }
    }
  }

  void _listenToClientesStream() {
    _clientesSubscription?.cancel();
    _clientesSubscription = _repository.watchClientes().listen(
      (clientes) {
        _clientes = clientes;
        if (!_isLoading) {
          notifyListeners();
        }
      },
      onError: (e) {
        _error = 'Error al leer la base de datos: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _listenToProgressStream() {
    _progressSubscription?.cancel();
    _progressSubscription = _repository.progressStream.listen((message) {
      _syncMessage = message;
      final isFinalMessage = message.startsWith('✅') || message.startsWith('❌') || message.startsWith('👍');
      
      if (isFinalMessage) {
        _isLoading = false;
        _error = message.startsWith('❌') ? message : null;
      } else {
        _isLoading = true;
        _error = null;
      }
      
      notifyListeners();
    });
  }

  Future<void> syncClientes() async {
    if (_isLoading) return;
    await _repository.syncClientes();
  }

  Future<void> createCliente(String name, String email, String phone, String city) async {
    if (name.trim().isEmpty) throw Exception('El nombre es obligatorio');
    await _repository.createCliente(name.trim(), email.trim(), phone.trim(), city.trim());
  }

  Future<void> updateCliente(Cliente cliente) async {
    if (cliente.name.trim().isEmpty) throw Exception('El nombre es obligatorio');
    await _repository.updateCliente(cliente);
  }

  Future<void> deleteCliente(Cliente cliente) async {
    await _repository.deleteCliente(cliente);
  }

  void _clearData() {
    _clientesSubscription?.cancel();
    _progressSubscription?.cancel();
    _clientes = [];
    _isLoading = false;
    _error = null;
    _syncMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clientesSubscription?.cancel();
    _progressSubscription?.cancel();
    _authSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
```
---

### FILE: lib/providers/navigation_provider.dart
```dart

import 'package:flutter/material.dart';

// Enum para representar las páginas principales de la aplicación
enum AppPage {
  clientes,
  perfil,
}

class NavigationProvider with ChangeNotifier {
  AppPage _currentPage = AppPage.clientes; // Página inicial
  VoidCallback? _fabAction;
  String _searchQuery = '';
  bool _isSearchActive = false; // <-- NUEVO: Estado para la búsqueda

  // Getters públicos
  AppPage get currentPage => _currentPage;
  VoidCallback? get fabAction => _fabAction;
  String get searchQuery => _searchQuery;
  bool get isSearchActive => _isSearchActive; // <-- NUEVO: Getter para el estado

  // Cambia la página actual
  void changePage(AppPage page) {
    if (_currentPage == page) return; 

    _currentPage = page;
    _fabAction = null; 
    _searchQuery = ''; 
    _isSearchActive = false; // <-- NUEVO: Reseteamos la búsqueda al cambiar de página
    notifyListeners();
  }

  // --- MÉTODOS PARA LA BÚSQUEDA ---

  // Inicia el modo de búsqueda
  void startSearch() {
    if (_isSearchActive) return;
    _isSearchActive = true;
    notifyListeners();
  }

  // Detiene el modo de búsqueda y limpia la consulta
  void stopSearch() {
    if (!_isSearchActive) return;
    _isSearchActive = false;
    _searchQuery = '';
    notifyListeners();
  }

  // Actualiza el texto de la búsqueda
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // --- MÉTODOS PARA EL FAB ---

  void registerFabAction(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabAction = action;
      notifyListeners();
    });
  }

  void unregisterFabAction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabAction = null;
      notifyListeners();
    });
  }
}
```
---

### FILE: lib/providers/theme_provider.dart
```dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferences sharedPreferences;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider({required this.sharedPreferences}) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadTheme() {
    final themeIndex = sharedPreferences.getInt('theme_mode');
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    
    await sharedPreferences.setInt('theme_mode', _themeMode.index);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await sharedPreferences.setInt('theme_mode', _themeMode.index);
    notifyListeners();
  }
}
```
---

### FILE: lib/theme/app_theme.dart
```dart
import 'package:flutter/material.dart';

/// Colores principales de Tumburú
class AppColors {
  // Prevenir instanciación
  AppColors._();
  
  // Colores principales - Coral/Salmón
  static const Color primary = Color(0xFFF27E5F);
  static const Color primaryLight = Color(0xFFFF9A7F);
  static const Color primaryDark = Color(0xFFE66B4D);
  
  // Fondos oscuros
  static const Color backgroundDark = Color(0xFF111B21);
  static const Color surfaceDark = Color(0xFF1F2C34);
  static const Color cardDark = Color(0xFF2A3942);
  
  // Textos
  static const Color textPrimary = Color(0xFFE9EDEF);
  static const Color textSecondary = Color(0xFF8696A0);
  static const Color textTertiary = Color(0xFF667781);
  
  // Estados
  static const Color success = Color(0xFF00A884);
  static const Color error = Color(0xFFDC4E41);
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF0088CC);
  
  // Bordes y divisores
  static const Color border = Color(0xFF2A3942);
  static const Color divider = Color(0xFF1F2C34);
  
  // Avatares (colores variados para las iniciales)
  static const List<Color> avatarColors = [
    Color(0xFFF27E5F), // Coral
    Color(0xFF00A884), // Verde
    Color(0xFF0088CC), // Azul
    Color(0xFFAA66CC), // Morado
    Color(0xFFFF8A65), // Naranja
    Color(0xFF4DB6AC), // Teal
    Color(0xFFF06292), // Rosa
    Color(0xFF7E57C2), // Violeta
  ];
}

/// Configuración de tema de la aplicación
class AppTheme {
  AppTheme._();
  
  /// Obtiene un color de avatar basado en un texto
  static Color getAvatarColor(String text) {
    if (text.isEmpty) return AppColors.avatarColors[0];
    final hash = text.hashCode.abs();
    return AppColors.avatarColors[hash % AppColors.avatarColors.length];
  }
  
  /// Tema claro de la aplicación
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      scaffoldBackgroundColor: Colors.grey[100],
       appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }


  /// Tema oscuro de la aplicación
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Esquema de colores
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.primaryLight,
        surface: AppColors.surfaceDark,
        surfaceContainer: AppColors.cardDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
      ),
      
      // Colores de fondo
      scaffoldBackgroundColor: AppColors.backgroundDark,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      
      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      
      // Diálogos
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
      ),
      
      // Divisores
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      
      // SnackBars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // ListTiles
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Iconos
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
      
      // Indicadores de progreso
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),
      
      // Switches
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withAlpha(128);
          }
          return AppColors.border;
        }),
      ),
      
      // Tipografía
      textTheme: const TextTheme(
        // Títulos grandes
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        
        // Títulos
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        
        // Títulos de sección
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),
        
        // Cuerpo de texto
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 0.15,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
        
        // Etiquetas
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Extensiones de tema para facilitar el acceso a colores
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
```
---

### FILE: lib/widgets/app_drawer.dart
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final navigationProvider = context.read<NavigationProvider>();

    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildDrawerHeader(authProvider),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.people,
                  title: 'Clientes',
                  page: AppPage.clientes,
                  isSelected: navigationProvider.currentPage == AppPage.clientes,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_circle,
                  title: 'Mi Perfil',
                  page: AppPage.perfil,
                  isSelected: navigationProvider.currentPage == AppPage.perfil,
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            authProvider.userName ?? 'Usuario',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.userLogin ?? 'email@example.com',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required AppPage page,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceDark : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          context.read<NavigationProvider>().changePage(page);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.settings,
              color: AppColors.textSecondary,
              size: 24,
            ),
            title: const Text(
              'Configuración',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            onTap: () {
              // Implementar configuración
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}```
---

### FILE: lib/widgets/cliente_list_item.dart
```dart

import 'package:flutter/material.dart';
import '../data/local/app_database.dart';

class ClienteListItem extends StatelessWidget {
  final Cliente cliente;

  const ClienteListItem({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            cliente.name.isNotEmpty ? cliente.name[0].toUpperCase() : '?',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(cliente.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cliente.email?.isNotEmpty ?? false)
              Text(cliente.email!),

            if (cliente.phone?.isNotEmpty ?? false)
              Text(cliente.phone!),

            if (cliente.city?.isNotEmpty ?? false)
              Text(cliente.city!),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(context, '/cliente_detalle', arguments: cliente.id);
        },
      ),
    );
  }
}
```
---

### FILE: lib/widgets/main_scaffold.dart
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/pages/cliente_edit_page.dart';
import '../providers/navigation_provider.dart';
import '../pages/clientes_page.dart';
import '../pages/profile_page.dart';
import '../theme/app_theme.dart';
import 'app_drawer.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCurrentPageTitle(AppPage page) {
    switch (page) {
      case AppPage.clientes:
        return 'Clientes';
      case AppPage.perfil:
        return 'Perfil';
    }
  }

  Widget _buildCurrentPage(AppPage page) {
    switch (page) {
      case AppPage.clientes:
        return const ClientesPage();
      case AppPage.perfil:
        return const ProfilePage();
    }
  }

  AppBar _buildDefaultAppBar(BuildContext context, NavigationProvider provider) {
    return AppBar(
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        _getCurrentPageTitle(provider.currentPage),
        style: context.textTheme.titleLarge,
      ),
      actions: [
        if (provider.currentPage == AppPage.clientes) ...[
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () => provider.startSearch(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            color: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (value) {
              if (value == 'sync') {
                // Implementar sincronización manual
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync, color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Sincronizar',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  AppBar _buildSearchAppBar(BuildContext context, NavigationProvider provider) {
    if (provider.searchQuery.isEmpty) {
      _searchController.clear();
    }

    return AppBar(
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () {
          provider.stopSearch();
          _searchController.clear();
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Buscar...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
        onChanged: (query) => provider.updateSearchQuery(query),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textPrimary),
            onPressed: () {
              provider.updateSearchQuery('');
              _searchController.clear();
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        final currentPage = navigationProvider.currentPage;
        final isSearching = navigationProvider.isSearchActive;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: isSearching && currentPage == AppPage.clientes
              ? _buildSearchAppBar(context, navigationProvider)
              : _buildDefaultAppBar(context, navigationProvider),
          drawer: const AppDrawer(),
          body: _buildCurrentPage(currentPage),
          floatingActionButton: (currentPage == AppPage.clientes && !isSearching)
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const ClienteEditPage(),
                      ),
                    );
                  },
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  child: const Icon(Icons.person_add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }
}```
---
