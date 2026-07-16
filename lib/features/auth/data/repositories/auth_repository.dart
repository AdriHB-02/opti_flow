import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote_auth_data_source.dart';
import '../factories/user_factory.dart';

class AuthRepository implements IAuthRepository {
  final RemoteAuthDataSource _remoteDataSource;

  AuthRepository({required RemoteAuthDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<UserEntity> login(String email, String password) async {
    final data = await _remoteDataSource.login(email, password);
    try {
      return UserFactory.fromMap(data);
    } catch (e) {
      throw Exception('Error al procesar datos de usuario: $e');
    }
  }

  @override
  Future<UserEntity> loginBiometrico() async {
    final data = await _remoteDataSource.loginBiometrico();
    try {
      return UserFactory.fromMap(data);
    } catch (e) {
      throw Exception('Error al procesar datos de usuario: $e');
    }
  }

  @override
  Future<UserEntity> loginWithGoogle() async {
    final data = await _remoteDataSource.loginWithGoogle();
    try {
      return UserFactory.fromMap(data);
    } catch (e) {
      throw Exception('Error al procesar datos de usuario de Google: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
  }

  @override
  Future<void> recuperarPassword(String email) async {
    await _remoteDataSource.resetPassword(email);
  }
}
