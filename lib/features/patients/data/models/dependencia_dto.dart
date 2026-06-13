import '../../domain/entities/dependencia_entity.dart';

class DependenciaDTO {
  final String id;
  final DependenciaTipo tipo;
  final String? campanaId;
  final String? doctorId;
  final String nombre;

  const DependenciaDTO({
    required this.id,
    required this.tipo,
    this.campanaId,
    this.doctorId,
    required this.nombre,
  });

  factory DependenciaDTO.fromEntity(DependenciaEntity entity) {
    return DependenciaDTO(
      id: entity.id,
      tipo: entity.tipo,
      campanaId: entity.campanaId,
      doctorId: entity.doctorId,
      nombre: entity.nombre,
    );
  }

  DependenciaEntity toEntity() {
    return DependenciaEntity(
      id: id,
      tipo: tipo,
      campanaId: campanaId,
      doctorId: doctorId,
      nombre: nombre,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo.name.toUpperCase(),
      'campana_id': campanaId,
      'doctor_id': doctorId,
      'nombre': nombre,
    };
  }

  factory DependenciaDTO.fromMap(Map<String, dynamic> map) {
    return DependenciaDTO(
      id: _requiredString(map['id']),
      tipo: _parseTipo(map['tipo']),
      campanaId: _nullableString(map['campana_id']),
      doctorId: _nullableString(map['doctor_id']),
      nombre: _requiredString(map['nombre']),
    );
  }

  static DependenciaTipo _parseTipo(Object? value) {
    final tipo = value.toString().trim().toUpperCase();

    switch (tipo) {
      case 'EMPRESA':
        return DependenciaTipo.empresa;
      case 'LOCAL':
      default:
        return DependenciaTipo.local;
    }
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
