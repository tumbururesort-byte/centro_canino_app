import 'package:drift/drift.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/data/local/pet_types_table.dart';

part 'pet_types_dao.g.dart';

@DriftAccessor(tables: [PetTypes])
class PetTypesDao extends DatabaseAccessor<AppDatabase> with _$PetTypesDaoMixin {
  PetTypesDao(super.db);

  Stream<List<PetType>> watchAllPetTypes() => select(petTypes).watch();
  Future<List<PetType>> getAllPetTypes() => select(petTypes).get();

  Future<void> insertOrUpdateAll(List<PetTypesCompanion> petTypeList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(petTypes, petTypeList);
    });
  }

  Future<void> insertPetType(PetTypesCompanion petType) =>
      into(petTypes).insert(petType);

  Future<void> updatePetType(PetType petType) =>
      update(petTypes).replace(petType);
      
  Future<void> deletePetType(PetType petType) =>
      delete(petTypes).delete(petType);
}
