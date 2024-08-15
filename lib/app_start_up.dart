import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmcalendar/firebase_options.dart';
import 'package:mmcalendar/src/shared/providers/mm_calendar_providers.dart';
import 'package:mmcalendar/src/utils/shared_prefs/preference_manager.dart';
// import 'package:mmcalendar/src/utils/onesignal/onesignal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_start_up.g.dart';

@Riverpod(keepAlive: true)
FutureOr<void> appStartup(AppStartupRef ref) async {
  ref.onDispose(() {
    // ensure we invalidate all the providers we depend on
    // ref.invalidate(onboardingRepositoryProvider);
    ref.invalidate(sharedPreferencesProvider);
    ref.invalidate(mmCalendarConfigControllerProvider);
  });

  // await for all initialization code to be complete before returning
  // we can use `Future.wait` for independent long run tasks.
  await Future.wait([
    // Firebase init
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    // initOnesignal(),

    // list of providers to be warmed up
    // ref.watch(onboardingRepositoryProvider.future),
    ref.watch(sharedPreferencesProvider.future),
  ]);

  ref.watch(mmCalendarConfigControllerProvider);
}

/// Widget class to manage asynchronous app initialization
class AppStartUpWidget extends ConsumerWidget {
  const AppStartUpWidget({
    super.key,
    required this.onLoaded,
  });

  final WidgetBuilder onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStartupState = ref.watch(appStartupProvider);

    return appStartupState.when(
      data: (_) => onLoaded(context),
      loading: () => const AppStartupLoadingWidget(),
      error: (e, st) => AppStartupErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(appStartupProvider),
      ),
    );
  }
}

class AppStartupLoadingWidget extends StatelessWidget {
  const AppStartupLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator.adaptive(),
            ],
          ),
        ),
      ),
    );
  }
}

class AppStartupErrorWidget extends StatelessWidget {
  const AppStartupErrorWidget(
      {super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
