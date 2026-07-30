import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dependencia_entity.dart';
import '../../domain/repositories/i_dependencia_repository.dart';
import '../datasources/local_dependencia_data_source.dart';
import '../datasources/remote_dependencia_data_source.dart';
import '../models/dependencia_dto.dart';

class DependenciaRepository implements IDependenciaRepository {
  final LocalDependenciaDataSource _localDataSource;
  final RemoteDependenciaDataSource? _remoteDataSource;

  DependenciaRepository({
    required LocalDependenciaDataSource localDataSource,
    RemoteDependenciaDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<DependenciaEntity>>> getDependenciasByDoctor(
    String doctorId,
  ) async {
    try {
      final dtos = await _localDataSource.getDependenciasByDoctor(doctorId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener dependencias'));
    }
  }

  @override
  Future<Either<Failure, DependenciaEntity>> createDependenciaLocal(
    DependenciaEntity dependencia,
  ) async {
    try {
      final dto = DependenciaDTO.fromEntity(dependencia);
      await _localDataSource.insertDependencia(dto);

      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource.upsert(dto);
        } catch (e) {
          debugPrint(
            '[DependenciaRepository] Remote upsert failed, saved locally: $e',
          );
        }
      }

      return Right(dependencia);
    } on DataSourceException {
      return Left(CacheFailure('Error al crear dependencia local'));
    }
  }
}
