import 'package:equatable/equatable.dart';

enum SyncLogOperacion { insert, update, delete }

class SyncLogEntity extends Equatable {
  final String id;
  final String tablaAfectada;
  final String registroId;
  final SyncLogOperacion operacion;
  final DateTime fechaLocal;
  final bool sincronizado;
  final DateTime? fechaSync;
  final String doctorId;
  final int intentos;

  const SyncLogEntity({
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

  SyncLogEntity copyWith({
    String? id,
    String? tablaAfectada,
    String? registroId,
    SyncLogOperacion? operacion,
    DateTime? fechaLocal,
    bool? sincronizado,
    DateTime? fechaSync,
    String? doctorId,
    int? intentos,
  }) {
    return SyncLogEntity(
      id: id ?? this.id,
      tablaAfectada: tablaAfectada ?? this.tablaAfectada,
      registroId: registroId ?? this.registroId,
      operacion: operacion ?? this.operacion,
      fechaLocal: fechaLocal ?? this.fechaLocal,
      sincronizado: sincronizado ?? this.sincronizado,
      fechaSync: fechaSync ?? this.fechaSync,
      doctorId: doctorId ?? this.doctorId,
      intentos: intentos ?? this.intentos,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tablaAfectada,
        registroId,
        operacion,
        fechaLocal,
        sincronizado,
        fechaSync,
        doctorId,
        intentos,
      ];
}
