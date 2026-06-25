import 'package:equatable/equatable.dart';

abstract class HistoriaEvent extends Equatable {
  const HistoriaEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistorias extends HistoriaEvent {
  final String pacienteId;
  final String doctorId;

  const LoadHistorias({
    required this.pacienteId,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [pacienteId, doctorId];
}
