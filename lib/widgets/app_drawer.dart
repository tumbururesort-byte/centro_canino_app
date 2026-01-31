import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../pages/clientes_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.read<NavigationProvider>();
    final themeProvider = context.read<ThemeProvider>();

    return Drawer(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(
                    'Menú',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Clientes'),
                  onTap: () {
                    navigationProvider.changePage(const ClientesPage(), 'Clientes');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            title: const Text('Cambiar Tema'),
            onTap: () {
              themeProvider.toggleTheme();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context); // Cierra el drawer
            },
          ),
          const SizedBox(height: 10)
        ],
      ),
    );
  }
}
