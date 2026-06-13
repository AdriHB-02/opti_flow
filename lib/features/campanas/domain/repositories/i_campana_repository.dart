import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/campana_entity.dart';

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
}
