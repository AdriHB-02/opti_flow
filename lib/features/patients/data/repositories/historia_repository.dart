import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/historia_clinica_entity.dart';
import '../../domain/repositories/i_historia_repository.dart';
import '../datasources/local_historia_data_source.dart';
import '../datasources/remote_historia_data_source.dart';
import '../models/historia_clinica_dto.dart';

class HistoriaRepository implements IHistoriaRepository {
  final LocalHistoriaDataSource _localDataSource;
  final RemoteHistoriaDataSource? _remoteDataSource;

  HistoriaRepository({
    required LocalHistoriaDataSource localDataSource,
    RemoteHistoriaDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, HistoriaClinicaEntity>> saveHistoria(
    HistoriaClinicaEntity historia,
  ) async {
    try {
      final dto = HistoriaClinicaDTO.fromEntity(historia);
      await _localDataSource.insertHistoria(dto);

      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource.upsert(dto);
        } catch (e) {
          debugPrint('[HistoriaRepository] Remote upsert failed, saved locally: $e');
        }
      }

      return Right(historia);
    } on DataSourceException {
      return Left(CacheFailure('Error al guardar historia clínica'));
    }
  }

  @override
  Future<Either<Failure, List<HistoriaClinicaEntity>>>
      getHistoriasByPaciente(String pacienteId, String doctorId) async {
    try {
      final dtos = await _localDataSource.getByPaciente(pacienteId, doctorId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener historias clínicas'));
    }
  }

  @override
  Future<Either<Failure, HistoriaClinicaEntity?>> getHistoriaAnterior(
    String pacienteId,
    String campanaAnteriorId,
  ) async {
    try {
      final dto = await _localDataSource.getAnterior(
        pacienteId,
        campanaAnteriorId,
      );
      return Right(dto?.toEntity());
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener historia anterior'));
    }
  }

  @override
  Future<Either<Failure, List<HistoriaClinicaEntity>>> getHistoriasByCampana(
    String campanaId,
  ) async {
    try {
      if (_remoteDataSource != null) {
        try {
          final remoteDtos = await _remoteDataSource.getByCampanaId(campanaId);
          final entities = remoteDtos.map((dto) => dto.toEntity()).toList();
          return Right(entities);
        } catch (e) {
          debugPrint('[HistoriaRepository] Remote fetch failed, using local: $e');
        }
      }

      final dtos = await _localDataSource.getByCampana(campanaId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } on DataSourceException {
      return Left(CacheFailure('Error al obtener historias de la campaña'));
    }
  }
}
