import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/clientes_provider.dart';
import 'package:myapp/providers/tarifas_provider.dart';
import 'package:myapp/theme/app_theme.dart';

class TarifasListPage extends StatelessWidget {
  const TarifasListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tarifasProvider = context.watch<TarifasProvider>();
    final clientesProvider = context.watch<ClientesProvider>();
    final tarifas = tarifasProvider.tarifas;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Gestionar Tarifas', style: context.textTheme.titleLarge),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: clientesProvider.isLoading
                ? null
                : () => clientesProvider.syncAllData(),
            tooltip: 'Sincronizar Todo',
          ),
        ],
      ),
      body: Column(
        children: [
          if (clientesProvider.isLoading || clientesProvider.syncMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (clientesProvider.isLoading)
                    const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(clientesProvider.syncMessage ?? '', style: context.textTheme.bodySmall)),
                ],
              ),
            ),
          if (clientesProvider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(clientesProvider.error!, style: TextStyle(color: AppColors.error)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => clientesProvider.syncAllData(),
              child: ListView.builder(
                itemCount: tarifas.length,
                itemBuilder: (context, index) {
                  final tarifa = tarifas[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: AppColors.surfaceDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(tarifa.name, style: context.textTheme.titleMedium),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
