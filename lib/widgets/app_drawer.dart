
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Leemos los providers una sola vez al inicio del build
    final authProvider = context.watch<AuthProvider>();
    final navigationProvider = context.read<NavigationProvider>();
    final themeProvider = context.read<ThemeProvider>();

    return Drawer(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                UserAccountsDrawerHeader(
                  accountName: Text(
                    authProvider.userName ?? 'Usuario',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(authProvider.userLogin ?? 'email@example.com'),
                  currentAccountPicture: CircleAvatar(
                    child: Icon(Icons.person, size: 40),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
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
          const Divider(),
          ListTile(
            leading: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            title: const Text('Cambiar Tema'),
            onTap: () {
              themeProvider.toggleTheme();
            },
          ),
          const SizedBox(height: 10)
        ],
      ),
    );
  }

  // Widget helper para crear los elementos del menú
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required AppPage page,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        context.read<NavigationProvider>().changePage(page);
        Navigator.pop(context); // Cierra el drawer
      },
      selected: isSelected,
      // Usamos withAlpha para la opacidad, que es la forma moderna
      selectedTileColor: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.1).round()),
    );
  }
}
