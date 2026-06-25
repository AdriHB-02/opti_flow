import 'package:equatable/equatable.dart';

import '../../domain/usecases/create_campana_usecase.dart';
import '../../domain/usecases/import_pacientes_reconsulta_usecase.dart';

abstract class CampanaEvent extends Equatable {
  const CampanaEvent();

  @override
  List<Object?> get props => [];
}

class CreateCampana extends CampanaEvent {
  final CreateCampanaParams params;

  const CreateCampana({required this.params});

  @override
  List<Object?> get props => [params];
}

class LoadCampanas extends CampanaEvent {
  final String doctorId;

  const LoadCampanas({required this.doctorId});

  @override
  List<Object?> get props => [doctorId];
}

class AssignDoctor extends CampanaEvent {
  final String campanaId;
  final String doctorId;

  const AssignDoctor({
    required this.campanaId,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [campanaId, doctorId];
}

class LoadProgress extends CampanaEvent {
  final String campanaId;

  const LoadProgress({required this.campanaId});

  @override
  List<Object?> get props => [campanaId];
}

class ImportReconsulta extends CampanaEvent {
  final ImportReconsultaParams params;

  const ImportReconsulta({required this.params});

  @override
  List<Object?> get props => [params];
}
