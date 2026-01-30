
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import 'app_drawer.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // AppBar en estado normal
  AppBar _buildNormalAppBar(BuildContext context, NavigationProvider provider) {
    return AppBar(
      title: Text(provider.currentPageTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
      ],
    );
  }

  // AppBar cuando se activa la búsqueda
  AppBar _buildSearchAppBar(BuildContext context, NavigationProvider provider) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            // Notificamos al provider que la búsqueda ha terminado
            provider.updateSearchQuery('');
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true, // El cursor aparece automáticamente
        decoration: const InputDecoration(
          hintText: 'Buscar...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 18),
        onChanged: (query) {
          // Notificamos al provider cada vez que el texto cambia
          provider.updateSearchQuery(query);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos 'consumer' para tener acceso tanto al valor como para no redibujar todo
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          appBar: _isSearching 
              ? _buildSearchAppBar(context, navigationProvider)
              : _buildNormalAppBar(context, navigationProvider),
          drawer: _isSearching ? null : const AppDrawer(), // Ocultamos el drawer al buscar
          body: navigationProvider.currentPage,
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
