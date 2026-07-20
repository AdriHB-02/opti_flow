import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/historia_clinica_entity.dart';
import '../entities/patient_entity.dart';
import '../repositories/i_historia_repository.dart';
import '../repositories/i_patient_repository.dart';
import '../services/i_gps_service.dart';

class RegisterPatientParams extends Equatable {
  final String nombreCompleto;
  final String dependenciaId;
  final String doctorId;
  final bool esReconsulta;
  final String? campanaId;
  final String? diagnosticoTexto;
  final String? imagenUrl;
  final double latitud;
  final double longitud;
  final DateTime fechaAtencion;
  final String? historiaAnteriorId;

  const RegisterPatientParams({
    required this.nombreCompleto,
    required this.dependenciaId,
    required this.doctorId,
    this.esReconsulta = false,
    this.campanaId,
    this.diagnosticoTexto,
    this.imagenUrl,
    this.latitud = 0.0,
    this.longitud = 0.0,
    required this.fechaAtencion,
    this.historiaAnteriorId,
  });

  RegisterPatientParams copyWith({
    String? nombreCompleto,
    String? dependenciaId,
    String? doctorId,
    bool? esReconsulta,
    String? campanaId,
    String? diagnosticoTexto,
    String? imagenUrl,
    double? latitud,
    double? longitud,
    DateTime? fechaAtencion,
    String? historiaAnteriorId,
  }) {
    return RegisterPatientParams(
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      dependenciaId: dependenciaId ?? this.dependenciaId,
      doctorId: doctorId ?? this.doctorId,
      esReconsulta: esReconsulta ?? this.esReconsulta,
      campanaId: campanaId ?? this.campanaId,
      diagnosticoTexto: diagnosticoTexto ?? this.diagnosticoTexto,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fechaAtencion: fechaAtencion ?? this.fechaAtencion,
      historiaAnteriorId: historiaAnteriorId ?? this.historiaAnteriorId,
    );
  }

  PatientEntity toPatientEntity(String id) {
    final now = DateTime.now();
    return PatientEntity(
      id: id,
      nombreCompleto: nombreCompleto,
      dependenciaId: dependenciaId,
      doctorId: doctorId,
      esReconsulta: esReconsulta,
      createdAt: now,
      updatedAt: now,
    );
  }

  HistoriaClinicaEntity toHistoriaEntity(String id, String pacienteId) {
    return HistoriaClinicaEntity(
      id: id,
      pacienteId: pacienteId,
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
        nombreCompleto,
        dependenciaId,
        doctorId,
        esReconsulta,
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
  final IGpsService gpsService;

  RegisterPatientUseCase({
    required this.patientRepository,
    required this.historiaRepository,
    required this.gpsService,
  });

  @override
  Future<Either<Failure, void>> call(RegisterPatientParams params) async {
    double lat = params.latitud;
    double lng = params.longitud;

    if (lat == 0.0 && lng == 0.0) {
      try {
        final hasPermission = await gpsService.checkAndRequestPermission();
        if (hasPermission) {
          final location = await gpsService.getCurrentLocation();
          lat = location.lat;
          lng = location.lng;
        }
      } catch (_) {
        return const Left(LocationFailure(
          'No se pudo obtener la ubicación GPS',
        ));
      }
    }

    final patientId = const Uuid().v4();
    final historiaId = const Uuid().v4();

    final patientEither =
        await patientRepository.savePatient(params.toPatientEntity(patientId));
    final patientResult = patientEither.fold(
      (failure) => Left<Failure, void>(failure),
      (_) => null,
    );
    if (patientResult != null) return patientResult;

    final updatedParams = params.copyWith(latitud: lat, longitud: lng);
    final historiaEither = await historiaRepository
        .saveHistoria(updatedParams.toHistoriaEntity(historiaId, patientId));
    return historiaEither.fold(
      (failure) => Left<Failure, void>(failure),
      (_) => const Right<Failure, void>(null),
    );
  }
}
