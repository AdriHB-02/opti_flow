import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../patients/domain/entities/patient_entity.dart';
import '../../../patients/domain/repositories/i_patient_repository.dart';
import '../repositories/i_campana_repository.dart';

class ImportReconsultaParams extends Equatable {
  final String campanaAnteriorId;
  final String nuevaCampanaId;
  final String nuevaDependenciaId;
  final String doctorId;

  const ImportReconsultaParams({
    required this.campanaAnteriorId,
    required this.nuevaCampanaId,
    required this.nuevaDependenciaId,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [
        campanaAnteriorId,
        nuevaCampanaId,
        nuevaDependenciaId,
        doctorId,
      ];
}

class ImportPacientesReconsultaUseCase
    implements UseCase<void, ImportReconsultaParams> {
  final IPatientRepository patientRepository;
  final ICampanaRepository campanaRepository;

  ImportPacientesReconsultaUseCase({
    required this.patientRepository,
    required this.campanaRepository,
  });

  @override
  Future<Either<Failure, void>> call(ImportReconsultaParams params) async {
    final patientsResult = await patientRepository.getPatientsByCampanaId(
      params.campanaAnteriorId,
    );

    return patientsResult.fold(
      (failure) => Left(failure),
      (oldPatients) async {
        final now = DateTime.now();
        const uuid = Uuid();

        for (final oldPatient in oldPatients) {
          final newPatient = PatientEntity(
            id: uuid.v4(),
            nombreCompleto: oldPatient.nombreCompleto,
            dependenciaId: params.nuevaDependenciaId,
            doctorId: params.doctorId,
            esReconsulta: true,
            createdAt: now,
            updatedAt: now,
          );

          final saveResult = await patientRepository.savePatient(newPatient);
          if (saveResult.isLeft()) {
            return Left(CacheFailure('Error al importar pacientes como reconsulta'));
          }
        }

        return const Right(null);
      },
    );
  }
}
