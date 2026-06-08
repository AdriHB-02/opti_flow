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
    return UserFactory.fromMap(data);
  }

  @override
  Future<UserEntity> loginBiometrico() async {
    final data = await _remoteDataSource.loginBiometrico();
    return UserFactory.fromMap(data);
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
