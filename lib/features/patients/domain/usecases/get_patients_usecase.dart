import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/patient_entity.dart';
import '../repositories/i_patient_repository.dart';

class GetPatientsParams extends Equatable {
  final String dependenciaId;
  final String doctorId;

  const GetPatientsParams({
    required this.dependenciaId,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [dependenciaId, doctorId];
}

class GetPatientsUseCase
    implements UseCase<List<PatientEntity>, GetPatientsParams> {
  final IPatientRepository repository;

  GetPatientsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PatientEntity>>> call(
      GetPatientsParams params) async {
    return repository.getPatients(params.dependenciaId, params.doctorId);
  }
}
