
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// 1. Convert to StatefulWidget to safely handle context after async operations
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

    // 2. Remove the Scaffold. This widget is the 'body' of the MainScaffold.
    //    It should only return the content that goes inside the body.
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        // Tarjeta de Información del Usuario
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
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Tarjeta de Detalles de la Sesión
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

        // Botón de Cerrar Sesión
        ElevatedButton.icon(
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
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
                        // 3. Add 'mounted' check before using context to prevent runtime error
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
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods are now part of the State class
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
    );
  }
}
