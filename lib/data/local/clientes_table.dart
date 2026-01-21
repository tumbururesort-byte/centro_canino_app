import 'package:drift/drift.dart';

class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get odooId => integer().nullable().unique()(); // ID remoto
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get city => text().nullable()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSync => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}