import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/repositories/i_patient_repository.dart';
import '../datasources/local_patient_data_source.dart';
import '../datasources/remote_patient_data_source.dart';
import '../models/patient_dto.dart';

class PatientRepository implements IPatientRepository {
  final LocalPatientDataSource _localDataSource;
  final RemotePatientDataSource? _remoteDataSource;

  PatientRepository({
    required LocalPatientDataSource localDataSource,
    RemotePatientDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<PatientEntity>>> getPatients(
    String dependenciaId,
    String doctorId,
  ) async {
    try {
      final localDtos =
          await _localDataSource.getPatients(dependenciaId, doctorId);

      if (_remoteDataSource != null) {
        try {
          final remoteDtos =
              await _remoteDataSource.getByDependenciaId(dependenciaId);
          final merged = _mergePatientLists(localDtos, remoteDtos);
          final entities = merged.map((dto) => dto.toEntity()).toList();
          return Right(entities);
        } catch (e) {
          debugPrint('[PatientRepository] Remote fetch failed, using local: $e');
        }
      }

      final entities = localDtos.map((dto) => dto.toEntity()).toList();
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

      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource.upsert(dto);
        } catch (e) {
          debugPrint('[PatientRepository] Remote upsert failed, saved locally: $e');
        }
      }

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
        if (_remoteDataSource != null) {
          try {
            final remoteDto = await _remoteDataSource.getById(patientId);
            if (remoteDto != null) {
              return Right(remoteDto.toEntity());
            }
          } catch (e) {
            debugPrint('[PatientRepository] Remote getById failed: $e');
          }
        }
        return Left(CacheFailure('Paciente no encontrado'));
      }
      return Right(dto.toEntity());
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener paciente'));
    }
  }

  @override
  Future<Either<Failure, List<PatientEntity>>> getPatientsByCampanaId(
    String campanaId,
  ) async {
    try {
      final dtos = await _localDataSource.getPatientsByCampanaId(campanaId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener pacientes por campaña'));
    }
  }

  List<PatientDTO> _mergePatientLists(
    List<PatientDTO> local,
    List<PatientDTO> remote,
  ) {
    final mergedMap = <String, PatientDTO>{};

    for (final remoteDto in remote) {
      mergedMap[remoteDto.id] = remoteDto;
    }

    for (final localDto in local) {
      final existing = mergedMap[localDto.id];
      if (existing == null) {
        mergedMap[localDto.id] = localDto;
      } else {
        if (localDto.updatedAt.isAfter(existing.updatedAt)) {
          mergedMap[localDto.id] = localDto;
        }
      }
    }

    final merged = mergedMap.values.toList();
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }
}
