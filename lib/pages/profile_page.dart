import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clientes_provider.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Container(
      color: AppColors.backgroundDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildProfileHeader(authProvider),
          const SizedBox(height: 16),
          _buildSectionTitle('Información de la cuenta'),
          _buildInfoCard([
            _buildInfoTile(
              icon: Icons.person,
              title: 'Nombre',
              subtitle: authProvider.userName ?? 'No disponible',
            ),
            const Divider(color: AppColors.divider, height: 1),
            _buildInfoTile(
              icon: Icons.email,
              title: 'Usuario',
              subtitle: authProvider.userLogin ?? 'No disponible',
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('Conexión'),
          _buildInfoCard([
            _buildInfoTile(
              icon: Icons.cloud,
              title: 'Servidor',
              subtitle: authProvider.serverUrl ?? 'No disponible',
            ),
            const Divider(color: AppColors.divider, height: 1),
            _buildInfoTile(
              icon: Icons.storage,
              title: 'Base de datos',
              subtitle: authProvider.dbName ?? 'No disponible',
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('Sincronización'),
          _buildSyncButton(),
          const SizedBox(height: 32),
          _buildLogoutButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            authProvider.userName ?? 'Nombre no disponible',
            style: context.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.userLogin ?? 'Login no disponible',
            style: context.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: context.textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon, color: AppColors.textSecondary, size: 24),
      title: Text(
        title,
        style: context.textTheme.bodySmall,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () async {
            final provider = context.read<ClientesProvider>();
            await provider.syncClientes();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronización iniciada'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.sync, color: AppColors.textSecondary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sincronizar datos',
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Actualizar clientes desde el servidor',
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('CERRAR SESIÓN'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext ctx) {
                return AlertDialog(
                  backgroundColor: AppColors.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: const Text(
                    '¿Estás seguro de que quieres cerrar la sesión?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: AppColors.error),
                      ),
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
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}