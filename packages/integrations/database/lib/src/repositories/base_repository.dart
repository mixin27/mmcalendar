import 'package:shared_core/shared_core.dart';

/// Base repository with common error handling
abstract class BaseRepository {
  /// Handle exceptions and convert to failures
  Failure handleException(Exception exception) {
    if (exception is CacheException) {
      return CacheFailure(exception.message, exception.code);
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message, exception.code);
    } else if (exception is DataException) {
      return DataFailure(exception.message, exception.code);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message, exception.code);
    } else {
      return UnknownFailure(exception.toString());
    }
  }

  /// Execute with error handling
  Future<T> executeWithErrorHandling<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException catch (e) {
      throw handleException(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
