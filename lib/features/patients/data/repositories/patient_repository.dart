import 'package:dartz/dartz.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/repositories/i_patient_repository.dart';
import '../datasources/local_patient_data_source.dart';
import '../models/patient_dto.dart';

class PatientRepository implements IPatientRepository {
  final LocalPatientDataSource _localDataSource;

  PatientRepository({required LocalPatientDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<PatientEntity>>> getPatients(
    String dependenciaId,
    String doctorId,
  ) async {
    try {
      final dtos = await _localDataSource.getPatients(dependenciaId, doctorId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener pacientes'));
    }
  }

  @override
  Future<Either<Failure, PatientEntity>> savePatient(
    PatientEntity patient,
  ) async {
    try {
      final dto = PatientDTO.fromEntity(patient);
      await _localDataSource.insertPatient(dto);
      return Right(patient);
    } on DataSourceException {
      return Left(CacheFailure('Error al guardar paciente'));
    }
  }

  @override
  Future<Either<Failure, List<PatientEntity>>> searchByName(
    String name,
    String dependenciaId,
    String doctorId,
  ) async {
    try {
      final dtos =
          await _localDataSource.searchByName(name, dependenciaId, doctorId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException {
      return Left(CacheFailure('Error al buscar pacientes'));
    }
  }

  @override
  Future<Either<Failure, PatientEntity>> getPatientById(
    String patientId,
  ) async {
    try {
      final dto = await _localDataSource.getPatientById(patientId);
      if (dto == null) {
        return Left(CacheFailure('Paciente no encontrado'));
      }
      return Right(dto.toEntity());
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener paciente'));
    }
  }
}
