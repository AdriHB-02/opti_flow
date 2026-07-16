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

  Future<void> _onLoadDoctors(
    LoadDoctors event,
    Emitter<AdminState> emit,
  ) async {
    _currentFilters = event.filters;
    emit(const AdminLoading());
    final result = await _getAllDoctorsUseCase(event.filters);
    emit(result.fold(
      (failure) {
        debugPrint('[AdminBloc] _onLoadDoctors failure: ${failure.message}');
        return AdminError(failure.message);
      },
      (doctors) => DoctorsLoaded(doctors: doctors),
    ));
  }

  Future<void> _onUpdateDoctorFilters(
    UpdateDoctorFilters event,
    Emitter<AdminState> emit,
  ) async {
    _currentFilters = event.filters;
    emit(const AdminLoading());
    final result = await _getAllDoctorsUseCase(event.filters);
    emit(result.fold(
      (failure) {
        debugPrint('[AdminBloc] _onUpdateDoctorFilters failure: ${failure.message}');
        return AdminError(failure.message);
      },
      (doctors) => DoctorsLoaded(doctors: doctors),
    ));
  }

  Future<void> _onLoadStats(
    LoadStats event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await _getGlobalStatsUseCase(const NoParams());
    emit(result.fold(
      (failure) {
        debugPrint('[AdminBloc] _onLoadStats failure: ${failure.message}');
        return AdminError(failure.message);
      },
      (stats) => StatsLoaded(stats: stats),
    ));
  }

  Future<void> _onLoadPatientsByMonth(
    LoadPatientsByMonth event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await _getPatientsByMonthUseCase(const NoParams());
    emit(result.fold(
      (failure) {
        debugPrint('[AdminBloc] _onLoadPatientsByMonth failure: ${failure.message}');
        return AdminError(failure.message);
      },
      (data) => PatientsByMonthLoaded(data: data),
    ));
  }

  Future<void> _onDeleteDoctor(
    DeleteDoctor event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await _deleteDoctorAccountUseCase(
      DeleteDoctorAccountParams(doctorId: event.doctorId),
    );
    emit(result.fold(
      (failure) {
        debugPrint('[AdminBloc] _onDeleteDoctor failure: ${failure.message}');
        return AdminError(failure.message);
      },
      (_) {
        add(LoadDoctors(filters: _currentFilters));
        return const DoctorDeleted();
      },
    ));
  }
}
