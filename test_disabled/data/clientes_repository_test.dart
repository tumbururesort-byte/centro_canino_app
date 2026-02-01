
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
  
  tearDown(() {
    repository.dispose();
  });

  group('syncClientes', () {
    final tClientesList = [
      {'id': 1, 'name': 'Cliente A', 'email': 'a@test.com', 'phone': '123', 'city': 'City A'},
      {'id': 2, 'name': 'Cliente B', 'email': 'b@test.com', 'phone': '456', 'city': 'City B'},
    ];

    test('debería sincronizar todos los clientes en bloques si no hay fecha previa', () async {
      // Arrange
      when(mockSharedPreferences.getString(any)).thenReturn(null);
      when(mockOdooService.countClientes(lastSync: null)).thenAnswer((_) async => 2);
      when(mockOdooService.fetchClientesChunk(lastSync: null, limit: anyNamed('limit'), offset: 0))
          .thenAnswer((_) async => tClientesList);
      when(mockClientesDao.insertOrUpdateAll(any)).thenAnswer((_) async => {});
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      // Act
      await repository.syncClientes();

      // Assert
      verify(mockOdooService.countClientes(lastSync: null)).called(1);
      verify(mockOdooService.fetchClientesChunk(lastSync: null, limit: anyNamed('limit'), offset: 0)).called(1);
      verify(mockClientesDao.insertOrUpdateAll(any)).called(1);
      verify(mockSharedPreferences.setString(ClientesRepository.lastSyncTimestampKey, any)).called(1);
    });

    test('debería finalizar rápidamente si no hay clientes nuevos para sincronizar', () async {
      // Arrange
      final lastSyncTimestamp = '2024-01-01T12:00:00.000';
      final lastSyncDate = DateTime.parse(lastSyncTimestamp);
      when(mockSharedPreferences.getString(ClientesRepository.lastSyncTimestampKey)).thenReturn(lastSyncTimestamp);
      when(mockOdooService.countClientes(lastSync: anyNamed('lastSync'))).thenAnswer((_) async => 0);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      // Act
      await repository.syncClientes();

      // Assert
      verify(mockOdooService.countClientes(lastSync: lastSyncDate)).called(1);
      verifyNever(mockOdooService.fetchClientesChunk(lastSync: anyNamed('lastSync'), limit: anyNamed('limit'), offset: anyNamed('offset')));
      verifyNever(mockClientesDao.insertOrUpdateAll(any));
      verify(mockSharedPreferences.setString(ClientesRepository.lastSyncTimestampKey, any)).called(1);
    });

    test('debería emitir un error en el stream y no hacer cambios si Odoo falla', () async {
      // Arrange
      final tException = Exception('Error de Red');
      when(mockOdooService.countClientes(lastSync: anyNamed('lastSync'))).thenThrow(tException);
      when(mockSharedPreferences.getString(any)).thenReturn(null);

      // Act & Assert
      expect(
        repository.progressStream,
        emitsInOrder([
          'Iniciando sincronización...',
          'Contando registros en Odoo...',
          startsWith('❌ Error'),
        ]),
      );

      await repository.syncClientes();

      verifyNever(mockOdooService.fetchClientesChunk(lastSync: anyNamed('lastSync'), limit: anyNamed('limit'), offset: anyNamed('offset')));
      verifyNever(mockClientesDao.insertOrUpdateAll(any));
      verifyNever(mockSharedPreferences.setString(ClientesRepository.lastSyncTimestampKey, any));
    });
  });
}
