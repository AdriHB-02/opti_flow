import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class BiometricLoginUseCase extends UseCase<UserEntity, NoParams> {
  final IAuthRepository repository;

  BiometricLoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    try {
      final user = await repository.loginBiometrico();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
