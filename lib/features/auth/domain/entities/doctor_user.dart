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

  // Map conversion handled by UserFactory in data layer
}
