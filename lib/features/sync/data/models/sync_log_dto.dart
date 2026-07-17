import '../../domain/entities/sync_log_entity.dart';

class SyncLogDTO {
  final String id;
  final String tablaAfectada;
  final String registroId;
  final String operacion;
  final String fechaLocal;
  final int sincronizado;
  final String? fechaSync;
  final String doctorId;
  final int intentos;

  const SyncLogDTO({
    required this.id,
    required this.tablaAfectada,
    required this.registroId,
    required this.operacion,
    required this.fechaLocal,
    required this.sincronizado,
    this.fechaSync,
    required this.doctorId,
    this.intentos = 0,
  });

  factory SyncLogDTO.fromEntity(SyncLogEntity entity) {
    return SyncLogDTO(
      id: entity.id,
      tablaAfectada: entity.tablaAfectada,
      registroId: entity.registroId,
      operacion: entity.operacion.name.toUpperCase(),
      fechaLocal: entity.fechaLocal.toIso8601String(),
      sincronizado: entity.sincronizado ? 1 : 0,
      fechaSync: entity.fechaSync?.toIso8601String(),
      doctorId: entity.doctorId,
      intentos: entity.intentos,
    );
  }

  SyncLogEntity toEntity() {
    return SyncLogEntity(
      id: id,
      tablaAfectada: tablaAfectada,
      registroId: registroId,
      operacion: _parseOperacion(operacion),
      fechaLocal: DateTime.parse(fechaLocal),
      sincronizado: sincronizado == 1,
      fechaSync: fechaSync != null ? DateTime.parse(fechaSync!) : null,
      doctorId: doctorId,
      intentos: intentos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tabla_afectada': tablaAfectada,
      'registro_id': registroId,
      'operacion': operacion,
      'fecha_local': fechaLocal,
      'sincronizado': sincronizado,
      'fecha_sync': fechaSync,
      'doctor_id': doctorId,
      'intentos': intentos,
    };
  }

  factory SyncLogDTO.fromMap(Map<String, dynamic> map) {
    return SyncLogDTO(
      id: _requiredString(map['id']),
      tablaAfectada: _requiredString(map['tabla_afectada']),
      registroId: _requiredString(map['registro_id']),
      operacion: _requiredString(map['operacion']),
      fechaLocal: _requiredString(map['fecha_local']),
      sincronizado: _parseInt(map['sincronizado']),
      fechaSync: _nullableString(map['fecha_sync']),
      doctorId: _requiredString(map['doctor_id']),
      intentos: _parseIntValue(map['intentos']),
    );
  }

  static SyncLogOperacion _parseOperacion(String value) {
    switch (value.toUpperCase()) {
      case 'UPDATE':
        return SyncLogOperacion.update;
      case 'DELETE':
        return SyncLogOperacion.delete;
      case 'INSERT':
      default:
        return SyncLogOperacion.insert;
    }
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      return value.trim() == '1' ? 1 : 0;
    }
    return 0;
  }

  static int _parseIntValue(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _requiredString(Object? value) {
    return value.toString().trim();
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
