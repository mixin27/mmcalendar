/// Base exception class
class AppException implements Exception {
  final String message;
  final int? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() =>
      'AppException: $message ${code != null ? '(code: $code)' : ''}';
}

/// Exception from server/API
class ServerException extends AppException {
  const ServerException(super.message, [super.code]);
}

/// Exception from local cache/database
class CacheException extends AppException {
  const CacheException(super.message, [super.code]);
}

/// Exception from network connection
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

/// Exception from invalid data
class DataException extends AppException {
  const DataException(super.message, [super.code]);
}

/// Exception from validation
class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);
}

/// Exception from authentication
class AuthException extends AppException {
  const AuthException(super.message, [super.code]);
}

/// Exception from permission
class PermissionException extends AppException {
  const PermissionException(super.message, [super.code]);
}
