import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userName = authProvider.userName ?? 'N/A';
    final userEmail = authProvider.userLogin ?? 'N/A';
    final serverUrl = authProvider.serverUrl ?? 'N/A';
    final dbName = authProvider.dbName ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Mi Perfil y Conexión', style: context.textTheme.titleLarge),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildUserInfoCard(context, userName, userEmail),
          const SizedBox(height: 20),
          _buildConnectionInfoCard(context, serverUrl, dbName),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            onPressed: () {
              // Cerramos esta pantalla y luego deslogueamos para evitar errores de estado
              Navigator.of(context).pop();
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, String userName, String userEmail) {
    return Card(
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.getAvatarColor(userName),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: context.textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Usuario', style: context.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(userName, style: context.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(userEmail, style: context.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInfoCard(BuildContext context, String serverUrl, String dbName) {
    return Card(
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalles de la Conexión', style: context.textTheme.titleMedium),
            const Divider(height: 20, color: AppColors.backgroundDark),
            ListTile(
              leading: const Icon(Icons.dns_outlined, color: AppColors.textSecondary),
              title: const Text('Servidor Odoo'),
              subtitle: Text(serverUrl, style: context.textTheme.bodyMedium?.copyWith(color: AppColors.primary)),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.storage_outlined, color: AppColors.textSecondary),
              title: const Text('Base de Datos'),
              subtitle: Text(dbName, style: context.textTheme.bodyMedium?.copyWith(color: AppColors.primary)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
