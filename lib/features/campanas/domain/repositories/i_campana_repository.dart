import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../entities/campana_entity.dart';
import '../entities/doctor_progress.dart';

abstract class ICampanaRepository {
  Future<Either<Failure, CampanaEntity>> createCampana(CampanaEntity campana);

  Future<Either<Failure, List<CampanaEntity>>> getCampanasByDoctor(
    String doctorId,
  );

  Future<Either<Failure, bool>> checkHistorialPrevio(
    String nombreEmpresa,
    String lugar,
  );

  Future<Either<Failure, void>> assignDoctor(String campanaId, String doctorId);

  Future<Either<Failure, List<DoctorProgress>>> getCampanaProgress(
    String campanaId,
  );

  Future<Either<Failure, List<UserEntity>>> getAvailableDoctors(
    String campanaId,
  );

  Future<Either<Failure, void>> createEmpresa(Map<String, dynamic> empresaMap);
}
