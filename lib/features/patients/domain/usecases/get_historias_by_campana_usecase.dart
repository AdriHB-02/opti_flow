import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/historia_clinica_entity.dart';
import '../../domain/repositories/i_historia_repository.dart';

class GetHistoriasByCampanaParams extends Equatable {
  final String campanaId;

  const GetHistoriasByCampanaParams({required this.campanaId});

  @override
  List<Object?> get props => [campanaId];
}

class GetHistoriasByCampanaUseCase
    implements
        UseCase<List<HistoriaClinicaEntity>, GetHistoriasByCampanaParams> {
  final IHistoriaRepository repository;

  GetHistoriasByCampanaUseCase(this.repository);

  @override
  Future<Either<Failure, List<HistoriaClinicaEntity>>> call(
    GetHistoriasByCampanaParams params,
  ) async {
    return repository.getHistoriasByCampana(params.campanaId);
  }
}
