
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../pages/clientes_page.dart';
import '../pages/profile_page.dart';
import 'app_drawer.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  // Determina el título del AppBar según la página actual
  String _getCurrentPageTitle(AppPage page) {
    switch (page) {
      case AppPage.clientes:
        return 'Clientes';
      case AppPage.perfil:
        return 'Mi Perfil';
    }
  }

  // Devuelve el widget de la página correspondiente
  Widget _buildCurrentPage(AppPage page) {
    switch (page) {
      case AppPage.clientes:
        return const ClientesPage();
      case AppPage.perfil:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        final currentPage = navigationProvider.currentPage;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(_getCurrentPageTitle(currentPage)),
            // La barra de búsqueda se gestionará dentro de ClentesPage
          ),
          drawer: const AppDrawer(),
          body: _buildCurrentPage(currentPage),
          floatingActionButton: navigationProvider.fabAction == null
              ? null
              : FloatingActionButton(
                  onPressed: navigationProvider.fabAction,
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }
}
