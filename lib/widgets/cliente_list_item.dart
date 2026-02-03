
import 'package:flutter/material.dart';
import '../data/local/app_database.dart';

class ClienteListItem extends StatelessWidget {
  final Cliente cliente;

  const ClienteListItem({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            cliente.name.isNotEmpty ? cliente.name[0].toUpperCase() : '?',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(cliente.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cliente.email?.isNotEmpty ?? false)
              Text(cliente.email!),

            if (cliente.phone?.isNotEmpty ?? false)
              Text(cliente.phone!),

            if (cliente.city?.isNotEmpty ?? false)
              Text(cliente.city!),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(context, '/cliente_detalle', arguments: cliente.id);
        },
      ),
    );
  }
}
