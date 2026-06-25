import 'package:equatable/equatable.dart';

import '../../domain/entities/patient_entity.dart';

abstract class PatientState extends Equatable {
  const PatientState();

  @override
  List<Object?> get props => [];
}

class PatientInitial extends PatientState {
  const PatientInitial();
}

class PatientLoading extends PatientState {
  const PatientLoading();
}

class PatientsLoaded extends PatientState {
  final List<PatientEntity> patients;

  const PatientsLoaded({required this.patients});

  @override
  List<Object?> get props => [patients];
}

class PatientSaved extends PatientState {
  const PatientSaved();
}

class PatientError extends PatientState {
  final String message;

  const PatientError(this.message);

  @override
  List<Object?> get props => [message];
}
