import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';

class DeleteDoctorAccountParams extends Equatable {
  final String doctorId;
  final String currentUserId;

  const DeleteDoctorAccountParams({
    required this.doctorId,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [doctorId, currentUserId];
}

class DeleteDoctorAccountUseCase
    extends UseCase<void, DeleteDoctorAccountParams> {
  final IAuthRepository repository;

  DeleteDoctorAccountUseCase(this.repository);

  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  Future<Either<Failure, void>> call(
    DeleteDoctorAccountParams params,
  ) async {
    if (params.doctorId.isEmpty) {
      return const Left(AuthFailure('El identificador del doctor no puede estar vacío'));
    }

    if (!_uuidRegex.hasMatch(params.doctorId)) {
      return const Left(AuthFailure('El identificador del doctor no tiene un formato válido'));
    }

    if (params.doctorId == params.currentUserId) {
      return const Left(AuthFailure('No puedes eliminar tu propia cuenta desde el panel de administración'));
    }

    return repository.deleteDoctorAccount(params.doctorId);
  }
}
