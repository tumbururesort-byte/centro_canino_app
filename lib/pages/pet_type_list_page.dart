import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/pet_types_provider.dart';
import 'package:myapp/pages/pet_type_edit_page.dart';

class PetTypeListPage extends StatelessWidget {
  const PetTypeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final petTypesProvider = Provider.of<PetTypesProvider>(context);
    final petTypes = petTypesProvider.petTypes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Razas de Mascotas'),
      ),
      body: ListView.builder(
        itemCount: petTypes.length,
        itemBuilder: (context, index) {
          final petType = petTypes[index];
          return ListTile(
            title: Text(petType.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PetTypeEditPage(petType: petType),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PetTypeEditPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
