import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/global_stats.dart';
import '../../domain/entities/patients_by_month.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminReady extends AdminState {
  final List<UserEntity> doctors;
  final bool doctorsLoading;
  final String? doctorsError;

  final GlobalStats? stats;
  final bool statsLoading;
  final String? statsError;

  final List<PatientsByMonth>? patientsByMonth;
  final bool patientsLoading;
  final String? patientsError;

  final bool deleteSuccess;

  const AdminReady({
    this.doctors = const [],
    this.doctorsLoading = false,
    this.doctorsError,
    this.stats,
    this.statsLoading = false,
    this.statsError,
    this.patientsByMonth,
    this.patientsLoading = false,
    this.patientsError,
    this.deleteSuccess = false,
  });

  AdminReady copyWith({
    List<UserEntity>? doctors,
    bool? doctorsLoading,
    String? doctorsError,
    bool clearDoctorsError = false,
    GlobalStats? stats,
    bool? statsLoading,
    String? statsError,
    bool clearStatsError = false,
    List<PatientsByMonth>? patientsByMonth,
    bool? patientsLoading,
    String? patientsError,
    bool clearPatientsError = false,
    bool? deleteSuccess,
  }) {
    return AdminReady(
      doctors: doctors ?? this.doctors,
      doctorsLoading: doctorsLoading ?? this.doctorsLoading,
      doctorsError: clearDoctorsError ? null : (doctorsError ?? this.doctorsError),
      stats: stats ?? this.stats,
      statsLoading: statsLoading ?? this.statsLoading,
      statsError: clearStatsError ? null : (statsError ?? this.statsError),
      patientsByMonth: patientsByMonth ?? this.patientsByMonth,
      patientsLoading: patientsLoading ?? this.patientsLoading,
      patientsError: clearPatientsError ? null : (patientsError ?? this.patientsError),
      deleteSuccess: deleteSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [
        doctors, doctorsLoading, doctorsError,
        stats, statsLoading, statsError,
        patientsByMonth, patientsLoading, patientsError,
        deleteSuccess,
      ];
}
