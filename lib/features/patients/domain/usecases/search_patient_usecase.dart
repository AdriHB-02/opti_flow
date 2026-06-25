import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/patient_entity.dart';
import '../repositories/i_patient_repository.dart';

class SearchPatientParams extends Equatable {
  final String query;
  final String dependenciaId;
  final String doctorId;

  const SearchPatientParams({
    required this.query,
    required this.dependenciaId,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [query, dependenciaId, doctorId];
}

class SearchPatientUseCase
    implements UseCase<List<PatientEntity>, SearchPatientParams> {
  final IPatientRepository repository;

  SearchPatientUseCase(this.repository);

  @override
  Future<Either<Failure, List<PatientEntity>>> call(
      SearchPatientParams params) async {
    return repository.searchByName(
      params.query,
      params.dependenciaId,
      params.doctorId,
    );
  }
}
