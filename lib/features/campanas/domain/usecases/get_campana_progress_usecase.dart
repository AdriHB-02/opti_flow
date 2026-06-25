import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/doctor_progress.dart';
import '../repositories/i_campana_repository.dart';

class GetCampanaProgressParams extends Equatable {
  final String campanaId;

  const GetCampanaProgressParams({required this.campanaId});

  @override
  List<Object?> get props => [campanaId];
}

class GetCampanaProgressUseCase
    implements UseCase<List<DoctorProgress>, GetCampanaProgressParams> {
  final ICampanaRepository repository;

  GetCampanaProgressUseCase(this.repository);

  @override
  Future<Either<Failure, List<DoctorProgress>>> call(
    GetCampanaProgressParams params,
  ) async {
    return repository.getCampanaProgress(params.campanaId);
  }
}
