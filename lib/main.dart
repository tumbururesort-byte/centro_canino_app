
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
