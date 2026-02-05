import 'package:drift/drift.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/data/local/clientes_table.dart';

part 'clientes_dao.g.dart';

@DriftAccessor(tables: [Clientes])
class ClientesDao extends DatabaseAccessor<AppDatabase> with _$ClientesDaoMixin {
  ClientesDao(super.db);

  Stream<List<Cliente>> watchAllClientes() => (select(clientes)..where((c) => c.isDeleted.equals(false))).watch();

  Future<void> insertCliente(ClientesCompanion cliente) => into(clientes).insert(cliente);

  Future<void> insertOrUpdateAll(List<ClientesCompanion> clientesList) {
    return batch((batch) {
      batch.insertAll(
        clientes,
        clientesList,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> updateCliente(Cliente cliente) => update(clientes).replace(cliente);
  
  Future<void> deleteCliente(Cliente cliente) => delete(clientes).delete(cliente);

  Future<List<Cliente>> getClientesPendientes() {
    return (select(clientes)..where((c) => c.pendingSync.equals(true))).get();
  }
}
