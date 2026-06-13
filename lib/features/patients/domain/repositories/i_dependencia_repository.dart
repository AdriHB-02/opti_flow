import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dependencia_entity.dart';

abstract class IDependenciaRepository {
  Future<Either<Failure, List<DependenciaEntity>>> getDependenciasByDoctor(
    String doctorId,
  );

  Future<Either<Failure, DependenciaEntity>> createDependenciaLocal(
    DependenciaEntity dependencia,
  );
}
