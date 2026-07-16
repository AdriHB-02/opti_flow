import 'package:equatable/equatable.dart';

import '../../domain/entities/doctor_filters.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadDoctors extends AdminEvent {
  final DoctorFilters filters;

  const LoadDoctors({this.filters = const DoctorFilters()});

  @override
  List<Object?> get props => [filters];
}

class UpdateDoctorFilters extends AdminEvent {
  final DoctorFilters filters;

  const UpdateDoctorFilters({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class LoadStats extends AdminEvent {
  const LoadStats();
}

class LoadPatientsByMonth extends AdminEvent {
  const LoadPatientsByMonth();
}

class DeleteDoctor extends AdminEvent {
  final String doctorId;
  final String currentUserId;

  const DeleteDoctor({
    required this.doctorId,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [doctorId, currentUserId];
}
