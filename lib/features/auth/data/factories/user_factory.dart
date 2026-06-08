import '../../domain/entities/user_entity.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/jefe_user.dart';
import '../../domain/entities/doctor_user.dart';

class UserFactory {
  static UserEntity fromMap(Map<String, dynamic> data) {
    final rol = data['rol'] as String;
    switch (rol) {
      case 'ADMIN':
        return AdminUser(
          id: data['id'] as String,
          nombre: data['nombre'] as String,
          email: data['email'] as String,
          activo: (data['activo'] as int) == 1,
        );
      case 'JEFE':
        return JefeUser(
          id: data['id'] as String,
          nombre: data['nombre'] as String,
          email: data['email'] as String,
          activo: (data['activo'] as int) == 1,
        );
      default:
        return DoctorUser(
          id: data['id'] as String,
          nombre: data['nombre'] as String,
          email: data['email'] as String,
          activo: (data['activo'] as int) == 1,
          dependenciaLocalId: data['dependencia_local_id'] as String? ?? '',
        );
    }
  }
}
