import 'dart:developer' as developer;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'exceptions.dart';

part 'error_logger.g.dart';

abstract class ErrorLogger {
  /// * This can be replaced with a call to a crash reporting tool of choice
  void logError(Object error, StackTrace? stackTrace);

  /// * This can be replaced with a call to a crash reporting tool of choice
  void logException(AppException exception);
}

class AppErrorLogger implements ErrorLogger {
  @override
  void logError(Object error, StackTrace? stackTrace) {
    // * This can be replaced with a call to a crash reporting tool of choice
    developer.log(error.toString(), error: error, stackTrace: stackTrace);
  }

  @override
  void logException(AppException exception) {
    // * This can be replaced with a call to a crash reporting tool of choice
    developer.log(exception.toString());
  }
}

@riverpod
ErrorLogger errorLogger(Ref ref) {
  return AppErrorLogger();
}
