import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final navigationProvider = context.read<NavigationProvider>();

    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildDrawerHeader(authProvider),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.people,
                  title: 'Clientes',
                  page: AppPage.clientes,
                  isSelected: navigationProvider.currentPage == AppPage.clientes,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_circle,
                  title: 'Mi Perfil',
                  page: AppPage.perfil,
                  isSelected: navigationProvider.currentPage == AppPage.perfil,
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            authProvider.userName ?? 'Usuario',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.userLogin ?? 'email@example.com',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required AppPage page,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceDark : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          context.read<NavigationProvider>().changePage(page);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.settings,
              color: AppColors.textSecondary,
              size: 24,
            ),
            title: const Text(
              'Configuración',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            onTap: () {
              // Implementar configuración
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}