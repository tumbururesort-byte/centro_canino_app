import 'package:drift/drift.dart';

@DataClassName('Tarifa')
class Tarifas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get odooId => integer().unique()();
  TextColumn get name => text()();
}
