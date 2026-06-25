import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/i_campana_repository.dart';

class GetAvailableDoctorsParams extends Equatable {
  final String campanaId;

  const GetAvailableDoctorsParams({required this.campanaId});

  @override
  List<Object?> get props => [campanaId];
}

class GetAvailableDoctorsUseCase
    implements UseCase<List<UserEntity>, GetAvailableDoctorsParams> {
  final ICampanaRepository repository;

  GetAvailableDoctorsUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(
    GetAvailableDoctorsParams params,
  ) async {
    return repository.getAvailableDoctors(params.campanaId);
  }
}
