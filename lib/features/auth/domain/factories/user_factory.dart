import '../entities/user_entity.dart';
import '../entities/admin_user.dart';
import '../entities/jefe_user.dart';
import '../entities/doctor_user.dart';

class UserFactory {
  static UserEntity create(Map<String, dynamic> data) {
    final rol = data['rol'] as String;
    switch (rol) {
      case 'ADMIN':
        return AdminUser.fromMap(data);
      case 'JEFE':
        return JefeUser.fromMap(data);
      default:
        return DoctorUser.fromMap(data);
    }
  }
}
