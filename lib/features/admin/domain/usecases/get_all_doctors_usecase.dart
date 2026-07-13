import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../entities/doctor_filters.dart';

class GetAllDoctorsUseCase
    extends UseCase<List<UserEntity>, DoctorFilters> {
  final IAuthRepository repository;

  GetAllDoctorsUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(
    DoctorFilters params,
  ) async {
    return repository.getAllDoctors(
      rol: params.rol != null ? _rolToString(params.rol!) : null,
      empresaNombre: params.empresaNombre,
      fechaDesde: params.fechaDesde,
      fechaHasta: params.fechaHasta,
    );
  }

  String _rolToString(UserRole rol) {
    switch (rol) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.jefe:
        return 'JEFE';
      case UserRole.user:
        return 'USER';
    }
  }
}
