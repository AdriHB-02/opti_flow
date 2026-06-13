import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/campana_entity.dart';
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
    } catch (e) {
      return Left(CacheFailure(e.toString()));
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
    } catch (e) {
      return Left(CacheFailure(e.toString()));
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
    } catch (e) {
      return Left(CacheFailure(e.toString()));
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
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
