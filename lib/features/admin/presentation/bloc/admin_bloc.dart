import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/doctor_filters.dart';
import '../../domain/usecases/delete_doctor_account_usecase.dart';
import '../../domain/usecases/get_all_doctors_usecase.dart';
import '../../domain/usecases/get_global_stats_usecase.dart';
import '../../domain/usecases/get_patients_by_month_usecase.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final GetAllDoctorsUseCase _getAllDoctorsUseCase;
  final DeleteDoctorAccountUseCase _deleteDoctorAccountUseCase;
  final GetGlobalStatsUseCase _getGlobalStatsUseCase;
  final GetPatientsByMonthUseCase _getPatientsByMonthUseCase;

  DoctorFilters _currentFilters = const DoctorFilters();

  AdminBloc({
    required GetAllDoctorsUseCase getAllDoctorsUseCase,
    required DeleteDoctorAccountUseCase deleteDoctorAccountUseCase,
    required GetGlobalStatsUseCase getGlobalStatsUseCase,
    required GetPatientsByMonthUseCase getPatientsByMonthUseCase,
  })  : _getAllDoctorsUseCase = getAllDoctorsUseCase,
        _deleteDoctorAccountUseCase = deleteDoctorAccountUseCase,
        _getGlobalStatsUseCase = getGlobalStatsUseCase,
        _getPatientsByMonthUseCase = getPatientsByMonthUseCase,
        super(const AdminInitial()) {
    on<LoadDoctors>(_onLoadDoctors);
    on<UpdateDoctorFilters>(_onUpdateDoctorFilters);
    on<LoadStats>(_onLoadStats);
    on<LoadPatientsByMonth>(_onLoadPatientsByMonth);
    on<DeleteDoctor>(_onDeleteDoctor);
  }

  AdminReady _ensureReady(AdminState state) {
    if (state is AdminReady) return state;
    return const AdminReady();
  }

  Future<void> _onLoadDoctors(
    LoadDoctors event,
    Emitter<AdminState> emit,
  ) async {
    _currentFilters = event.filters;
    final current = _ensureReady(state);
    emit(current.copyWith(doctorsLoading: true, clearDoctorsError: true));
    final result = await _getAllDoctorsUseCase(event.filters);
    final current2 = _ensureReady(state);
    emit(result.fold(
      (failure) {
        debugPrint('[AdminBloc] _onLoadDoctors failure: ${failure.message}');
        return current2.copyWith(
          doctorsLoading: false,
          doctorsError: failure.message,
        );
      },
      (doctors) => current2.copyWith(
        doctorsLoading: false,
        doctors: doctors,
      ),
    ));
  }

  Future<void> _onUpdateDoctorFilters(
    UpdateDoctorFilters event,
    Emitter<AdminState> emit,
  ) async {
    _currentFilters = event.filters;
    final current = _ensureReady(state);
    emit(current.copyWith(doctorsLoading: true, clearDoctorsError: true));
    final result = await _getAllDoctorsUseCase(event.filters);
    final current2 = _ensureReady(state);
    emit(result.fold(
      (failure) {
        debugPrint('[AdminBloc] _onUpdateDoctorFilters failure: ${failure.message}');
        return current2.copyWith(
          doctorsLoading: false,
          doctorsError: failure.message,
        );
      },
      (doctors) => current2.copyWith(
        doctorsLoading: false,
        doctors: doctors,
      ),
    ));
  }

  Future<void> _onLoadStats(
    LoadStats event,
    Emitter<AdminState> emit,
  ) async {
    final current = _ensureReady(state);
    emit(current.copyWith(statsLoading: true, clearStatsError: true));
    final result = await _getGlobalStatsUseCase(const NoParams());
    final current2 = _ensureReady(state);
    emit(result.fold(
      (failure) {
        debugPrint('[AdminBloc] _onLoadStats failure: ${failure.message}');
        return current2.copyWith(
          statsLoading: false,
          statsError: failure.message,
        );
      },
      (stats) => current2.copyWith(
        statsLoading: false,
        stats: stats,
      ),
    ));
  }

  Future<void> _onLoadPatientsByMonth(
    LoadPatientsByMonth event,
    Emitter<AdminState> emit,
  ) async {
    final current = _ensureReady(state);
    emit(current.copyWith(patientsLoading: true, clearPatientsError: true));
    final result = await _getPatientsByMonthUseCase(const NoParams());
    final current2 = _ensureReady(state);
    emit(result.fold(
      (failure) {
        debugPrint('[AdminBloc] _onLoadPatientsByMonth failure: ${failure.message}');
        return current2.copyWith(
          patientsLoading: false,
          patientsError: failure.message,
        );
      },
      (data) => current2.copyWith(
        patientsLoading: false,
        patientsByMonth: data,
      ),
    ));
  }

  Future<void> _onDeleteDoctor(
    DeleteDoctor event,
    Emitter<AdminState> emit,
  ) async {
    final result = await _deleteDoctorAccountUseCase(
      DeleteDoctorAccountParams(
        doctorId: event.doctorId,
        currentUserId: event.currentUserId,
      ),
    );
    final current = _ensureReady(state);
    emit(result.fold(
      (failure) => current.copyWith(doctorsError: failure.message),
      (_) => current.copyWith(deleteSuccess: true),
    ));
    add(LoadDoctors(filters: _currentFilters));
  }
}
