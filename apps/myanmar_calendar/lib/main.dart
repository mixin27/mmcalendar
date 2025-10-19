import 'package:data/data.dart';
import 'package:firebase_analytics_app/firebase_analytics_app.dart';
import 'package:firebase_core/firebase_core.dart';
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

  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString(
      'assets/fonts/google_fonts/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['google_fonts'], license);
  });

  // Initialize Firebase with consent settings
  await _initializeFirebaseWithConsent();

  // Initialize dependency injection
  await initializeDependencies();

  // Configure system UI
  await _configureSystemUI();

  debugPrint('🔧 Initializing WorkManager...');
  // Initialize WorkManager for background widget updates
  await Workmanager().initialize(callbackDispatcher);

  // Load saved settings and configure Myanmar Calendar
  await _initializeMyanmarCalendar();

  // Set up Bloc observer
  Bloc.observer = AppBlocObserver();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ErrorBoundary.errorWidget(details);
  };

  // Schedule widget updates on app start
  await _initializeWidgetUpdates();

  runApp(const MyanmarCalendarApp());
}

Future<void> _initializeFirebaseWithConsent() async {
  try {
    debugPrint('🔧 Initializing Firebase...');

    // Initialize Firebase Core first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Load user consent settings from database
    final database = AppDatabase();
    final settingsDao = database.settingsDao;

    final analyticsConsent =
        await settingsDao.getSetting('enable_analytics') ?? 'true';
    final crashlyticsConsent =
        await settingsDao.getSetting('enable_crashlytics') ?? 'true';

    final enableAnalytics = analyticsConsent.toLowerCase() == 'true';
    final enableCrashlytics = crashlyticsConsent.toLowerCase() == 'true';

    // Create configs with user consent
    final analyticsConfig = AnalyticsConfig(
      enableCollection: enableAnalytics,
      enableDebugLogging: !kReleaseMode,
      eventPrefix: 'app_',
    );

    final crashlyticsConfig = CrashlyticsConfig(
      enableCollection: enableCrashlytics,
      enableDebugLogging: !kReleaseMode,
    );

    // Initialize Firebase Services with configs
    await FirebaseService.initialize(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      analyticsConfig: analyticsConfig,
      crashlyticsConfig: crashlyticsConfig,
      enableDebugLogging: !kReleaseMode,
    );

    // Set up error handlers for Firebase Crashlytics
    _setupCrashlyticsHandlers();

    debugPrint('✅ Firebase initialized');
    debugPrint('  Analytics: ${enableAnalytics ? 'enabled' : 'disabled'}');
    debugPrint('  Crashlytics: ${enableCrashlytics ? 'enabled' : 'disabled'}');
  } catch (e, stack) {
    debugPrint('❌ Error initializing Firebase: $e\n$stack');
    rethrow;
  }
}

/// Setup error handlers to report to Crashlytics
void _setupCrashlyticsHandlers() {
  final crashlytics = FirebaseService.crashlytics;

  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      crashlytics.recordFlutterFatalError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  // Handle PlatformDispatcher errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kReleaseMode) {
      crashlytics.recordError(error, stack, fatal: true);
    }
    debugPrint('Platform error: $error\n$stack');
    return true;
  };
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
    final analyticsService = AnalyticsService(
      firebaseAnalytics: FirebaseService.analytics,
    );

    // Update widget IMMEDIATELY on app start
    await widgetRepository.refreshWidget();

    // Log widget update to analytics
    await analyticsService.logWidgetInteraction(
      widgetName: 'home_screen_widget',
      actionType: 'updated_on_app_start',
    );

    // Schedule daily background updates at 12:01 AM
    await widgetRepository.scheduleWidgetUpdates();
    debugPrint('✅ Background updates scheduled');
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
