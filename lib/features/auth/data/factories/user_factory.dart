import '../../domain/entities/user_entity.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/jefe_user.dart';
import '../../domain/entities/doctor_user.dart';

class UserFactory {
  static UserEntity fromMap(Map<String, dynamic> data) {
    final rol = data['rol'] as String;

    final rawActivo = data['activo'];
    final activo = rawActivo is bool
        ? rawActivo
        : (rawActivo as int) == 1;

    switch (rol) {
      case 'ADMIN':
        return AdminUser(
          id: data['id'] as String,
          nombre: data['nombre'] as String,
          email: data['email'] as String,
          activo: activo,
        );
      case 'JEFE':
        return JefeUser(
          id: data['id'] as String,
          nombre: data['nombre'] as String,
          email: data['email'] as String,
          activo: activo,
        );
      case 'USER':
        return DoctorUser(
          id: data['id'] as String,
          nombre: data['nombre'] as String,
          email: data['email'] as String,
          activo: activo,
          dependenciaLocalId: data['dependencia_local_id'] as String? ?? '',
        );
      default:
        throw ArgumentError('Unknown rol: $rol');
    }
  }
}
