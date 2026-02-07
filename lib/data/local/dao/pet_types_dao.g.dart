// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_types_dao.dart';

// ignore_for_file: type=lint
mixin _$PetTypesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PetTypesTable get petTypes => attachedDatabase.petTypes;
  PetTypesDaoManager get managers => PetTypesDaoManager(this);
}

class PetTypesDaoManager {
  final _$PetTypesDaoMixin _db;
  PetTypesDaoManager(this._db);
  $$PetTypesTableTableManager get petTypes =>
      $$PetTypesTableTableManager(_db.attachedDatabase, _db.petTypes);
}
