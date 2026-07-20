import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class SyncFailure extends Failure {
  const SyncFailure(super.message);
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

class CameraFailure extends Failure {
  const CameraFailure(super.message);
}

class S3Failure extends Failure {
  const S3Failure(super.message);
}
