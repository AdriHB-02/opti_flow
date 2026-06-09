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

  const SyncLogEntity({
    required this.id,
    required this.tablaAfectada,
    required this.registroId,
    required this.operacion,
    required this.fechaLocal,
    required this.sincronizado,
    this.fechaSync,
    required this.doctorId,
  });

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
      ];
}
