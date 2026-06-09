import 'package:equatable/equatable.dart';

class HistoriaClinicaEntity extends Equatable {
  final String id;
  final String pacienteId;
  final String? campanaId;
  final String? diagnosticoTexto;
  final String? imagenUrl;
  final double latitud;
  final double longitud;
  final DateTime fechaAtencion;
  final String doctorId;
  final String? historiaAnteriorId;
  final bool sincronizado;
  final DateTime createdAt;

  const HistoriaClinicaEntity({
    required this.id,
    required this.pacienteId,
    this.campanaId,
    this.diagnosticoTexto,
    this.imagenUrl,
    required this.latitud,
    required this.longitud,
    required this.fechaAtencion,
    required this.doctorId,
    this.historiaAnteriorId,
    required this.sincronizado,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        pacienteId,
        campanaId,
        diagnosticoTexto,
        imagenUrl,
        latitud,
        longitud,
        fechaAtencion,
        doctorId,
        historiaAnteriorId,
        sincronizado,
        createdAt,
      ];
}
