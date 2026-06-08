import '../../domain/entities/user_entity.dart';
import '../../domain/entities/doctor_user.dart';
import '../factories/user_factory.dart';

class UserDTO {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String? dependenciaLocalId;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserDTO({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.dependenciaLocalId,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDTO.fromEntity(UserEntity entity) {
    String? depId;
    if (entity is DoctorUser) {
      depId = entity.dependenciaLocalId;
    }
    return UserDTO(
      id: entity.id,
      nombre: entity.nombre,
      email: entity.email,
      rol: entity.rol.name.toUpperCase(),
      dependenciaLocalId: depId,
      activo: entity.activo,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  UserEntity toEntity() {
    return UserFactory.fromMap(toMap());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'dependencia_local_id': dependenciaLocalId,
      'activo': activo ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserDTO.fromMap(Map<String, dynamic> map) {
    return UserDTO(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      email: map['email'] as String,
      rol: map['rol'] as String,
      dependenciaLocalId: map['dependencia_local_id'] as String?,
      activo: (map['activo'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
