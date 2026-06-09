import 'package:equatable/equatable.dart';

class PatientEntity extends Equatable {
  final String id;
  final String nombreCompleto;
  final String dependenciaId;
  final String doctorId;
  final bool esReconsulta;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientEntity({
    required this.id,
    required this.nombreCompleto,
    required this.dependenciaId,
    required this.doctorId,
    required this.esReconsulta,
    required this.createdAt,
    required this.updatedAt,
  });

  PatientEntity copyWith({
    String? id,
    String? nombreCompleto,
    String? dependenciaId,
    String? doctorId,
    bool? esReconsulta,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientEntity(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      dependenciaId: dependenciaId ?? this.dependenciaId,
      doctorId: doctorId ?? this.doctorId,
      esReconsulta: esReconsulta ?? this.esReconsulta,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombreCompleto,
        dependenciaId,
        doctorId,
        esReconsulta,
        createdAt,
        updatedAt,
      ];
}
