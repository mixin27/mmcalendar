import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:settings/settings.dart';
import 'package:shared_localizations/shared_localizations.dart';

/// Splash screen shown during app initialization
///
/// Displays app logo/branding while:
/// - Loading cached data
/// - Initializing services
/// - Checking app state
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isBlockedByRequiredUpdate = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Initialize app and navigate
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for minimum splash duration (for better UX)
      await Future.wait([
        Future.delayed(const Duration(seconds: 2)),
        _loadInitialData(),
      ]);

      if (_isBlockedByRequiredUpdate) {
        return;
      }

      // Navigate to home
      if (mounted) {
        // Check if consent dialog needs to be shown
        final settingsState = context.read<SettingsBloc>().state;

        if (settingsState is SettingsLoaded) {
          final hasShownConsent = settingsState.settings.hasShownConsentDialog;

          // Navigate based on consent status
          if (hasShownConsent) {
            context.go(RoutePaths.home);
          } else {
            context.go(RoutePaths.consent);
          }
        } else {
          // Fallback if settings not loaded yet
          context.go(RoutePaths.home);
        }
      }
    } catch (e) {
      // Handle initialization errors
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _loadInitialData() async {
    // Perform any necessary initialization here
    // Examples:
    // - Load cached settings
    // - Initialize Myanmar Calendar configuration
    // - Check for updates
    // - Preload commonly used data

    // For now, just a simple delay
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkRequiredUpdate();
  }

  Future<void> _checkRequiredUpdate() async {
    final updatePort = GetIt.I<AppUpdatePort>();
    final updateInfo = await updatePort.checkForUpdate();
    if (!mounted || !updateInfo.isRequired) {
      return;
    }

    _isBlockedByRequiredUpdate = true;
    await _showRequiredUpdateDialog(updatePort, updateInfo);
  }

  Future<void> _showRequiredUpdateDialog(
    AppUpdatePort updatePort,
    AppUpdateInfo initialInfo,
  ) async {
    var updateInfo = initialInfo;
    final l10n = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final details = <String>[updateInfo.message];
              final releaseNotes = updateInfo.releaseNotes?.trim() ?? '';
              if (releaseNotes.isNotEmpty) {
                details.add(releaseNotes);
              }

              return AlertDialog(
                title: Text(updateInfo.title),
                content: Text(details.join('\n\n')),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final refreshedInfo = await updatePort.checkForUpdate(
                        forceRefresh: true,
                      );
                      if (!dialogContext.mounted) return;

                      if (!refreshedInfo.isRequired) {
                        _isBlockedByRequiredUpdate = false;
                        Navigator.of(dialogContext).pop();
                        return;
                      }

                      setDialogState(() {
                        updateInfo = refreshedInfo;
                      });
                    },
                    child: Text(l10n?.checkAgain ?? 'Check Again'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final launched = await updatePort.launchUpdate(
                        updateInfo,
                      );
                      if (!mounted || launched) {
                        return;
                      }

                      _showStatusSnackBar(
                        l10n?.unableToOpenUpdatePage ??
                            'Unable to open the update page.',
                      );
                    },
                    child: Text(l10n?.updateNow ?? 'Update Now'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showErrorDialog(String error) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n?.initializationErrorTitle ?? 'Initialization Error'),
        content: Text(
          l10n?.failedToInitializeApp(error) ??
              'Failed to initialize the app:\n\n$error',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry
            },
            child: Text(l10n?.retry ?? 'Retry'),
          ),
        ],
      ),
    );
  }

  void _showStatusSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = MyanmarCalendar.today();

    final settingsState = context.read<SettingsBloc>().state;
    final isShowShanCalendar =
        (settingsState is SettingsLoaded &&
        settingsState.settings.showShanCalendar &&
        MyanmarCalendar.currentLanguage == Language.shan);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // App Logo/Icon with Animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: SvgPicture.asset(
                        'assets/logo.svg',
                        semanticsLabel: "Myanmar Calendar Logo",
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // App Name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Today's Date
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    isShowShanCalendar
                        ? "${today.shanDate.year} ${today.formatMyanmar("&M")}"
                        : today.formatMyanmar(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Loading Indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Loading Text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    AppLocalizations.of(context)?.loading ?? 'Loading...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Version/Copyright
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      AppLocalizations.of(
                            context,
                          )?.versionLabel(AppConstants.appVersion) ??
                          'Version ${AppConstants.appVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppWithWidgetHandler extends StatefulWidget {
  final Widget child;

  const AppWithWidgetHandler({super.key, required this.child});

  @override
  State<AppWithWidgetHandler> createState() => _AppWithWidgetHandlerState();
}

class _AppWithWidgetHandlerState extends State<AppWithWidgetHandler>
    with WidgetsBindingObserver {
  late WidgetClickHandler _widgetClickHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize handler
    _widgetClickHandler = WidgetClickHandler(
      analyticsService: GetIt.I<AnalyticsPort>(),
    );

    // Check on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widgetClickHandler.checkWidgetLaunch(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _widgetClickHandler.checkWidgetLaunch(context);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
