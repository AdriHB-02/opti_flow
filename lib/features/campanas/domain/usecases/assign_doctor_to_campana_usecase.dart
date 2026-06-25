import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/i_campana_repository.dart';

class AssignDoctorParams extends Equatable {
  final String campanaId;
  final String doctorId;

  const AssignDoctorParams({
    required this.campanaId,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [campanaId, doctorId];
}

class AssignDoctorToCampanaUseCase
    implements UseCase<void, AssignDoctorParams> {
  final ICampanaRepository repository;

  AssignDoctorToCampanaUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AssignDoctorParams params) async {
    return repository.assignDoctor(params.campanaId, params.doctorId);
  }
}
