
import 'package:flutter/material.dart';
import '../data/local/app_database.dart';

class ClienteListItem extends StatelessWidget {
  final Cliente cliente;

  const ClienteListItem({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            cliente.name.isNotEmpty ? cliente.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(cliente.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comprobación de nulabilidad y vacío
            if (cliente.email?.isNotEmpty ?? false)
              Text(cliente.email!),

            // Comprobación de nulabilidad y vacío
            if (cliente.phone?.isNotEmpty ?? false)
              Text(cliente.phone!),

            // Comprobación de nulabilidad y vacío
            if (cliente.city?.isNotEmpty ?? false)
              Text(cliente.city!),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navegar a la página de detalles del cliente
          Navigator.pushNamed(context, '/cliente_detalle', arguments: cliente.id);
        },
      ),
    );
  }
}
