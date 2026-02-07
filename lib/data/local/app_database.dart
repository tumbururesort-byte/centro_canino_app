import 'package:drift/drift.dart';
import 'connection/mobile.dart';
import 'clientes_table.dart';
import 'dao/clientes_dao.dart';
import 'tarifas_table.dart';
import 'dao/tarifas_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Clientes, Tarifas], daos: [ClientesDao, TarifasDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(openConnection());

  static final AppDatabase _instance = AppDatabase._();

  static AppDatabase get instance => _instance;

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        for (final table in allTables) {
          await m.drop(table);
        }

        for (final table in allTables) {
          await m.create(table);
        }
      },
       beforeOpen: (details) async {
        if (details.hadUpgrade) {
          // Este bloque se ejecuta si hubo una actualización de esquema.
          // Aquí puedes poblar datos iniciales si es necesario.
        }
      },
    );
  }
}
