import 'user_entity.dart';

class JefeUser extends UserEntity {
  const JefeUser({
    required super.id,
    required super.nombre,
    required super.email,
    required super.activo,
  }) : super(rol: UserRole.jefe);

  @override
  bool canAccess(Feature feature) {
    switch (feature) {
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
      case Feature.manageDoctors:
      case Feature.viewStats:
      case Feature.viewCompanies:
        return false;
    }
  }

  void createCampana(Object campana) {
    throw UnimplementedError();
  }

  void assignDoctor(String doctorId, String campanaId) {
    throw UnimplementedError();
  }

  void getCampanaProgress(String campanaId) {
    throw UnimplementedError();
  }

  factory JefeUser.fromMap(Map<String, dynamic> data) {
    return JefeUser(
      id: data['id'] as String,
      nombre: data['nombre'] as String,
      email: data['email'] as String,
      activo: (data['activo'] as int) == 1,
    );
  }
}
