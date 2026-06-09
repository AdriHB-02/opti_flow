import 'package:equatable/equatable.dart';

enum CampanaEstado { activa, finalizada }

class CampanaEntity extends Equatable {
  final String id;
  final String empresaId;
  final String nombreEmpresa;
  final String lugar;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String creadoPor;
  final CampanaEstado estado;
  final DateTime createdAt;

  const CampanaEntity({
    required this.id,
    required this.empresaId,
    required this.nombreEmpresa,
    required this.lugar,
    required this.fechaInicio,
    required this.fechaFin,
    required this.creadoPor,
    required this.estado,
    required this.createdAt,
  });

  bool tieneHistorialPrevio() {
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        empresaId,
        nombreEmpresa,
        lugar,
        fechaInicio,
        fechaFin,
        creadoPor,
        estado,
        createdAt,
      ];
}
