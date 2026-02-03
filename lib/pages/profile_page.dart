
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  authProvider.userName ?? 'Nombre no disponible',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  authProvider.userLogin ?? 'Login no disponible',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionTitle(context, 'Detalles de la Conexión'),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.cloud_queue,
                title: 'Servidor',
                subtitle: authProvider.serverUrl ?? 'No disponible',
              ),
              const Divider(height: 1),
               _buildInfoTile(
                icon: Icons.storage,
                title: 'Base de Datos',
                subtitle: authProvider.dbName ?? 'No disponible',
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar Sesión'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext ctx) {
                return AlertDialog(
                  title: const Text('Confirmar'),
                  content: const Text('¿Estás seguro de que quieres cerrar la sesión?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    FilledButton(
                      child: const Text('Cerrar Sesión'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        context.read<AuthProvider>().logout(); 
                      },
                    ),
                  ],
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: theme.textTheme.bodyLarge),
    );
  }
}
