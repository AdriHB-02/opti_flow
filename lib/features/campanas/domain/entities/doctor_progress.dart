import 'package:equatable/equatable.dart';

class DoctorProgress extends Equatable {
  final String doctorId;
  final String doctorNombre;
  final int totalPacientes;

  const DoctorProgress({
    required this.doctorId,
    required this.doctorNombre,
    required this.totalPacientes,
  });

  @override
  List<Object?> get props => [doctorId, doctorNombre, totalPacientes];
}
