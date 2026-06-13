import '../../domain/entities/patient_entity.dart';

class PatientDTO {
  final String id;
  final String nombreCompleto;
  final String dependenciaId;
  final String doctorId;
  final bool esReconsulta;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientDTO({
    required this.id,
    required this.nombreCompleto,
    required this.dependenciaId,
    required this.doctorId,
    required this.esReconsulta,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientDTO.fromEntity(PatientEntity entity) {
    return PatientDTO(
      id: entity.id,
      nombreCompleto: entity.nombreCompleto,
      dependenciaId: entity.dependenciaId,
      doctorId: entity.doctorId,
      esReconsulta: entity.esReconsulta,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  PatientEntity toEntity() {
    return PatientEntity(
      id: id,
      nombreCompleto: nombreCompleto,
      dependenciaId: dependenciaId,
      doctorId: doctorId,
      esReconsulta: esReconsulta,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'dependencia_id': dependenciaId,
      'doctor_id': doctorId,
      'es_reconsulta': esReconsulta ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PatientDTO.fromMap(Map<String, dynamic> map) {
    return PatientDTO(
      id: _requiredString(map['id']),
      nombreCompleto: _requiredString(map['nombre_completo']),
      dependenciaId: _requiredString(map['dependencia_id']),
      doctorId: _requiredString(map['doctor_id']),
      esReconsulta: _parseBool(map['es_reconsulta']),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.parse(value as String);
  }

  static bool _parseBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }

    return false;
  }

  static String _requiredString(Object? value) {
    return value.toString().trim();
  }
}
