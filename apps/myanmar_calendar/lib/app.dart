import 'dart:developer';

import 'package:converter/converter.dart';
import 'package:calendar/calendar.dart';
import 'package:calendar_studio/calendar_studio.dart'
    show CalendarStudioFontCatalog;
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';
import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart'
    show MyanmarCalendar;
import 'package:shared_localizations/shared_localizations.dart';
import 'package:promo/promo.dart';
import 'package:settings/settings.dart';
import 'package:views/views.dart';

import 'config/di_setup.dart';
import 'config/router.dart';

class MyanmarCalendarApp extends StatelessWidget {
  const MyanmarCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Calendar feature
        BlocProvider(
          create: (context) =>
              getIt<CalendarBloc>()..add(LoadCalendarMonth(DateTime.now())),
        ),

        // Settings feature
        BlocProvider(
          create: (context) => getIt<SettingsBloc>()..add(const LoadSettings()),
        ),

        // Views feature
        BlocProvider(create: (context) => getIt<ViewsBloc>()),

        // Converter feature
        BlocProvider(create: (context) => getIt<ConverterBloc>()),

        // Events feature
        BlocProvider(
          create: (context) =>
              getIt<UserEventsBloc>()..add(const LoadAllEvents()),
        ),
        BlocProvider(
          create: (context) =>
              getIt<EventCategoriesBloc>()..add(const LoadEventCategories()),
        ),
      ],
      child: _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  @override
  void initState() {
    super.initState();
    // Request notification permissions
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    final notificationService = getIt<NotificationService>();
    await notificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listenWhen: (prev, curr) {
        if (curr is! SettingsLoaded) {
          return false;
        }
        if (prev is! SettingsLoaded) {
          return true;
        }
        return prev.settings.calendarLanguage !=
                curr.settings.calendarLanguage ||
            prev.settings.calendarConfig != curr.settings.calendarConfig;
      },
      listener: (context, state) {
        if (state is! SettingsLoaded) {
          return;
        }
        _syncMyanmarCalendarRuntime(state.settings);
      },
      buildWhen: (prev, curr) {
        if (prev is SettingsLoaded && curr is SettingsLoaded) {
          return prev.settings.themeMode != curr.settings.themeMode ||
              prev.settings.appStyle != curr.settings.appStyle ||
              prev.settings.customColors != curr.settings.customColors ||
              prev.settings.themePreset != curr.settings.themePreset ||
              prev.settings.appLanguage != curr.settings.appLanguage ||
              prev.settings.calendarLanguage !=
                  curr.settings.calendarLanguage ||
              prev.settings.calendarConfig != curr.settings.calendarConfig;
        }
        return true;
      },
      builder: (context, settingsState) {
        // Get theme mode from settings
        ThemeMode themeMode = ThemeMode.system;
        if (settingsState is SettingsLoaded) {
          log(settingsState.settings.themeMode.toString());
          themeMode = settingsState.settings.themeMode;
        }

        final settings = settingsState is SettingsLoaded
            ? settingsState.settings
            : null;
        // Light and dark are resolved separately so "System" follows the
        // device in both directions.
        final schemes = ThemePresets.schemesFor(
          settings?.themePreset ?? 'modern',
          custom: settings?.customColors,
        );
        final appStyle = settings?.appStyle ?? AppStyle.automatic;

        // Sync with Telegram theme if available
        // final telegramBgColor = getIt<TelegramService>()
        //     .getThemeBackgroundColor();
        // final telegramColor = Color(
        //   int.parse(telegramBgColor.replaceFirst('#', '0xff')),
        // );

        final lightTheme = AppTheme.build(
          style: appStyle,
          colorScheme: schemes.light,
        );
        final darkTheme = AppTheme.build(
          style: appStyle,
          colorScheme: schemes.dark,
        );

        final locale = settingsState is SettingsLoaded
            ? Locale(settingsState.settings.appLanguage)
            : Locale('en');

        // No key tied to the theme: changing style, mode or colours
        // restyles in place and keeps every tab's navigation stack.
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          localizationsDelegates: [
            PromoLocalizationsDelegate(),
            ...AppLocalizations.localizationsDelegates,
            // pro_image_editor (Calendar Studio "Edit image") is built on
            // material_ui, which needs its own localizations.
            ...material_ui.GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final width = mediaQuery.size.width;
            final maxTextScale = width < 360 ? 1.15 : 1.3;
            final content = MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  maxScaleFactor: maxTextScale,
                ),
              ),
              // Calendar data follows the calendar language; the interface
              // follows [locale].
              child: CalendarLanguageScope(
                language:
                    settings?.calendarLanguage ??
                    MyanmarCalendar.currentLanguage,
                // Grid themes draw numbers in Studio's bundled typefaces.
                child: CalendarFontScope(
                  resolve: _calendarFont,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
            return _AppStartupGuard(child: content);
          },
          routerConfig: router,
        );
      },
    );
  }

  void _syncMyanmarCalendarRuntime(AppSettingsEntity settings) {
    final config = settings.calendarConfig;
    final holidayOverridesPort = getIt<HolidayOverridesPort>();
    applyMyanmarCalendarRuntimeConfig(
      baseConfig: config,
      language: settings.calendarLanguage,
      useDeviceTimezone: settings.useDeviceTimezone,
      customHolidayRules: holidayOverridesPort.getCustomHolidayRules(),
      disabledHolidays: holidayOverridesPort.getDisabledHolidays(),
      disabledHolidaysByYear: holidayOverridesPort.getDisabledHolidaysByYear(),
      disabledHolidaysByDate: holidayOverridesPort.getDisabledHolidaysByDate(),
      cacheProfile: MyanmarCalendarCacheProfile.highPerformance,
    );
  }
}

class _AppStartupGuard extends StatefulWidget {
  final Widget child;

  const _AppStartupGuard({required this.child});

  @override
  State<_AppStartupGuard> createState() => _AppStartupGuardState();
}

class _AppStartupGuardState extends State<_AppStartupGuard> {
  bool _didStartUpdateCheck = false;
  bool _updateCheckCompleted = false;
  bool _requiredUpdateDialogOpen = false;
  bool _routedToConsent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartUpdateCheck) return;
    _didStartUpdateCheck = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRequiredUpdate();
    });
  }

  Future<void> _checkRequiredUpdate() async {
    final updatePort = getIt<AppUpdatePort>();
    final updateInfo = await updatePort.checkForUpdate();

    if (!mounted) return;

    if (updateInfo.isRequired) {
      _requiredUpdateDialogOpen = true;
      await _showRequiredUpdateDialog(updatePort, updateInfo);
      _requiredUpdateDialogOpen = false;
    }

    _updateCheckCompleted = true;
    _maybeRouteToConsent();
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
                      if (!dialogContext.mounted || launched) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n?.unableToOpenUpdatePage ??
                                'Unable to open the update page.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
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

  void _maybeRouteToConsent() {
    if (!mounted || !_updateCheckCompleted || _requiredUpdateDialogOpen) {
      return;
    }

    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState is! SettingsLoaded) return;
    if (settingsState.settings.hasShownConsentDialog) return;
    if (_routedToConsent) return;

    final currentPath = router.routeInformationProvider.value.uri.path;
    if (currentPath == RoutePaths.consent) return;

    _routedToConsent = true;
    router.go(RoutePaths.consent);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (_, state) => state is SettingsLoaded,
      listener: (context, _) => _maybeRouteToConsent(),
      child: widget.child,
    );
  }
}

TextStyle _calendarFont(String family, FontWeight weight) =>
    CalendarStudioFontCatalog.style(family: family, weight: weight);
