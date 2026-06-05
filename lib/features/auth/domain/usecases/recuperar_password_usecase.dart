import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/i_auth_repository.dart';

class RecuperarPasswordParams extends Equatable {
  final String email;

  const RecuperarPasswordParams({required this.email});

  @override
  List<Object?> get props => [email];
}

class RecuperarPasswordUseCase extends UseCase<void, RecuperarPasswordParams> {
  final IAuthRepository repository;

  RecuperarPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RecuperarPasswordParams params) async {
    try {
      await repository.recuperarPassword(params.email);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
