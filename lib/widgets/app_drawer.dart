
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
    final theme = Theme.of(context);

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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    )
                  ),
                  accountEmail: Text(
                    authProvider.userLogin ?? 'email@example.com',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    )
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: theme.colorScheme.onPrimary,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        context.read<NavigationProvider>().changePage(page);
        Navigator.pop(context); // Cierra el drawer
      },
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withAlpha(26),
    );
  }
}
