import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/assign_doctor_to_campana_usecase.dart';
import '../../domain/usecases/create_campana_usecase.dart';
import '../../domain/usecases/get_campana_progress_usecase.dart';
import '../../domain/usecases/get_campanas_by_doctor_usecase.dart';
import '../../domain/usecases/import_pacientes_reconsulta_usecase.dart';
import 'campana_event.dart';
import 'campana_state.dart';

class CampanaBloc extends Bloc<CampanaEvent, CampanaState> {
  final CreateCampanaUseCase _createCampanaUseCase;
  final AssignDoctorToCampanaUseCase _assignDoctorToCampanaUseCase;
  final GetCampanaProgressUseCase _getCampanaProgressUseCase;
  final ImportPacientesReconsultaUseCase _importPacientesReconsultaUseCase;
  final GetCampanasByDoctorUseCase _getCampanasByDoctorUseCase;

  CampanaBloc({
    required CreateCampanaUseCase createCampanaUseCase,
    required AssignDoctorToCampanaUseCase assignDoctorToCampanaUseCase,
    required GetCampanaProgressUseCase getCampanaProgressUseCase,
    required ImportPacientesReconsultaUseCase importPacientesReconsultaUseCase,
    required GetCampanasByDoctorUseCase getCampanasByDoctorUseCase,
  })  : _createCampanaUseCase = createCampanaUseCase,
        _assignDoctorToCampanaUseCase = assignDoctorToCampanaUseCase,
        _getCampanaProgressUseCase = getCampanaProgressUseCase,
        _importPacientesReconsultaUseCase = importPacientesReconsultaUseCase,
        _getCampanasByDoctorUseCase = getCampanasByDoctorUseCase,
        super(const CampanaInitial()) {
    on<CreateCampana>(_onCreateCampana);
    on<AssignDoctor>(_onAssignDoctor);
    on<LoadProgress>(_onLoadProgress);
    on<ImportReconsulta>(_onImportReconsulta);
    on<LoadCampanas>(_onLoadCampanas);
  }

  Future<void> _onCreateCampana(
    CreateCampana event,
    Emitter<CampanaState> emit,
  ) async {
    emit(const CampanaLoading());
    final result = await _createCampanaUseCase(event.params);
    emit(result.fold(
      (failure) => CampanaError(failure.message),
      (campanaResult) {
        if (campanaResult.existeHistorialPrevio) {
          return HistorialPrevioDetectado(
            campanasAnteriores: campanaResult.campanasAnteriores,
          );
        }
        return CampanaCreated(campanaResult.campanaCreada!);
      },
    ));
  }

  Future<void> _onAssignDoctor(
    AssignDoctor event,
    Emitter<CampanaState> emit,
  ) async {
    emit(const CampanaLoading());
    final result = await _assignDoctorToCampanaUseCase(
      AssignDoctorParams(
        campanaId: event.campanaId,
        doctorId: event.doctorId,
      ),
    );
    emit(result.fold(
      (failure) => CampanaError(failure.message),
      (_) => const DoctorAssigned(),
    ));
  }

  Future<void> _onLoadProgress(
    LoadProgress event,
    Emitter<CampanaState> emit,
  ) async {
    emit(const CampanaLoading());
    final result = await _getCampanaProgressUseCase(
      GetCampanaProgressParams(campanaId: event.campanaId),
    );
    emit(result.fold(
      (failure) => CampanaError(failure.message),
      (progress) => ProgressLoaded(progress: progress),
    ));
  }

  Future<void> _onImportReconsulta(
    ImportReconsulta event,
    Emitter<CampanaState> emit,
  ) async {
    emit(const CampanaLoading());
    final result = await _importPacientesReconsultaUseCase(event.params);
    emit(result.fold(
      (failure) => CampanaError(failure.message),
      (_) => const ReconsultaImportada(),
    ));
  }

  Future<void> _onLoadCampanas(
    LoadCampanas event,
    Emitter<CampanaState> emit,
  ) async {
    emit(const CampanaLoading());
    final result = await _getCampanasByDoctorUseCase(
      GetCampanasByDoctorParams(doctorId: event.doctorId),
    );
    emit(result.fold(
      (failure) => CampanaError(failure.message),
      (campanas) => CampanasLoaded(campanas: campanas),
    ));
  }
}
