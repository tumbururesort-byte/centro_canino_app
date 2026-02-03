
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/pages/cliente_edit_page.dart';
import '../providers/navigation_provider.dart';
import '../pages/clientes_page.dart';
import '../pages/profile_page.dart';
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
        return 'Mi Perfil';
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
      title: Text(_getCurrentPageTitle(provider.currentPage)),
      actions: [
        if (provider.currentPage == AppPage.clientes)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => provider.startSearch(),
          ),
      ],
    );
  }

  AppBar _buildSearchAppBar(BuildContext context, NavigationProvider provider) {
    final theme = Theme.of(context);

    if (provider.searchQuery.isEmpty) {
      _searchController.clear();
    }

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          provider.stopSearch();
          _searchController.clear();
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Buscar...',
          border: InputBorder.none,
        ),
        onChanged: (query) => provider.updateSearchQuery(query),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.clear),
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
          appBar: isSearching && currentPage == AppPage.clientes
              ? _buildSearchAppBar(context, navigationProvider)
              : _buildDefaultAppBar(context, navigationProvider),
          drawer: const AppDrawer(),
          body: _buildCurrentPage(currentPage),
          floatingActionButton: (currentPage == AppPage.clientes && !isSearching)
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const ClienteEditPage()),
                    );
                  },
                  tooltip: 'Nuevo Cliente',
                  child: const Icon(Icons.person_add_alt_1_rounded),
                )
              : null,
        );
      },
    );
  }
}
