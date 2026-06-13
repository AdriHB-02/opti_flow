import '../../domain/entities/campana_entity.dart';

class CampanaDTO {
  final String id;
  final String empresaId;
  final String nombreEmpresa;
  final String lugar;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String creadoPor;
  final CampanaEstado estado;
  final DateTime createdAt;

  const CampanaDTO({
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

  factory CampanaDTO.fromEntity(CampanaEntity entity) {
    return CampanaDTO(
      id: entity.id,
      empresaId: entity.empresaId,
      nombreEmpresa: entity.nombreEmpresa,
      lugar: entity.lugar,
      fechaInicio: entity.fechaInicio,
      fechaFin: entity.fechaFin,
      creadoPor: entity.creadoPor,
      estado: entity.estado,
      createdAt: entity.createdAt,
    );
  }

  CampanaEntity toEntity() {
    return CampanaEntity(
      id: id,
      empresaId: empresaId,
      nombreEmpresa: nombreEmpresa,
      lugar: lugar,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      creadoPor: creadoPor,
      estado: estado,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'nombre_empresa': nombreEmpresa,
      'lugar': lugar,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'creado_por': creadoPor,
      'estado': estado.name.toUpperCase(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CampanaDTO.fromMap(Map<String, dynamic> map) {
    return CampanaDTO(
      id: _requiredString(map['id']),
      empresaId: _requiredString(map['empresa_id']),
      nombreEmpresa: _requiredString(map['nombre_empresa']),
      lugar: _requiredString(map['lugar']),
      fechaInicio: _parseDateTime(map['fecha_inicio']),
      fechaFin: _parseDateTime(map['fecha_fin']),
      creadoPor: _requiredString(map['creado_por']),
      estado: _parseEstado(map['estado']),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.parse(value as String);
  }

  static CampanaEstado _parseEstado(Object? value) {
    final estado = value.toString().trim().toUpperCase();

    switch (estado) {
      case 'FINALIZADA':
        return CampanaEstado.finalizada;
      case 'ACTIVA':
      default:
        return CampanaEstado.activa;
    }
  }

  static String _requiredString(Object? value) {
    return value.toString().trim();
  }
}
