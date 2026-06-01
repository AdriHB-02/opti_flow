import 'user_entity.dart';

class AdminUser extends UserEntity {
  const AdminUser({
    required super.id,
    required super.nombre,
    required super.email,
    required super.activo,
  }) : super(rol: UserRole.admin);

  @override
  bool canAccess(Feature feature) {
    switch (feature) {
      case Feature.manageDoctors:
      case Feature.viewStats:
      case Feature.viewCompanies:
      case Feature.createCampana:
      case Feature.assignDoctors:
      case Feature.viewCampanaProgress:
      case Feature.registerPatient:
      case Feature.viewPatients:
      case Feature.searchPatient:
      case Feature.importReconsulta:
      case Feature.viewHistoria:
      case Feature.compareDiagnosticos:
        return true;
    }
  }

  void deleteAccount(String doctorId) {
    throw UnimplementedError();
  }

  void getGlobalStats() {
    throw UnimplementedError();
  }

  void listAllDoctors() {
    throw UnimplementedError();
  }

  factory AdminUser.fromMap(Map<String, dynamic> data) {
    return AdminUser(
      id: data['id'] as String,
      nombre: data['nombre'] as String,
      email: data['email'] as String,
      activo: (data['activo'] as int) == 1,
    );
  }
}
