import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/tarifas_provider.dart';
import 'package:myapp/theme/app_theme.dart';

class TarifasListPage extends StatelessWidget {
  const TarifasListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TarifasProvider>();
    final tarifas = provider.tarifas;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Tarifas', style: context.textTheme.titleLarge),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: provider.isLoading ? null : () => provider.syncTarifas(),
            tooltip: 'Sincronizar Tarifas',
          ),
        ],
      ),
      body: Column(
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
            child: tarifas.isEmpty
                ? Center(child: Text('No hay tarifas disponibles', style: context.textTheme.bodyLarge))
                : ListView.builder(
                    itemCount: tarifas.length,
                    itemBuilder: (context, index) {
                      final tarifa = tarifas[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        color: AppColors.surfaceDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.local_offer, color: Colors.white, size: 20),
                          ),
                          title: Text(tarifa.name, style: context.textTheme.titleMedium),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
