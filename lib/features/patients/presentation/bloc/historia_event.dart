import 'package:equatable/equatable.dart';

abstract class HistoriaEvent extends Equatable {
  const HistoriaEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistorias extends HistoriaEvent {
  final String pacienteId;

  const LoadHistorias({required this.pacienteId});

  @override
  List<Object?> get props => [pacienteId];
}
