import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:opti_flow/core/errors/data_source_exception.dart';
import 'package:opti_flow/core/errors/failures.dart';
import 'package:opti_flow/features/patients/data/datasources/local_patient_data_source.dart';
import 'package:opti_flow/features/patients/data/models/patient_dto.dart';
import 'package:opti_flow/features/patients/data/repositories/patient_repository.dart';
import 'package:opti_flow/features/patients/domain/entities/patient_entity.dart';

class MockLocalPatientDataSource extends Mock implements LocalPatientDataSource {}

class _PatientDTOFake extends Fake implements PatientDTO {}

void main() {
  setUpAll(() {
    registerFallbackValue(_PatientDTOFake());
  });
  late MockLocalPatientDataSource mockDataSource;
  late PatientRepository repository;

  final now = DateTime.now();
  final testId = const Uuid().v4();
  final testDepId = const Uuid().v4();
  final testDoctorId = const Uuid().v4();

  final testEntity = PatientEntity(
    id: testId,
    nombreCompleto: 'Juan Test',
    dependenciaId: testDepId,
    doctorId: testDoctorId,
    esReconsulta: false,
    createdAt: now,
    updatedAt: now,
  );

  final testDto = PatientDTO.fromEntity(testEntity);

  setUp(() {
    mockDataSource = MockLocalPatientDataSource();
    repository = PatientRepository(localDataSource: mockDataSource);
  });

  group('savePatient', () {
    test('debe retornar Right(entity) cuando el DataSource inserta ok', () async {
      when(() => mockDataSource.insertPatient(any())).thenAnswer((_) async {});

      final result = await repository.savePatient(testEntity);

      expect(result, isA<Right<Failure, PatientEntity>>());
      expect(result.getOrElse(() => testEntity).id, testId);
      verify(() => mockDataSource.insertPatient(any())).called(1);
    });

    test('debe retornar Left(CacheFailure) cuando el DataSource lanza excepción',
        () async {
      when(() => mockDataSource.insertPatient(any()))
          .thenThrow(DataSourceException('Error DB'));

      final result = await repository.savePatient(testEntity);

      expect(result, isA<Left<Failure, PatientEntity>>());
      expect(result.fold((l) => l, (r) => null), isA<CacheFailure>());
    });
  });

  group('getPatients', () {
    test('debe retornar Right con lista de entidades', () async {
      when(() => mockDataSource.getPatients(any(), any()))
          .thenAnswer((_) async => [testDto]);

      final result = await repository.getPatients(testDepId, testDoctorId);

      expect(result.isRight(), true);
      final patients = result.getOrElse(() => []);
      expect(patients.length, 1);
      expect(patients.first.nombreCompleto, 'Juan Test');
      verify(() => mockDataSource.getPatients(testDepId, testDoctorId))
          .called(1);
    });

    test('debe retornar Left(CacheFailure) cuando falla', () async {
      when(() => mockDataSource.getPatients(any(), any()))
          .thenThrow(DataSourceException('Error'));

      final result = await repository.getPatients(testDepId, testDoctorId);

      expect(result.isLeft(), true);
    });
  });

  group('searchByName', () {
    test('debe retornar Right con resultados filtrados', () async {
      when(() => mockDataSource.searchByName(any(), any(), any()))
          .thenAnswer((_) async => [testDto]);

      final result =
          await repository.searchByName('Juan', testDepId, testDoctorId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).length, 1);
      verify(
        () => mockDataSource.searchByName('Juan', testDepId, testDoctorId),
      ).called(1);
    });

    test('debe retornar Left(CacheFailure) cuando falla', () async {
      when(() => mockDataSource.searchByName(any(), any(), any()))
          .thenThrow(DataSourceException('Error'));

      final result =
          await repository.searchByName('Juan', testDepId, testDoctorId);

      expect(result.isLeft(), true);
    });
  });

  group('getPatientById', () {
    test('debe retornar Right(entity) cuando existe', () async {
      when(() => mockDataSource.getPatientById(any()))
          .thenAnswer((_) async => testDto);

      final result = await repository.getPatientById(testId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => testEntity).nombreCompleto, 'Juan Test');
      verify(() => mockDataSource.getPatientById(testId)).called(1);
    });

    test('debe retornar Left(CacheFailure) cuando no existe', () async {
      when(() => mockDataSource.getPatientById(any()))
          .thenAnswer((_) async => null);

      final result = await repository.getPatientById('no-existe');

      expect(result.isLeft(), true);
      expect(
        result.fold((l) => (l as CacheFailure).message, (r) => ''),
        'Paciente no encontrado',
      );
    });

    test('debe retornar Left(CacheFailure) cuando falla la BD', () async {
      when(() => mockDataSource.getPatientById(any()))
          .thenThrow(DataSourceException('Error'));

      final result = await repository.getPatientById(testId);

      expect(result.isLeft(), true);
    });
  });
}
