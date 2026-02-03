
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/pages/cliente_edit_page.dart';
import 'package:myapp/providers/clientes_provider.dart';
import 'package:myapp/providers/navigation_provider.dart';

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
            context.watch<NavigationProvider>().searchQuery
        );

        return Column(
          children: [
            _buildSyncStatus(provider),
            
            Expanded(
              child: provider.isLoading && provider.clientes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => provider.syncClientes(),
                      child: filteredClientes.isEmpty
                          ? _buildEmptyState(context.watch<NavigationProvider>().searchQuery)
                          : _buildClientesList(context, filteredClientes),
                    ),
            ),
          ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          // Implementación futura: El provider debería limpiar su propio mensaje.
        }
      });
    }
    
    return Material(
      elevation: 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
            gradient: isError
                ? null
                : LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: isError ? colorScheme.errorContainer : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  if (isLoading) SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)),
                  if (!isLoading) Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? colorScheme.error : colorScheme.onPrimary, size: 16),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message, style: theme.textTheme.bodySmall?.copyWith(color: isError ? colorScheme.onErrorContainer : colorScheme.onPrimary))),
                ],
              ),
              if (isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(String searchQuery) => ListView(
    children: [ 
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Icon(searchQuery.isEmpty ? Icons.people_outline : Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(searchQuery.isEmpty ? 'No hay clientes' : 'No se encontraron resultados', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 24),
            if (searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: () => context.read<ClientesProvider>().syncClientes(),
                icon: const Icon(Icons.sync),
                label: const Text('Sincronizar ahora'),
              )
          ],
        ),
      )
    ]
  );

  ListView _buildClientesList(BuildContext context, List<Cliente> clientes) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: clientes.length,
      itemBuilder: (context, i) {
        final cliente = clientes[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _navigateToCliente(context, cliente: cliente),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      cliente.name.isNotEmpty ? cliente.name[0].toUpperCase() : '?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (cliente.phone?.isNotEmpty == true)
                          Text(
                            cliente.phone!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
