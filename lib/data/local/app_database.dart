import 'package:drift/drift.dart';
import 'connection/mobile.dart';
import 'clientes_table.dart';
import 'dao/clientes_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Clientes], daos: [ClientesDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(openConnection());

  static final AppDatabase _instance = AppDatabase._();

  static AppDatabase get instance => _instance;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        // La forma correcta es usar `allTables` de la propia base de datos.
        // Primero, borramos todas las tablas.
        for (final table in allTables) {
          await m.drop(table);
        }

        // Luego, las volvemos a crear.
        for (final table in allTables) {
          await m.create(table);
        }
      },
    );
  }
}
