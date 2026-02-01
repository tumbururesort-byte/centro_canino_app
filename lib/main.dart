
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  final AppDatabase database = AppDatabase.instance;

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: database),
        Provider.value(value: sharedPreferences),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(sharedPreferences: context.read<SharedPreferences>()),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // ProxyProvider que construye ClientesRepository
        ProxyProvider2<AuthProvider, SharedPreferences, ClientesRepository>(
          update: (context, authProvider, prefs, previous) {
            // ¡CORREGIDO! Se elimina el operador '!'.
            // Ahora el ClientesRepository puede ser construido con un odooService nulo
            // cuando el usuario no está logueado, evitando el crash.
            return ClientesRepository(
              odooService: authProvider.odooService, // Sin '!'
              clientesDao: database.clientesDao,
              sharedPreferences: prefs,
            );
          },
        ),

        // ProxyProvider que construye ClientesProvider y depende de ClientesRepository
        ChangeNotifierProxyProvider<ClientesRepository, ClientesProvider>(
          create: (context) => ClientesProvider(repository: context.read<ClientesRepository>()),
          update: (context, repository, previous) {
            previous?.updateRepository(repository);
            return previous ?? ClientesProvider(repository: repository);
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
    const Color primarySeedColor = Colors.deepPurple;

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Clientes Offline-First',
          theme: lightTheme,
          darkTheme: darkTheme,
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
    final authProvider = context.watch<AuthProvider>();

    authProvider.tryAutoLogin();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: authProvider.isLoggedIn
          ? const MainScaffold()
          : const LoginPage(),
    );
  }
}
