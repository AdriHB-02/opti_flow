import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:opti_flow/core/errors/data_source_exception.dart';
import 'package:opti_flow/core/errors/failures.dart';
import 'package:opti_flow/features/campanas/data/datasources/local_campana_data_source.dart';
import 'package:opti_flow/features/campanas/data/models/campana_dto.dart';
import 'package:opti_flow/features/campanas/data/repositories/campana_repository.dart';
import 'package:opti_flow/features/campanas/domain/entities/campana_entity.dart';

class MockLocalCampanaDataSource extends Mock implements LocalCampanaDataSource {}

class _CampanaDTOFake extends Fake implements CampanaDTO {}

void main() {
  setUpAll(() {
    registerFallbackValue(_CampanaDTOFake());
  });
  late MockLocalCampanaDataSource mockDataSource;
  late CampanaRepository repository;

  final now = DateTime.now();
  final testId = const Uuid().v4();
  final testEmpresaId = const Uuid().v4();
  final testDoctorId = const Uuid().v4();

  final testEntity = CampanaEntity(
    id: testId,
    empresaId: testEmpresaId,
    nombreEmpresa: 'Empresa Test',
    lugar: 'Ciudad Test',
    fechaInicio: now,
    fechaFin: now.add(const Duration(days: 30)),
    creadoPor: testDoctorId,
    estado: CampanaEstado.activa,
    createdAt: now,
  );

  final testDto = CampanaDTO.fromEntity(testEntity);

  setUp(() {
    mockDataSource = MockLocalCampanaDataSource();
    repository = CampanaRepository(localDataSource: mockDataSource);
  });

  group('createCampana', () {
    test('debe retornar Right(entity) cuando el DataSource inserta ok', () async {
      when(() => mockDataSource.insertCampana(any())).thenAnswer((_) async {});

      final result = await repository.createCampana(testEntity);

      expect(result, isA<Right<Failure, CampanaEntity>>());
      expect(result.getOrElse(() => testEntity).id, testId);
      verify(() => mockDataSource.insertCampana(any())).called(1);
    });

    test('debe retornar Left(CacheFailure) cuando falla', () async {
      when(() => mockDataSource.insertCampana(any()))
          .thenThrow(DataSourceException('Error'));

      final result = await repository.createCampana(testEntity);

      expect(result, isA<Left<Failure, CampanaEntity>>());
    });
  });

  group('getCampanasByDoctor', () {
    test('debe retornar Right con lista de campañas', () async {
      when(() => mockDataSource.getCampanasByDoctor(any()))
          .thenAnswer((_) async => [testDto]);

      final result = await repository.getCampanasByDoctor(testDoctorId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).length, 1);
      expect(result.getOrElse(() => []).first.nombreEmpresa, 'Empresa Test');
      verify(() => mockDataSource.getCampanasByDoctor(testDoctorId)).called(1);
    });

    test('debe retornar Right con lista vacía si no hay campañas', () async {
      when(() => mockDataSource.getCampanasByDoctor(any()))
          .thenAnswer((_) async => []);

      final result = await repository.getCampanasByDoctor(testDoctorId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('debe retornar Left(CacheFailure) cuando falla', () async {
      when(() => mockDataSource.getCampanasByDoctor(any()))
          .thenThrow(DataSourceException('Error'));

      final result = await repository.getCampanasByDoctor(testDoctorId);

      expect(result.isLeft(), true);
    });
  });

  group('checkHistorialPrevio', () {
    test('debe retornar Right(true) cuando existe duplicado', () async {
      when(() => mockDataSource.checkDuplicate(any(), any()))
          .thenAnswer((_) async => true);

      final result = await repository.checkHistorialPrevio('Empresa Test', 'Lugar');

      expect(result.isRight(), true);
      expect(result.getOrElse(() => false), true);
    });

    test('debe retornar Right(false) cuando no existe duplicado', () async {
      when(() => mockDataSource.checkDuplicate(any(), any()))
          .thenAnswer((_) async => false);

      final result = await repository.checkHistorialPrevio('Nueva', 'Otro');

      expect(result.isRight(), true);
      expect(result.getOrElse(() => true), false);
    });

    test('debe retornar Left(CacheFailure) cuando falla', () async {
      when(() => mockDataSource.checkDuplicate(any(), any()))
          .thenThrow(DataSourceException('Error'));

      final result = await repository.checkHistorialPrevio('X', 'Y');

      expect(result.isLeft(), true);
    });
  });

  group('assignDoctor', () {
    test('debe retornar Right(null) cuando la asignación es exitosa', () async {
      when(() => mockDataSource.assignDoctor(any(), any()))
          .thenAnswer((_) async {});

      final result = await repository.assignDoctor(testId, testDoctorId);

      expect(result.isRight(), true);
      verify(() => mockDataSource.assignDoctor(testId, testDoctorId)).called(1);
    });

    test('debe retornar Left(CacheFailure) cuando falla', () async {
      when(() => mockDataSource.assignDoctor(any(), any()))
          .thenThrow(DataSourceException('Error'));

      final result = await repository.assignDoctor(testId, testDoctorId);

      expect(result.isLeft(), true);
    });
  });
}
