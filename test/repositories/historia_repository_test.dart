import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:opti_flow/core/errors/data_source_exception.dart';
import 'package:opti_flow/core/errors/failures.dart';
import 'package:opti_flow/features/patients/data/datasources/local_historia_data_source.dart';
import 'package:opti_flow/features/patients/data/models/historia_clinica_dto.dart';
import 'package:opti_flow/features/patients/data/repositories/historia_repository.dart';
import 'package:opti_flow/features/patients/domain/entities/historia_clinica_entity.dart';

class MockLocalHistoriaDataSource extends Mock implements LocalHistoriaDataSource {}

class _HistoriaDTOFake extends Fake implements HistoriaClinicaDTO {}

void main() {
  setUpAll(() {
    registerFallbackValue(_HistoriaDTOFake());
  });
  late MockLocalHistoriaDataSource mockDataSource;
  late HistoriaRepository repository;

  final now = DateTime.now();
  final testId = const Uuid().v4();
  final testPacienteId = const Uuid().v4();
  final testCampanaId = const Uuid().v4();
  final testDoctorId = const Uuid().v4();

  final testEntity = HistoriaClinicaEntity(
    id: testId,
    pacienteId: testPacienteId,
    campanaId: testCampanaId,
    diagnosticoTexto: 'Miopía',
    imagenUrl: null,
    latitud: 19.43,
    longitud: -99.13,
    fechaAtencion: now,
    doctorId: testDoctorId,
    historiaAnteriorId: null,
    sincronizado: false,
    createdAt: now,
  );

  final testDto = HistoriaClinicaDTO.fromEntity(testEntity);

  setUp(() {
    mockDataSource = MockLocalHistoriaDataSource();
    repository = HistoriaRepository(localDataSource: mockDataSource);
  });

  group('saveHistoria', () {
    test('debe retornar Right(entity) cuando el DataSource inserta ok', () async {
      when(() => mockDataSource.insertHistoria(any())).thenAnswer((_) async {});

      final result = await repository.saveHistoria(testEntity);

      expect(result, isA<Right<Failure, HistoriaClinicaEntity>>());
      expect(result.getOrElse(() => testEntity).id, testId);
      verify(() => mockDataSource.insertHistoria(any())).called(1);
    });

    test('debe retornar Left(CacheFailure) cuando falla', () async {
      when(() => mockDataSource.insertHistoria(any()))
          .thenThrow(DataSourceException('Error'));

      final result = await repository.saveHistoria(testEntity);

      expect(result, isA<Left<Failure, HistoriaClinicaEntity>>());
    });
  });

  group('getHistoriasByPaciente', () {
    test('debe retornar Right con lista de historias', () async {
      when(() => mockDataSource.getByPaciente(any(), any()))
          .thenAnswer((_) async => [testDto]);

      final result =
          await repository.getHistoriasByPaciente(testPacienteId, testDoctorId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).length, 1);
      expect(result.getOrElse(() => []).first.diagnosticoTexto, 'Miopía');
      verify(() => mockDataSource.getByPaciente(testPacienteId, testDoctorId))
          .called(1);
    });

    test('debe retornar Right con lista vacía si no hay historias', () async {
      when(() => mockDataSource.getByPaciente(any(), any()))
          .thenAnswer((_) async => []);

      final result =
          await repository.getHistoriasByPaciente(testPacienteId, testDoctorId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('debe retornar Left(CacheFailure) cuando falla', () async {
      when(() => mockDataSource.getByPaciente(any(), any()))
          .thenThrow(DataSourceException('Error'));

      final result =
          await repository.getHistoriasByPaciente(testPacienteId, testDoctorId);

      expect(result.isLeft(), true);
    });
  });

  group('getHistoriaAnterior', () {
    test('debe retornar Right(historia) cuando existe', () async {
      when(() => mockDataSource.getAnterior(any(), any()))
          .thenAnswer((_) async => testDto);

      final result = await repository.getHistoriaAnterior(
        testPacienteId,
        testCampanaId,
      );

      expect(result.isRight(), true);
      expect(result.getOrElse(() => null), isNotNull);
      expect(result.getOrElse(() => testEntity)!.diagnosticoTexto, 'Miopía');
      verify(() => mockDataSource.getAnterior(testPacienteId, testCampanaId))
          .called(1);
    });

    test('debe retornar Right(null) cuando no existe anterior', () async {
      when(() => mockDataSource.getAnterior(any(), any()))
          .thenAnswer((_) async => null);

      final result = await repository.getHistoriaAnterior(
        testPacienteId,
        testCampanaId,
      );

      expect(result.isRight(), true);
      expect(result.getOrElse(() => null), isNull);
    });

    test('debe retornar Left(CacheFailure) cuando falla', () async {
      when(() => mockDataSource.getAnterior(any(), any()))
          .thenThrow(DataSourceException('Error'));

      final result = await repository.getHistoriaAnterior(
        testPacienteId,
        testCampanaId,
      );

      expect(result.isLeft(), true);
    });
  });
}
