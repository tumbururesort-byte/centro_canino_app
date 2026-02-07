import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/data/app_data_repository.dart';
import 'package:myapp/data/remote/odoo_service.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/clientes_provider.dart';
import 'package:myapp/providers/pet_types_provider.dart';
import 'package:myapp/providers/tarifas_provider.dart';
import 'package:myapp/providers/navigation_provider.dart';
import 'package:myapp/pages/cliente_list_page.dart';
import 'package:myapp/pages/login_page.dart';
import 'package:myapp/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.instance;
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(MyApp(db: db, sharedPreferences: sharedPreferences));
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  final SharedPreferences sharedPreferences;

  const MyApp({super.key, required this.db, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<SharedPreferences>.value(value: sharedPreferences),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(sharedPreferences: ctx.read<SharedPreferences>()),
        ),
        ProxyProvider<AuthProvider, OdooService?>(
          update: (_, auth, __) => auth.odooService,
        ),
        ProxyProvider<OdooService?, AppDataRepository>(
          update: (ctx, odooService, previous) => AppDataRepository(
            odooService: odooService,
            clientesDao: db.clientesDao,
            tarifasDao: db.tarifasDao,
            petTypesDao: db.petTypesDao,
            sharedPreferences: sharedPreferences,
          ),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, AppDataRepository, ClientesProvider>(
          create: (ctx) => ClientesProvider(
            repository: ctx.read<AppDataRepository>(),
            authProvider: ctx.read<AuthProvider>(),
          ),
          update: (_, auth, repository, previous) => ClientesProvider(
            repository: repository,
            authProvider: auth,
          ),
        ),
        ChangeNotifierProxyProvider<AppDataRepository, TarifasProvider>(
          create: (ctx) => TarifasProvider(repository: ctx.read<AppDataRepository>()),
          update: (_, repository, __) => TarifasProvider(repository: repository),
        ),
        ChangeNotifierProxyProvider<AppDataRepository, PetTypesProvider>(
           create: (ctx) => PetTypesProvider(repository: ctx.read<AppDataRepository>()),
           update: (_, repository, __) => PetTypesProvider(repository: repository),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const AppMaterial(),
    );
  }
}

class AppMaterial extends StatefulWidget {
  const AppMaterial({super.key});

  @override
  State<AppMaterial> createState() => _AppMaterialState();
}

class _AppMaterialState extends State<AppMaterial> {
  late Future<void> _autoLoginFuture;

  @override
  void initState() {
    super.initState();
    _autoLoginFuture = context.read<AuthProvider>().tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odoo App',
      theme: AppTheme.darkTheme,
      home: FutureBuilder(
        future: _autoLoginFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return auth.isLoggedIn
                  ? const ClienteListPage()
                  : const LoginPage();
            },
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
