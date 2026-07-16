import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> loginBiometrico();
  Future<void> logout();
  Future<void> recuperarPassword(String email);

  Future<Either<Failure, List<UserEntity>>> getAllDoctors({
    String? rol,
    String? empresaNombre,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  Future<Either<Failure, void>> deleteDoctorAccount(String doctorId);

  Future<Either<Failure, Map<String, int>>> getGlobalStats();

  Future<Either<Failure, List<Map<String, dynamic>>>> getPacientesPorMes();
}
