import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/campana_entity.dart';
import '../repositories/i_campana_repository.dart';

class CreateCampanaParams extends Equatable {
  final String id;
  final String empresaId;
  final String nombreEmpresa;
  final String lugar;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String creadoPor;
  final bool ignorarHistorial;

  const CreateCampanaParams({
    required this.id,
    required this.empresaId,
    required this.nombreEmpresa,
    required this.lugar,
    required this.fechaInicio,
    required this.fechaFin,
    required this.creadoPor,
    this.ignorarHistorial = false,
  });

  CampanaEntity toEntity() {
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
        id,
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
        (failure) => false,
        (exists) => exists,
      );

      if (existeHistorial) {
        return const Right(CreateCampanaResult(existeHistorialPrevio: true));
      }
    }

    final campanaEntity = params.toEntity();
    return repository.createCampana(campanaEntity).then(
      (result) => result.fold(
        (failure) => Left(failure),
        (campana) => Right(CreateCampanaResult(campanaCreada: campana)),
      ),
    );
  }
}
