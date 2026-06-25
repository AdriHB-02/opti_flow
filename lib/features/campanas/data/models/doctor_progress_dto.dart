import '../../domain/entities/doctor_progress.dart';

class DoctorProgressDTO {
  final String doctorId;
  final String doctorNombre;
  final int totalPacientes;

  const DoctorProgressDTO({
    required this.doctorId,
    required this.doctorNombre,
    required this.totalPacientes,
  });

  DoctorProgress toEntity() {
    return DoctorProgress(
      doctorId: doctorId,
      doctorNombre: doctorNombre,
      totalPacientes: totalPacientes,
    );
  }

  factory DoctorProgressDTO.fromMap(Map<String, dynamic> map) {
    return DoctorProgressDTO(
      doctorId: map['doctor_id'] as String,
      doctorNombre: map['doctor_nombre'] as String,
      totalPacientes: (map['total_pacientes'] as int),
    );
  }
}
