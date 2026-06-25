import 'package:dartz/dartz.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dependencia_entity.dart';
import '../../domain/repositories/i_dependencia_repository.dart';
import '../datasources/local_dependencia_data_source.dart';
import '../models/dependencia_dto.dart';

class DependenciaRepository implements IDependenciaRepository {
  final LocalDependenciaDataSource _localDataSource;

  DependenciaRepository({required LocalDependenciaDataSource localDataSource})
      : _localDataSource = localDataSource;

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
      return Right(dependencia);
    } on DataSourceException {
      return Left(CacheFailure('Error al crear dependencia local'));
    }
  }
}
