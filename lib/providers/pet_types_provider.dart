import 'package:flutter/material.dart';
import 'package:myapp/data/app_data_repository.dart';
import 'package:myapp/data/local/app_database.dart';
import 'dart:async';

class PetTypesProvider with ChangeNotifier {
  final AppDataRepository _repository;
  List<PetType> _petTypes = [];
  StreamSubscription? _petTypesSubscription;

  PetTypesProvider({required AppDataRepository repository}) : _repository = repository {
    _listenToPetTypesStream();
  }

  List<PetType> get petTypes => _petTypes;

  void _listenToPetTypesStream() {
    _petTypesSubscription?.cancel();
    _petTypesSubscription = _repository.watchPetTypes().listen((petTypes) {
      _petTypes = petTypes;
      notifyListeners();
    });
  }

  Future<void> createPetType(String name) async {
    if (name.trim().isEmpty) throw Exception('El nombre es obligatorio');
    await _repository.createPetType(name.trim());
  }

  Future<void> updatePetType(PetType petType) async {
    if (petType.name.trim().isEmpty) throw Exception('El nombre es obligatorio');
    await _repository.updatePetType(petType);
  }

  Future<void> deletePetType(PetType petType) async {
    await _repository.deletePetType(petType);
  }

  @override
  void dispose() {
    _petTypesSubscription?.cancel();
    super.dispose();
  }
}
