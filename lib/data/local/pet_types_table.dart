import 'package:drift/drift.dart';

@DataClassName('PetType')
class PetTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get odooId => integer().unique()();
  TextColumn get name => text()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
}
