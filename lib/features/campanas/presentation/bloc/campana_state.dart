import 'package:equatable/equatable.dart';

import '../../domain/entities/campana_entity.dart';
import '../../domain/entities/doctor_progress.dart';

abstract class CampanaState extends Equatable {
  const CampanaState();

  @override
  List<Object?> get props => [];
}

class CampanaInitial extends CampanaState {
  const CampanaInitial();
}

class CampanaLoading extends CampanaState {
  const CampanaLoading();
}

class CampanaCreated extends CampanaState {
  final CampanaEntity campana;

  const CampanaCreated(this.campana);

  @override
  List<Object?> get props => [campana];
}

class HistorialPrevioDetectado extends CampanaState {
  final List<CampanaEntity> campanasAnteriores;

  const HistorialPrevioDetectado({required this.campanasAnteriores});

  @override
  List<Object?> get props => [campanasAnteriores];
}

class DoctorAssigned extends CampanaState {
  const DoctorAssigned();
}

class ProgressLoaded extends CampanaState {
  final List<DoctorProgress> progress;

  const ProgressLoaded({required this.progress});

  @override
  List<Object?> get props => [progress];
}

class ReconsultaImportada extends CampanaState {
  const ReconsultaImportada();
}

class CampanaError extends CampanaState {
  final String message;

  const CampanaError(this.message);

  @override
  List<Object?> get props => [message];
}
