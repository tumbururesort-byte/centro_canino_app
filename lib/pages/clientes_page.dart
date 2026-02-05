import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/pages/cliente_edit_page.dart';
import 'package:myapp/providers/clientes_provider.dart';
import 'package:myapp/providers/navigation_provider.dart';
import 'package:myapp/theme/app_theme.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ClientesView();
  }
}

void _navigateToCliente(BuildContext context, {Cliente? cliente}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => ClienteEditPage(cliente: cliente),
    ),
  );
}

class _ClientesView extends StatefulWidget {
  const _ClientesView();

  @override
  State<_ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<_ClientesView> {
  Timer? _messageTimer;

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientesProvider>(
      builder: (context, provider, child) {
        final filteredClientes = _filterClientes(
          provider.clientes,
          context.watch<NavigationProvider>().searchQuery,
        );

        return Container(
          color: AppColors.backgroundDark,
          child: Column(
            children: [
              _buildSyncStatus(provider),
              Expanded(
                child: provider.isLoading && provider.clientes.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.syncClientes(),
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceDark,
                        child: filteredClientes.isEmpty
                            ? _buildEmptyState(
                                context.watch<NavigationProvider>().searchQuery,
                              )
                            : _buildClientesList(context, filteredClientes),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Cliente> _filterClientes(List<Cliente> clientes, String searchQuery) {
    if (searchQuery.isEmpty) return clientes;
    final query = searchQuery.toLowerCase();
    return clientes.where((c) {
      final name = c.name.toLowerCase();
      final email = c.email?.toLowerCase() ?? '';
      final phone = c.phone?.toLowerCase() ?? '';
      return name.contains(query) || email.contains(query) || phone.contains(query);
    }).toList();
  }

  Widget _buildSyncStatus(ClientesProvider provider) {
    if (provider.syncMessage == null) {
      return const SizedBox.shrink();
    }

    final message = provider.syncMessage!;
    final isLoading = provider.isLoading;
    final isError = message.startsWith('❌');

    if (!isLoading) {
      _messageTimer?.cancel();
      _messageTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          // El mensaje se limpiará automáticamente
        }
      });
    }

    return Container(
      color: isError ? AppColors.error : AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              if (!isLoading)
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String searchQuery) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                size: 80,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                searchQuery.isEmpty
                    ? 'No hay clientes'
                    : 'No se encontraron resultados',
                style: context.textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (searchQuery.isEmpty) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.read<ClientesProvider>().syncClientes(),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar ahora'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  ListView _buildClientesList(BuildContext context, List<Cliente> clientes) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: clientes.length,
      itemBuilder: (context, i) {
        final cliente = clientes[i];
        return Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider,
                width: 1,
              ),
            ),
          ),
          child: Material(
            color: AppColors.backgroundDark,
            child: InkWell(
              onTap: () => _navigateToCliente(context, cliente: cliente),
              splashColor: AppColors.surfaceDark,
              highlightColor: AppColors.surfaceDark,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Avatar con iniciales
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.getAvatarColor(cliente.name),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          cliente.name.isNotEmpty
                              ? cliente.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Información del cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.name,
                            style: context.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cliente.phone?.isNotEmpty == true
                                ? cliente.phone!
                                : cliente.email ?? 'Sin información',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}