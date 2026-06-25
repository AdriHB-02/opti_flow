import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/historia_clinica_entity.dart';
import '../repositories/i_historia_repository.dart';

class GetHistoriasParams extends Equatable {
  final String pacienteId;

  const GetHistoriasParams({required this.pacienteId});

  @override
  List<Object?> get props => [pacienteId];
}

class GetHistoriasByPacienteUseCase
    implements
        UseCase<List<HistoriaClinicaEntity>, GetHistoriasParams> {
  final IHistoriaRepository repository;

  GetHistoriasByPacienteUseCase(this.repository);

  @override
  Future<Either<Failure, List<HistoriaClinicaEntity>>> call(
      GetHistoriasParams params) async {
    return repository.getHistoriasByPaciente(params.pacienteId);
  }
}
