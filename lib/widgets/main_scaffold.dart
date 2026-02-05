import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/pages/cliente_edit_page.dart';
import '../providers/navigation_provider.dart';
import '../pages/clientes_page.dart';
import '../pages/profile_page.dart';
import '../theme/app_theme.dart';
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
        return 'Perfil';
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
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        _getCurrentPageTitle(provider.currentPage),
        style: context.textTheme.titleLarge,
      ),
      actions: [
        if (provider.currentPage == AppPage.clientes) ...[
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () => provider.startSearch(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            color: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (value) {
              if (value == 'sync') {
                // Implementar sincronización manual
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync, color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Sincronizar',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  AppBar _buildSearchAppBar(BuildContext context, NavigationProvider provider) {
    if (provider.searchQuery.isEmpty) {
      _searchController.clear();
    }

    return AppBar(
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () {
          provider.stopSearch();
          _searchController.clear();
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Buscar...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
        onChanged: (query) => provider.updateSearchQuery(query),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textPrimary),
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
          backgroundColor: AppColors.backgroundDark,
          appBar: isSearching && currentPage == AppPage.clientes
              ? _buildSearchAppBar(context, navigationProvider)
              : _buildDefaultAppBar(context, navigationProvider),
          drawer: const AppDrawer(),
          body: _buildCurrentPage(currentPage),
          floatingActionButton: (currentPage == AppPage.clientes && !isSearching)
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const ClienteEditPage(),
                      ),
                    );
                  },
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  child: const Icon(Icons.person_add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }
}