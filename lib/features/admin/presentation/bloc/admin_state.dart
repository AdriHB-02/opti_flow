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

class AdminLoading extends AdminState {
  const AdminLoading();
}

class DoctorsLoaded extends AdminState {
  final List<UserEntity> doctors;

  const DoctorsLoaded({required this.doctors});

  @override
  List<Object?> get props => [doctors];
}

class StatsLoaded extends AdminState {
  final GlobalStats stats;

  const StatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class PatientsByMonthLoaded extends AdminState {
  final List<PatientsByMonth> data;

  const PatientsByMonthLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class DoctorDeleted extends AdminState {
  const DoctorDeleted();
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
