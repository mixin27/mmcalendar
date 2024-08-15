import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmcalendar/app_start_up.dart';
import 'package:mmcalendar/src/features/app/app.dart';
import 'package:mmcalendar/src/l10n/l10n.dart';
import 'package:mmcalendar/src/shared/errors/async_error_logger.dart';
import 'package:mmcalendar/src/shared/errors/error_logger.dart';
// import 'package:mmcalendar/src/utils/onesignal/onesignal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final container = ProviderContainer(
    observers: [AsyncErrorLogger()],
  );

  // * Register error handlers. For more info, see:
  // * https://docs.flutter.dev/testing/errors
  final errorLogger = container.read(errorLoggerProvider);
  registerErrorHandlers(errorLogger);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        supportedLocales: L10n.all,
        path: L10n.translationPath,
        fallbackLocale: L10n.en,
        useOnlyLangCode: true,
        child: AppStartUpWidget(
          onLoaded: (context) => AppWidget(),
        ),
      ),
    ),
  );
}

void registerErrorHandlers(ErrorLogger errorLogger) {
  // * Show some error UI if any uncaught exception happens
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    errorLogger.logError(details.exception, details.stack);

    if (kReleaseMode) {
      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // * Handle errors from the underlying platform/OS
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    errorLogger.logError(error, stack);

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  // * Show some error UI when any widget in the app fails to build
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text('An error occurred'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Text(details.toString()),
        ),
      ),
    );
  };
}
