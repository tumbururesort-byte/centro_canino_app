import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/data/clientes_repository.dart';
import 'package:myapp/data/remote/odoo_service.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/clientes_provider.dart';
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
        // Infraestructura y servicios base
        Provider<AppDatabase>.value(value: db),
        Provider<SharedPreferences>.value(value: sharedPreferences),
        ChangeNotifierProvider(
            create: (ctx) =>
                AuthProvider(sharedPreferences: ctx.read<SharedPreferences>())),
        
        // Proxy para OdooService que depende de AuthProvider
        ProxyProvider<AuthProvider, OdooService?>(
          update: (_, auth, __) => auth.odooService,
        ),
        
        // Provider para ClientesRepository que depende de OdooService
        // Se crea una sola instancia que será compartida
        ProxyProvider<OdooService?, ClientesRepository>(
          update: (ctx, odooService, previous) => ClientesRepository(
            odooService: odooService,
            clientesDao: db.clientesDao,
            tarifasDao: db.tarifasDao,
            sharedPreferences: sharedPreferences,
          ),
        ),

        // ClientesProvider depende de AuthProvider y del ClientesRepository compartido
        ChangeNotifierProxyProvider2<AuthProvider, ClientesRepository, ClientesProvider>(
          create: (ctx) => ClientesProvider(
            repository: ctx.read<ClientesRepository>(),
            authProvider: ctx.read<AuthProvider>(),
          ),
          update: (_, auth, repository, previous) => ClientesProvider(
            repository: repository,
            authProvider: auth,
          ),
        ),

        // TarifasProvider depende del mismo ClientesRepository compartido
        ChangeNotifierProxyProvider<ClientesRepository, TarifasProvider>(
          create: (ctx) => TarifasProvider(ctx.read<ClientesRepository>()),
          update: (_, repository, __) => TarifasProvider(repository),
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
              backgroundColor: AppColors.backgroundDark,
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
