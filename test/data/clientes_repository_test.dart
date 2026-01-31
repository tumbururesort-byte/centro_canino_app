
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/data/clientes_repository.dart';
import 'package:myapp/data/local/dao/clientes_dao.dart';
import 'package:myapp/data/remote/odoo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([OdooService, ClientesDao, SharedPreferences])
import 'clientes_repository_test.mocks.dart';

void main() {
  late MockOdooService mockOdooService;
  late MockClientesDao mockClientesDao;
  late MockSharedPreferences mockSharedPreferences;
  late ClientesRepository repository;

  setUp(() {
    mockOdooService = MockOdooService();
    mockClientesDao = MockClientesDao();
    mockSharedPreferences = MockSharedPreferences();
    repository = ClientesRepository(
      odooService: mockOdooService,
      clientesDao: mockClientesDao,
      sharedPreferences: mockSharedPreferences,
    );
  });

  group('syncClientes', () {
    final tClientesList = [
      {'id': 1, 'name': 'Cliente A', 'email': 'a@test.com', 'phone': '123', 'city': 'City A'},
      {'id': 2, 'name': 'Cliente B', 'email': 'b@test.com', 'phone': '456', 'city': 'City B'},
    ];

    // Test 1: PASSED
    test('debería pedir todos los clientes si no hay fecha de última sincronización', () async {
      // ... (código del test anterior)
      when(mockSharedPreferences.getString(any)).thenReturn(null);
      when(mockOdooService.fetchClientes(lastSync: null)).thenAnswer((_) async => tClientesList);
      when(mockClientesDao.insertOrUpdateAll(any)).thenAnswer((_) async => {});
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
      await repository.syncClientes();
      verify(mockOdooService.fetchClientes(lastSync: null)).called(1);
      verify(mockClientesDao.insertOrUpdateAll(any)).called(1);
      verify(mockSharedPreferences.setString(ClientesRepository.lastSyncTimestampKey, any)).called(1);
    });

    // Test 2: PASSED
    test('debería pedir clientes usando la fecha de la última sincronización si existe', () async {
      // ... (código del test anterior)
      final lastSyncTimestamp = '2024-01-01T12:00:00.000';
      final lastSyncDate = DateTime.parse(lastSyncTimestamp);
      when(mockSharedPreferences.getString(ClientesRepository.lastSyncTimestampKey)).thenReturn(lastSyncTimestamp);
      when(mockOdooService.fetchClientes(lastSync: anyNamed('lastSync'))).thenAnswer((_) async => []);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
      await repository.syncClientes();
      verify(mockOdooService.fetchClientes(lastSync: lastSyncDate)).called(1);
      verifyNever(mockClientesDao.insertOrUpdateAll(any));
    });

    // Test 3: NUEVO
    test('debería lanzar una excepción y no actualizar la fecha si Odoo falla', () async {
      // Arrange
      // 1. Simula un error en el servicio de Odoo
      final tException = Exception('Error de Red');
      when(mockOdooService.fetchClientes(lastSync: anyNamed('lastSync'))).thenThrow(tException);
      when(mockSharedPreferences.getString(any)).thenReturn(null); // No importa si hay fecha o no

      // Act & Assert
      // 1. Verifica que el mÃ©todo syncClientes lanza la excepciÃ³n
      expect(() => repository.syncClientes(), throwsA(isA<Exception>()));

      // 2. Verifica que NO se intentÃ³ guardar NADA en la BD local
      verifyNever(mockClientesDao.insertOrUpdateAll(any));

      // 3. Verifica que NO se actualizÃ³ la fecha de sincronizaciÃ³n
      verifyNever(mockSharedPreferences.setString(ClientesRepository.lastSyncTimestampKey, any));
    });
  });
}
