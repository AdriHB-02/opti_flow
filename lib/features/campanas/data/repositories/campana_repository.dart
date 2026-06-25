import 'package:dartz/dartz.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../../domain/entities/campana_entity.dart';
import '../../domain/entities/doctor_progress.dart';
import '../../domain/repositories/i_campana_repository.dart';
import '../datasources/local_campana_data_source.dart';
import '../models/campana_dto.dart';

class CampanaRepository implements ICampanaRepository {
  final LocalCampanaDataSource _localDataSource;

  CampanaRepository({required LocalCampanaDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, CampanaEntity>> createCampana(
    CampanaEntity campana,
  ) async {
    try {
      final dto = CampanaDTO.fromEntity(campana);
      await _localDataSource.insertCampana(dto);
      return Right(campana);
    } on DataSourceException {
      return Left(CacheFailure('Error al crear campaña'));
    }
  }

  @override
  Future<Either<Failure, List<CampanaEntity>>> getCampanasByDoctor(
    String doctorId,
  ) async {
    try {
      final dtos = await _localDataSource.getCampanasByDoctor(doctorId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener campañas'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkHistorialPrevio(
    String nombreEmpresa,
    String lugar,
  ) async {
    try {
      final exists = await _localDataSource.checkDuplicate(
        nombreEmpresa,
        lugar,
      );
      return Right(exists);
    } on DataSourceException {
      return Left(CacheFailure('Error al verificar historial previo'));
    }
  }

  @override
  Future<Either<Failure, void>> assignDoctor(
    String campanaId,
    String doctorId,
  ) async {
    try {
      await _localDataSource.assignDoctor(campanaId, doctorId);
      return const Right(null);
    } on DataSourceException {
      return Left(CacheFailure('Error al asignar doctor a campaña'));
    }
  }

  @override
  Future<Either<Failure, List<DoctorProgress>>> getCampanaProgress(
    String campanaId,
  ) async {
    try {
      final dtos = await _localDataSource.getCampanaProgress(campanaId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener progreso de campaña'));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAvailableDoctors(
    String campanaId,
  ) async {
    try {
      final dtos = await _localDataSource.getAvailableDoctors(campanaId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener doctores disponibles'));
    }
  }
}
