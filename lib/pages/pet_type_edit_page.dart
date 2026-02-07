import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/pet_types_provider.dart';
import 'package:myapp/data/local/app_database.dart';

class PetTypeEditPage extends StatefulWidget {
  final PetType? petType;

  const PetTypeEditPage({super.key, this.petType});

  @override
  State<PetTypeEditPage> createState() => _PetTypeEditPageState();
}

class _PetTypeEditPageState extends State<PetTypeEditPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;

  @override
  void initState() {
    super.initState();
    _name = widget.petType?.name ?? '';
  }

  Future<void> _deletePetType() async {
    if (widget.petType == null) return;
    final provider = context.read<PetTypesProvider>();
    await provider.deletePetType(widget.petType!); 
    if (mounted) {
        Navigator.of(context).pop();
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      final provider = context.read<PetTypesProvider>();
      try {
        if (widget.petType == null) {
          await provider.createPetType(_name);
        } else {
          final updatedPetType = widget.petType!.copyWith(name: _name);
          await provider.updatePetType(updatedPetType);
        }
        if (mounted) {
            Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error guardando la raza: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petType == null ? 'Nueva Raza' : 'Editar Raza'),
        actions: [
          if (widget.petType != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePetType,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, introduce un nombre';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
