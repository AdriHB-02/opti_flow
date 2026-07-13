import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';

class DeleteDoctorAccountParams extends Equatable {
  final String doctorId;

  const DeleteDoctorAccountParams({required this.doctorId});

  @override
  List<Object?> get props => [doctorId];
}

class DeleteDoctorAccountUseCase
    extends UseCase<void, DeleteDoctorAccountParams> {
  final IAuthRepository repository;

  DeleteDoctorAccountUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    DeleteDoctorAccountParams params,
  ) async {
    return repository.deleteDoctorAccount(params.doctorId);
  }
}
