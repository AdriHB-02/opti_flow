import 'package:equatable/equatable.dart';

import '../../domain/entities/historia_clinica_entity.dart';

abstract class HistoriaState extends Equatable {
  const HistoriaState();

  @override
  List<Object?> get props => [];
}

class HistoriaInitial extends HistoriaState {
  const HistoriaInitial();
}

class HistoriaLoading extends HistoriaState {
  const HistoriaLoading();
}

class HistoriasLoaded extends HistoriaState {
  final List<HistoriaClinicaEntity> historias;

  const HistoriasLoaded({required this.historias});

  @override
  List<Object?> get props => [historias];
}

class HistoriaError extends HistoriaState {
  final String message;

  const HistoriaError(this.message);

  @override
  List<Object?> get props => [message];
}
