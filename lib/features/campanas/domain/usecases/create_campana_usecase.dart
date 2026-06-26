import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/campana_entity.dart';
import '../repositories/i_campana_repository.dart';

class CreateCampanaParams extends Equatable {
  final String? empresaId;
  final String nombreEmpresa;
  final String lugar;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String creadoPor;
  final bool ignorarHistorial;

  const CreateCampanaParams({
    this.empresaId,
    required this.nombreEmpresa,
    required this.lugar,
    required this.fechaInicio,
    required this.fechaFin,
    required this.creadoPor,
    this.ignorarHistorial = false,
  });

  CampanaEntity toEntity(String id, String empresaId) {
    return CampanaEntity(
      id: id,
      empresaId: empresaId,
      nombreEmpresa: nombreEmpresa,
      lugar: lugar,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      creadoPor: creadoPor,
      estado: CampanaEstado.activa,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        empresaId,
        nombreEmpresa,
        lugar,
        fechaInicio,
        fechaFin,
        creadoPor,
        ignorarHistorial,
      ];
}

class CreateCampanaResult extends Equatable {
  final CampanaEntity? campanaCreada;
  final List<CampanaEntity> campanasAnteriores;
  final bool existeHistorialPrevio;

  const CreateCampanaResult({
    this.campanaCreada,
    this.campanasAnteriores = const [],
    this.existeHistorialPrevio = false,
  });

  @override
  List<Object?> get props => [campanaCreada, campanasAnteriores, existeHistorialPrevio];
}

class CreateCampanaUseCase
    implements UseCase<CreateCampanaResult, CreateCampanaParams> {
  final ICampanaRepository repository;

  CreateCampanaUseCase(this.repository);

  @override
  Future<Either<Failure, CreateCampanaResult>> call(
    CreateCampanaParams params,
  ) async {
    if (!params.ignorarHistorial) {
      final checkResult = await repository.checkHistorialPrevio(
        params.nombreEmpresa,
        params.lugar,
      );

      final existeHistorial = checkResult.fold(
        (failure) => null,
        (exists) => exists,
      );

      if (existeHistorial == null) {
        return checkResult.fold(
          (failure) => Left(failure),
          (_) => const Right(CreateCampanaResult()),
        );
      }

      if (existeHistorial) {
        return const Right(CreateCampanaResult(existeHistorialPrevio: true));
      }
    }

    final id = const Uuid().v4();
    final empresaId = params.empresaId ?? id;

    if (params.empresaId == null) {
      final empresaResult = await repository.createEmpresa({
        'id': empresaId,
        'nombre': params.nombreEmpresa,
        'lugar': params.lugar,
        'activa': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      final empresaFailure = empresaResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (empresaFailure != null) return Left(empresaFailure);
    }

    final campanaEntity = params.toEntity(id, empresaId);
    return repository.createCampana(campanaEntity).then(
      (result) => result.fold(
        (failure) => Left(failure),
        (campana) => Right(CreateCampanaResult(campanaCreada: campana)),
      ),
    );
  }
}
