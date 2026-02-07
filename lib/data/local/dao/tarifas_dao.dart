import 'package:drift/drift.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/data/local/tarifas_table.dart';

part 'tarifas_dao.g.dart';

@DriftAccessor(tables: [Tarifas])
class TarifasDao extends DatabaseAccessor<AppDatabase> with _$TarifasDaoMixin {
  TarifasDao(super.db);

  Stream<List<Tarifa>> watchAllTarifas() => select(tarifas).watch();

  Future<void> insertOrUpdateAll(List<TarifasCompanion> tarifasList) {
    return batch((batch) {
      batch.insertAll(
        tarifas,
        tarifasList,
        mode: InsertMode.insertOrReplace,
      );
    });
  }
}
