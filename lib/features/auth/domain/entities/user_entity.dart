import 'package:equatable/equatable.dart';

enum UserRole { admin, jefe, user }

enum Feature {
  manageDoctors,
  viewStats,
  viewCompanies,
  createCampana,
  assignDoctors,
  viewCampanaProgress,
  registerPatient,
  viewPatients,
  searchPatient,
  importReconsulta,
  viewHistoria,
  compareDiagnosticos,
}

abstract class UserEntity extends Equatable {
  final String id;
  final String nombre;
  final String email;
  final UserRole rol;
  final bool activo;

  const UserEntity({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
  });

  bool canAccess(Feature feature);

  @override
  List<Object?> get props => [id, nombre, email, rol, activo];
}
