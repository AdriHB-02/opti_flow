import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../../domain/entities/campana_entity.dart';
import '../../domain/entities/doctor_progress.dart';
import '../../domain/repositories/i_campana_repository.dart';
import '../datasources/local_campana_data_source.dart';
import '../datasources/remote_campana_data_source.dart';
import '../models/campana_dto.dart';

class CampanaRepository implements ICampanaRepository {
  final LocalCampanaDataSource _localDataSource;
  final RemoteCampanaDataSource? _remoteDataSource;

  CampanaRepository({
    required LocalCampanaDataSource localDataSource,
    RemoteCampanaDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, CampanaEntity>> createCampana(
    CampanaEntity campana,
  ) async {
    try {
      final dto = CampanaDTO.fromEntity(campana);
      await _localDataSource.insertCampana(dto);

      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource.upsert(dto);
        } catch (e) {
          debugPrint('[CampanaRepository] Remote upsert failed, saved locally: $e');
        }
      }

      return Right(campana);
    } on DataSourceException catch (e) {
      debugPrint('[Repo] createCampana error: $e — original: ${e.originalError}');
      return Left(CacheFailure('Error al crear campaña: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CampanaEntity>>> getCampanasByDoctor(
    String doctorId,
  ) async {
    try {
      final localDtos = await _localDataSource.getCampanasByDoctor(doctorId);

      if (_remoteDataSource != null) {
        try {
          final remoteDtos = await _remoteDataSource.getByDoctorId(doctorId);
          for (final dto in remoteDtos) {
            try {
              await _localDataSource.insertCampanaSilent(dto);
            } catch (cacheError) {
              debugPrint('[CampanaRepository] Error cacheando campaña local ${dto.id}: $cacheError');
            }
          }
          final merged = _mergeCampanaLists(localDtos, remoteDtos);
          final entities = merged.map((dto) => dto.toEntity()).toList();
          return Right(entities);
        } catch (e) {
          debugPrint('[CampanaRepository] Remote fetch failed, using local: $e');
        }
      }

      final entities = localDtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException catch (e) {
      debugPrint('[Repo] getCampanasByDoctor error: $e — original: ${e.originalError}');
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
    } on DataSourceException catch (e) {
      debugPrint('[Repo] checkHistorialPrevio error: $e — original: ${e.originalError}');
      return Left(CacheFailure('Error al verificar historial previo'));
    }
  }

  @override
  Future<Either<Failure, void>> assignDoctor(
    String campanaId,
    String doctorId,
  ) async {
    bool localOk = true;
    try {
      await _localDataSource.assignDoctor(campanaId, doctorId);
    } on DataSourceException catch (e) {
      debugPrint('[CampanaRepository] Local assignDoctor failed, trying remote: $e');
      localOk = false;
    }

    bool remoteOk = false;
    if (_remoteDataSource != null) {
      try {
        await _remoteDataSource.assignDoctor(campanaId, doctorId);
        remoteOk = true;
      } catch (e) {
        debugPrint('[CampanaRepository] Remote assignDoctor failed: $e');
      }
    }

    if (localOk || remoteOk) {
      return const Right(null);
    }
    return Left(CacheFailure('Error al asignar doctor a campaña'));
  }

  @override
  Future<Either<Failure, List<DoctorProgress>>> getCampanaProgress(
    String campanaId,
  ) async {
    try {
      if (_remoteDataSource != null) {
        try {
          final remoteProgressMaps = await _remoteDataSource.getCampanaProgressByCampanaId(
            campanaId,
          );
          final entities = remoteProgressMaps
            .map((map) => DoctorProgress(
              doctorId: map['doctor_id'] as String,
              doctorNombre: map['doctor_nombre'] as String,
              totalPacientes: (map['total_pacientes'] as num).toInt(),
            ))
            .toList();
          return Right(entities);
        } catch (e) {
          debugPrint('[CampanaRepository] Remote fetch failed, using local: \$e');
        }
      }

      final dtos = await _localDataSource.getCampanaProgress(campanaId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException catch (e) {
      debugPrint('[Repo] getCampanaProgress error: $e — original: ${e.originalError}');
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
    } on DataSourceException catch (e) {
      debugPrint('[Repo] getAvailableDoctors error: $e — original: ${e.originalError}');
      return Left(CacheFailure('Error al obtener doctores disponibles'));
    }
  }

  @override
  Future<Either<Failure, void>> createEmpresa(Map<String, dynamic> empresaMap) async {
    try {
      await _localDataSource.insertEmpresa(empresaMap);

      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource.upsertEmpresa(empresaMap);
        } catch (e) {
          debugPrint('[CampanaRepository] Remote empresa upsert failed, saved locally: $e');
        }
      }

      return const Right(null);
    } on DataSourceException catch (e) {
      debugPrint('[Repo] createEmpresa error: $e — original: ${e.originalError}');
      return Left(CacheFailure('Error al crear empresa'));
    }
  }

  List<CampanaDTO> _mergeCampanaLists(
    List<CampanaDTO> local,
    List<CampanaDTO> remote,
  ) {
    final mergedMap = <String, CampanaDTO>{};

    for (final remoteDto in remote) {
      mergedMap[remoteDto.id] = remoteDto;
    }

    for (final localDto in local) {
      final existing = mergedMap[localDto.id];
      if (existing == null) {
        mergedMap[localDto.id] = localDto;
      } else {
        if (localDto.fechaFin.isAfter(existing.fechaFin)) {
          mergedMap[localDto.id] = localDto;
        }
      }
    }

    final merged = mergedMap.values.toList();
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }
}
