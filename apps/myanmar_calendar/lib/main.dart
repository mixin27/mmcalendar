import 'package:data/data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'config/bloc_observer.dart';
import 'config/di_setup.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TranslationService.addTranslation("test", Language.myanmar, "Test");

  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString(
      'assets/fonts/google_fonts/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['google_fonts'], license);
  });

  // Firebase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure system UI
  await _configureSystemUI();

  // Initialize dependency injection
  await initializeDependencies();

  // Initialize WorkManager for background widget updates
  await Workmanager().initialize(callbackDispatcher);

  // Load saved settings and configure Myanmar Calendar
  await _initializeMyanmarCalendar();

  // Schedule widget updates on app start
  await _initializeWidgetUpdates();

  // Set up Bloc observer
  Bloc.observer = AppBlocObserver();

  registerErrorHandlers();

  runApp(const MyanmarCalendarApp());
}

// Initialize Myanmar Calendar with saved settings
Future<void> _initializeMyanmarCalendar() async {
  try {
    final database = getIt<AppDatabase>();
    final settingsDao = database.settingsDao;

    // Load calendar configuration from database
    final sasanaYearType = await settingsDao.getSetting('sasana_year_type');
    final calendarType = await settingsDao.getSetting('calendar_type');
    final timezoneOffset = await settingsDao.getSetting('timezone_offset');
    final gregorianStart = await settingsDao.getSetting('gregorian_start');
    final calendarLanguage = await settingsDao.getSetting('calendar_language');

    // Configure Myanmar Calendar with saved settings
    MyanmarCalendar.configure(
      language: Language.fromCode(calendarLanguage ?? 'en'),
      timezoneOffset: double.tryParse(timezoneOffset ?? '6.5') ?? 6.5,
      sasanaYearType: int.tryParse(sasanaYearType ?? '0') ?? 0,
      calendarType: int.tryParse(calendarType ?? '0') ?? 0,
      gregorianStart: int.tryParse(gregorianStart ?? '2361222') ?? 2361222,
    );

    debugPrint('✅ Myanmar Calendar initialized with saved settings');
  } catch (e) {
    // If loading fails, use defaults
    MyanmarCalendar.configure(
      language: Language.english,
      timezoneOffset: 6.5,
      sasanaYearType: 0,
      calendarType: 0,
      gregorianStart: 2361222,
    );
    debugPrint('⚠️ Myanmar Calendar initialized with defaults: $e');
  }

  MyanmarCalendar.configureCache(const CacheConfig.memoryEfficient());
}

// Initialize widget updates
Future<void> _initializeWidgetUpdates() async {
  try {
    // Import the repository from DI
    final widgetRepository = getIt<WidgetRepository>();

    // Schedule daily updates at 12:01 AM
    await widgetRepository.scheduleWidgetUpdates();

    // Update widget immediately on app start
    await widgetRepository.refreshWidget();

    debugPrint('✅ Widget updates scheduled successfully');
  } catch (e) {
    debugPrint('⚠️ Failed to initialize widget updates: $e');
  }
}

/// Configure system UI overlays and orientation
Future<void> _configureSystemUI() async {
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Enable edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

void registerErrorHandlers() {
  // * Show some error UI if any uncaught exception happens
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(details.toString());

    if (kReleaseMode) {
      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // * Handle errors from the underlying platform/OS
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint(error.toString());

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ErrorBoundary.errorWidget(details);
  };
}

// Error handling widget
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? errorMessage;

  const ErrorBoundary({super.key, required this.child, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return child;
  }

  static Widget errorWidget(FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please restart the app',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    details.exception.toString(),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
