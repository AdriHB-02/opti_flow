import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dependencia_entity.dart';
import '../repositories/i_dependencia_repository.dart';

class GetDependenciasParams extends Equatable {
  final String doctorId;

  const GetDependenciasParams({required this.doctorId});

  @override
  List<Object?> get props => [doctorId];
}

class GetDependenciasUseCase
    implements UseCase<List<DependenciaEntity>, GetDependenciasParams> {
  final IDependenciaRepository repository;

  GetDependenciasUseCase(this.repository);

  @override
  Future<Either<Failure, List<DependenciaEntity>>> call(
      GetDependenciasParams params) async {
    return repository.getDependenciasByDoctor(params.doctorId);
  }
}
