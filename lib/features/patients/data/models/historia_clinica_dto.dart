import '../../domain/entities/historia_clinica_entity.dart';

class HistoriaClinicaDTO {
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

  const HistoriaClinicaDTO({
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

  factory HistoriaClinicaDTO.fromEntity(HistoriaClinicaEntity entity) {
    return HistoriaClinicaDTO(
      id: entity.id,
      pacienteId: entity.pacienteId,
      campanaId: entity.campanaId,
      diagnosticoTexto: entity.diagnosticoTexto,
      imagenUrl: entity.imagenUrl,
      latitud: entity.latitud,
      longitud: entity.longitud,
      fechaAtencion: entity.fechaAtencion,
      doctorId: entity.doctorId,
      historiaAnteriorId: entity.historiaAnteriorId,
      sincronizado: entity.sincronizado,
      createdAt: entity.createdAt,
    );
  }

  HistoriaClinicaEntity toEntity() {
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
      sincronizado: sincronizado,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'campana_id': campanaId,
      'diagnostico_texto': diagnosticoTexto,
      'imagen_url': imagenUrl,
      'latitud': latitud,
      'longitud': longitud,
      'fecha_atencion': fechaAtencion.toIso8601String(),
      'doctor_id': doctorId,
      'historia_anterior_id': historiaAnteriorId,
      'sincronizado': sincronizado ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HistoriaClinicaDTO.fromMap(Map<String, dynamic> map) {
    return HistoriaClinicaDTO(
      id: _requiredString(map['id']),
      pacienteId: _requiredString(map['paciente_id']),
      campanaId: _nullableString(map['campana_id']),
      diagnosticoTexto: _nullableString(map['diagnostico_texto']),
      imagenUrl: _nullableString(map['imagen_url']),
      latitud: _parseDouble(map['latitud']),
      longitud: _parseDouble(map['longitud']),
      fechaAtencion: _parseDateTime(map['fecha_atencion']),
      doctorId: _requiredString(map['doctor_id']),
      historiaAnteriorId: _nullableString(map['historia_anterior_id']),
      sincronizado: _parseBool(map['sincronizado']),
      createdAt: _parseDateTime(map['created_at']),
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

  static double _parseDouble(Object? value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.parse(value as String);
  }

  static String _requiredString(Object? value) {
    return value.toString().trim();
  }

  static String? _nullableString(Object? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
