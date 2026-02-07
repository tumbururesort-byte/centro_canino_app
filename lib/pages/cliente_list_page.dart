import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/clientes_provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/pages/cliente_edit_page.dart';
import 'package:myapp/pages/tarifas_list_page.dart';
import 'package:myapp/pages/profile_page.dart';
import 'package:myapp/pages/pet_type_list_page.dart';
import 'package:myapp/theme/app_theme.dart';

class ClienteListPage extends StatefulWidget {
  const ClienteListPage({super.key});

  @override
  State<ClienteListPage> createState() => _ClienteListPageState();
}

class _ClienteListPageState extends State<ClienteListPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  AppBar _buildAppBar(BuildContext context, ClientesProvider provider) {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textSecondary.withAlpha(204)),
              ),
              style: context.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
            )
          : Text('Clientes', style: context.textTheme.titleLarge),
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      actions: _isSearching
          ? [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _isSearching = true),
                tooltip: 'Buscar Cliente',
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: provider.isLoading ? null : () => provider.syncAllData(), // Corregido
                tooltip: 'Sincronizar Todo',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'tarifas') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TarifasListPage()),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'tarifas',
                    child: Text('Gestionar Tarifas'),
                  ),
                ],
              ),
            ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userName = authProvider.userName ?? 'N/A';

    return Drawer(
      backgroundColor: AppColors.surfaceDark,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppColors.surfaceDark),
                  child: Center(
                    child: Text(
                      'Tumburú',
                      style: context.textTheme.headlineMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.people_alt, color: AppColors.primary),
                  title: Text('Clientes', style: context.textTheme.titleMedium),
                  selected: true,
                  onTap: () => Navigator.pop(context), 
                ),
                ListTile(
                  leading: const Icon(Icons.pets, color: AppColors.primary),
                  title: Text('Razas', style: context.textTheme.titleMedium),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PetTypeListPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.backgroundDark, thickness: 1),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.getAvatarColor(userName),
              radius: 18,
              child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            title: Text(userName, style: context.textTheme.titleMedium),
            subtitle: Text('Mi Perfil', style: context.textTheme.bodySmall),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientesProvider>();
    final todosLosClientes = provider.clientes;
    final tarifas = provider.tarifas;
    final tarifaMap = {for (var t in tarifas) t.odooId: t.name};

    final searchQuery = _searchController.text.toLowerCase();
    final clientesFiltrados = searchQuery.isEmpty
        ? todosLosClientes
        : todosLosClientes.where((cliente) {
            final nombre = cliente.name.toLowerCase();
            final telefono = cliente.phone?.toLowerCase() ?? '';
            return nombre.contains(searchQuery) || telefono.contains(searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(context, provider),
      drawer: _buildDrawer(context), 
      body: RefreshIndicator(
        onRefresh: () => provider.syncAllData(), // Corregido
        child: Column(
          children: [
            if (provider.isLoading || provider.syncMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.isLoading) const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3)),
                    const SizedBox(width: 8),
                    Flexible(child: Text(provider.syncMessage ?? '', style: context.textTheme.bodySmall)),
                  ],
                ),
              ),
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(provider.error!, style: TextStyle(color: AppColors.error)),
              ),
            Expanded(
              child: clientesFiltrados.isEmpty
                  ? Center(child: Text(_isSearching ? 'No se encontraron resultados' : 'No hay clientes', style: context.textTheme.bodyLarge))
                  : ListView.builder(
                      itemCount: clientesFiltrados.length,
                      itemBuilder: (context, index) {
                        final cliente = clientesFiltrados[index];
                        final tarifaNombre = tarifaMap[cliente.tarifaId] ?? 'Sin tarifa';
                        final telefono = cliente.phone?.isNotEmpty == true ? cliente.phone : 'Sin teléfono';
                        
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: AppColors.surfaceDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.getAvatarColor(cliente.name),
                              child: Text(cliente.name.isNotEmpty ? cliente.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(cliente.name, style: context.textTheme.titleMedium),
                            subtitle: Text(
                              '$telefono - $tarifaNombre',
                              style: context.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              cliente.pendingSync
                                  ? Icons.sync
                                  : (cliente.odooId != null ? Icons.cloud_done : Icons.cloud_off),
                              color: cliente.pendingSync ? AppColors.primary : AppColors.textSecondary,
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (c) => ClienteEditPage(cliente: cliente)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (c) => const ClienteEditPage()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
