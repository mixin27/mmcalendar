import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:myanmar_calendar_wear/settings/watch_settings.dart';
import 'package:myanmar_calendar_wear/watch_payload/watch_payload_scheduler.dart';
import 'package:myanmar_calendar_wear/watch_payload/watch_payload_writer.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

/// Loads the saved calendar language and runs the app, then writes the
/// Tile and complication payload for today and schedules the daily rewrite.
Future<void> bootstrap(Widget Function(WatchSettings settings) builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };
  Bloc.observer = const AppBlocObserver();

  final settings = await WatchSettings.load();
  runApp(builder(settings));

  // After the first frame: building 90 days takes a moment on a watch.
  await WidgetsBinding.instance.endOfFrame;
  unawaited(WatchPayloadWriter(settings.preferences).write(settings.language));
  unawaited(WatchPayloadScheduler.schedule());
}
