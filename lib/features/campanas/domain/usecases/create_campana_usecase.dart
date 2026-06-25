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

  const CreateCampanaParams({
    required this.id,
    required this.empresaId,
    required this.nombreEmpresa,
    required this.lugar,
    required this.fechaInicio,
    required this.fechaFin,
    required this.creadoPor,
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
      ];
}

class CreateCampanaResult extends Equatable {
  final CampanaEntity? campanaCreada;
  final List<CampanaEntity> campanasAnteriores;

  bool get existeHistorialPrevio => campanasAnteriores.isNotEmpty;

  const CreateCampanaResult({
    this.campanaCreada,
    this.campanasAnteriores = const [],
  });

  @override
  List<Object?> get props => [campanaCreada, campanasAnteriores];
}

class CreateCampanaUseCase
    implements UseCase<CreateCampanaResult, CreateCampanaParams> {
  final ICampanaRepository repository;

  CreateCampanaUseCase(this.repository);

  @override
  Future<Either<Failure, CreateCampanaResult>> call(
    CreateCampanaParams params,
  ) async {
    final checkResult = await repository.checkHistorialPrevio(
      params.nombreEmpresa,
      params.lugar,
    );

    final existeHistorial = checkResult.fold(
      (failure) => false,
      (exists) => exists,
    );

    if (existeHistorial) {
      return Left(CacheFailure(
        'Ya existe un historial para ${params.nombreEmpresa} en ${params.lugar}',
      ));
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
