import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/historia_clinica_entity.dart';

abstract class IHistoriaRepository {
  Future<Either<Failure, HistoriaClinicaEntity>> saveHistoria(
    HistoriaClinicaEntity historia,
  );

  Future<Either<Failure, List<HistoriaClinicaEntity>>> getHistoriasByPaciente(
    String pacienteId,
    String doctorId,
  );

  Future<Either<Failure, HistoriaClinicaEntity?>> getHistoriaAnterior(
    String pacienteId,
    String campanaAnteriorId,
  );

  Future<Either<Failure, List<HistoriaClinicaEntity>>> getHistoriasByCampana(
    String campanaId,
  );
}
