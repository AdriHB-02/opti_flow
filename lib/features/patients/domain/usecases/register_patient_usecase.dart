import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/historia_clinica_entity.dart';
import '../entities/patient_entity.dart';
import '../repositories/i_historia_repository.dart';
import '../repositories/i_patient_repository.dart';

class RegisterPatientParams extends Equatable {
  final String patientId;
  final String nombreCompleto;
  final String dependenciaId;
  final String doctorId;
  final bool esReconsulta;
  final String historiaId;
  final String? campanaId;
  final String? diagnosticoTexto;
  final String? imagenUrl;
  final double latitud;
  final double longitud;
  final DateTime fechaAtencion;
  final String? historiaAnteriorId;

  const RegisterPatientParams({
    required this.patientId,
    required this.nombreCompleto,
    required this.dependenciaId,
    required this.doctorId,
    this.esReconsulta = false,
    required this.historiaId,
    this.campanaId,
    this.diagnosticoTexto,
    this.imagenUrl,
    this.latitud = 0.0,
    this.longitud = 0.0,
    required this.fechaAtencion,
    this.historiaAnteriorId,
  });

  PatientEntity toPatientEntity() {
    final now = DateTime.now();
    return PatientEntity(
      id: patientId,
      nombreCompleto: nombreCompleto,
      dependenciaId: dependenciaId,
      doctorId: doctorId,
      esReconsulta: esReconsulta,
      createdAt: now,
      updatedAt: now,
    );
  }

  HistoriaClinicaEntity toHistoriaEntity() {
    return HistoriaClinicaEntity(
      id: historiaId,
      pacienteId: patientId,
      campanaId: campanaId,
      diagnosticoTexto: diagnosticoTexto,
      imagenUrl: imagenUrl,
      latitud: latitud,
      longitud: longitud,
      fechaAtencion: fechaAtencion,
      doctorId: doctorId,
      historiaAnteriorId: historiaAnteriorId,
      sincronizado: false,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        patientId,
        nombreCompleto,
        dependenciaId,
        doctorId,
        esReconsulta,
        historiaId,
        campanaId,
        diagnosticoTexto,
        imagenUrl,
        latitud,
        longitud,
        fechaAtencion,
        historiaAnteriorId,
      ];
}

class RegisterPatientUseCase
    implements UseCase<void, RegisterPatientParams> {
  final IPatientRepository patientRepository;
  final IHistoriaRepository historiaRepository;

  RegisterPatientUseCase({
    required this.patientRepository,
    required this.historiaRepository,
  });

  @override
  Future<Either<Failure, void>> call(RegisterPatientParams params) async {
    final patientEither =
        await patientRepository.savePatient(params.toPatientEntity());
    final patientResult = patientEither.fold(
      (failure) => Left<Failure, void>(failure),
      (_) => null,
    );
    if (patientResult != null) return patientResult;

    final historiaEither =
        await historiaRepository.saveHistoria(params.toHistoriaEntity());
    return historiaEither.fold(
      (failure) => Left<Failure, void>(failure),
      (_) => const Right<Failure, void>(null),
    );
  }
}
