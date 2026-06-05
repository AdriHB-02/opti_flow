import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> loginBiometrico();
  Future<void> logout();
  Future<void> recuperarPassword(String email);
}
