// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tarifas_dao.dart';

// ignore_for_file: type=lint
mixin _$TarifasDaoMixin on DatabaseAccessor<AppDatabase> {
  $TarifasTable get tarifas => attachedDatabase.tarifas;
  TarifasDaoManager get managers => TarifasDaoManager(this);
}

class TarifasDaoManager {
  final _$TarifasDaoMixin _db;
  TarifasDaoManager(this._db);
  $$TarifasTableTableManager get tarifas =>
      $$TarifasTableTableManager(_db.attachedDatabase, _db.tarifas);
}
