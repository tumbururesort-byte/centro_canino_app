import 'package:drift/drift.dart';
import 'package:myapp/data/local/app_database.dart';
import 'package:myapp/data/local/clientes_table.dart';

part 'clientes_dao.g.dart';

@DriftAccessor(tables: [Clientes])
class ClientesDao extends DatabaseAccessor<AppDatabase> with _$ClientesDaoMixin {
  ClientesDao(super.db);

  Stream<List<Cliente>> watchAllClientes() => select(clientes).watch();

  Future<void> insertCliente(ClientesCompanion cliente) => into(clientes).insert(cliente);
  
  // Método para insertar/actualizar una lista de clientes.
  // Usado por el Repository para la sincronización.
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
}
