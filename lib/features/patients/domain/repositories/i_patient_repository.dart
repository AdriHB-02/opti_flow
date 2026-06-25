import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/patient_entity.dart';

abstract class IPatientRepository {
  Future<Either<Failure, List<PatientEntity>>> getPatients(
    String dependenciaId,
    String doctorId,
  );

  Future<Either<Failure, PatientEntity>> savePatient(PatientEntity patient);

  Future<Either<Failure, List<PatientEntity>>> searchByName(
    String name,
    String dependenciaId,
    String doctorId,
  );

  Future<Either<Failure, PatientEntity>> getPatientById(String patientId);

  Future<Either<Failure, List<PatientEntity>>> getPatientsByCampanaId(
    String campanaId,
  );
}
