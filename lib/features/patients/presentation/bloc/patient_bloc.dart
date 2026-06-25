import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/usecases/get_patients_usecase.dart';
import '../../domain/usecases/register_patient_usecase.dart';
import '../../domain/usecases/search_patient_usecase.dart';
import 'patient_event.dart';
import 'patient_state.dart';

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final GetPatientsUseCase _getPatientsUseCase;
  final RegisterPatientUseCase _registerPatientUseCase;
  final SearchPatientUseCase _searchPatientUseCase;

  PatientBloc({
    required GetPatientsUseCase getPatientsUseCase,
    required RegisterPatientUseCase registerPatientUseCase,
    required SearchPatientUseCase searchPatientUseCase,
  })  : _getPatientsUseCase = getPatientsUseCase,
        _registerPatientUseCase = registerPatientUseCase,
        _searchPatientUseCase = searchPatientUseCase,
        super(const PatientInitial()) {
    on<LoadPatients>(_onLoadPatients);
    on<SavePatient>(_onSavePatient);
    on<SearchPatient>(_onSearchPatient);
  }

  Future<void> _onLoadPatients(
    LoadPatients event,
    Emitter<PatientState> emit,
  ) async {
    emit(const PatientLoading());
    final result = await _getPatientsUseCase(
      GetPatientsParams(
        dependenciaId: event.dependenciaId,
        doctorId: event.doctorId,
      ),
    );
    emit(_resultToPatientsLoadedOrError(result));
  }

  Future<void> _onSavePatient(
    SavePatient event,
    Emitter<PatientState> emit,
  ) async {
    emit(const PatientLoading());
    final result = await _registerPatientUseCase(event.input);
    emit(result.fold(
      (failure) => PatientError(failure.message),
      (_) => const PatientSaved(),
    ));
  }

  Future<void> _onSearchPatient(
    SearchPatient event,
    Emitter<PatientState> emit,
  ) async {
    emit(const PatientLoading());
    final result = await _searchPatientUseCase(
      SearchPatientParams(
        query: event.query,
        dependenciaId: event.dependenciaId,
        doctorId: event.doctorId,
      ),
    );
    emit(_resultToPatientsLoadedOrError(result));
  }

  PatientState _resultToPatientsLoadedOrError(
    Either<Failure, List<PatientEntity>> result,
  ) {
    return result.fold(
      (failure) => PatientError(failure.message),
      (patients) => PatientsLoaded(patients: patients),
    );
  }
}
