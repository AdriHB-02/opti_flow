import 'user_entity.dart';

class DoctorUser extends UserEntity {
  final String dependenciaLocalId;

  const DoctorUser({
    required super.id,
    required super.nombre,
    required super.email,
    required super.activo,
    required this.dependenciaLocalId,
  }) : super(rol: UserRole.user);

  @override
  bool canAccess(Feature feature) {
    switch (feature) {
      case Feature.registerPatient:
      case Feature.viewPatients:
      case Feature.searchPatient:
      case Feature.importReconsulta:
      case Feature.viewHistoria:
      case Feature.compareDiagnosticos:
        return true;
      case Feature.manageDoctors:
      case Feature.viewStats:
      case Feature.viewCompanies:
      case Feature.createCampana:
      case Feature.assignDoctors:
      case Feature.viewCampanaProgress:
        return false;
    }
  }

  void registerPatient(Object patient) {
    throw UnimplementedError();
  }

  void getPatients(String dependenciaId) {
    throw UnimplementedError();
  }

  factory DoctorUser.fromMap(Map<String, dynamic> data) {
    return DoctorUser(
      id: data['id'] as String,
      nombre: data['nombre'] as String,
      email: data['email'] as String,
      activo: (data['activo'] as int) == 1,
      dependenciaLocalId: data['dependencia_local_id'] as String? ?? '',
    );
  }
}
