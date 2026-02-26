import 'package:equatable/equatable.dart';

/// Base class for all failures
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

/// Failure from server/API
class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

/// Failure from local cache/database
class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.code]);
}

/// Failure from network connection
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

/// Failure from invalid data
class DataFailure extends Failure {
  const DataFailure(super.message, [super.code]);
}

/// Failure from validation
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

/// Failure from authentication
class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.code]);
}

/// Failure from permission
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.code]);
}

/// Unknown/unexpected failure
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code]);
}
