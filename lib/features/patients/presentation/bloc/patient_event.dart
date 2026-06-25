import 'package:equatable/equatable.dart';

import '../../domain/usecases/register_patient_usecase.dart';

abstract class PatientEvent extends Equatable {
  const PatientEvent();

  @override
  List<Object?> get props => [];
}

class LoadPatients extends PatientEvent {
  final String dependenciaId;
  final String doctorId;

  const LoadPatients({
    required this.dependenciaId,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [dependenciaId, doctorId];
}

class SavePatient extends PatientEvent {
  final RegisterPatientParams input;

  const SavePatient({required this.input});

  @override
  List<Object?> get props => [input];
}

class SearchPatient extends PatientEvent {
  final String query;
  final String dependenciaId;
  final String doctorId;

  const SearchPatient({
    required this.query,
    required this.dependenciaId,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [query, dependenciaId, doctorId];
}
