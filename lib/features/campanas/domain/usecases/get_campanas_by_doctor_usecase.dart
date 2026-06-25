import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/campana_entity.dart';
import '../repositories/i_campana_repository.dart';

class GetCampanasByDoctorParams extends Equatable {
  final String doctorId;

  const GetCampanasByDoctorParams({required this.doctorId});

  @override
  List<Object?> get props => [doctorId];
}

class GetCampanasByDoctorUseCase
    implements UseCase<List<CampanaEntity>, GetCampanasByDoctorParams> {
  final ICampanaRepository repository;

  GetCampanasByDoctorUseCase(this.repository);

  @override
  Future<Either<Failure, List<CampanaEntity>>> call(
    GetCampanasByDoctorParams params,
  ) async {
    return repository.getCampanasByDoctor(params.doctorId);
  }
}
