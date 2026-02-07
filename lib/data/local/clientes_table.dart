import 'package:drift/drift.dart';
import 'package:myapp/data/local/tarifas_table.dart';

@DataClassName('Cliente')
class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get odooId => integer().unique().nullable()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get city => text().nullable()();
  IntColumn get tarifaId => integer().nullable().references(Tarifas, #odooId)();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
