// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/data/clientes_repository.dart';
import 'package:myapp/main.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/services/odoo_service.dart';
import 'package:myapp/providers/navigation_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/clientes_provider.dart';

// --- Mocks ---
class MockOdooService extends Mock implements OdooService {}

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _loggedIn = false;
  final SharedPreferences sharedPreferences;
  OdooService? _odooService;

  MockAuthProvider({required this.sharedPreferences, bool loggedIn = false}) {
    _loggedIn = loggedIn;
    if (_loggedIn) {
      _odooService = MockOdooService();
    }
  }

  @override
  bool get isLoggedIn => _loggedIn;

  @override
  OdooService? get odooService => _odooService;

  @override
  Future<void> tryAutoLogin() async {
    notifyListeners();
  }

  @override
  Future<bool> login(String db, String username, String password) async => true;

  @override
  Future<void> logout() async {}

  @override
  set odooService(OdooService? service) {
    _odooService = service;
  }
}

void main() {
  testWidgets('App smoke test: debería mostrar la HomePage si el usuario está logueado', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final database = AppDatabase.inMemory();
    final mockAuthProvider = MockAuthProvider(sharedPreferences: prefs, loggedIn: true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: database),
          Provider.value(value: prefs),
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ProxyProvider2<AuthProvider, SharedPreferences, ClientesRepository>(
            update: (context, authProvider, prefs, previous) {
              // ¡CORREGIDO TAMBIÉN AQUÍ! Se quita el '!' para ser consistente.
              return ClientesRepository(
                odooService: authProvider.odooService,
                clientesDao: database.clientesDao,
                sharedPreferences: prefs,
              );
            },
          ),
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

    await tester.pumpAndSettle();

    expect(find.text('Dashboard Principal'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Gestionar Clientes'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsNothing);
  });
}
