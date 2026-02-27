import 'package:calendar/calendar.dart';
import 'package:converter/converter.dart';
import 'package:shared_core/shared_core.dart';
import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:mmcalendar/src/build_number.dart';
import 'package:settings/settings.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:views/views.dart';

import '../presentation/pages/consent_page.dart';
import '../presentation/pages/privacy_policy_page.dart';
import '../presentation/pages/splash_page.dart';
import '../presentation/shell/app_shell.dart';
import '../presentation/widgets/promo_initializer.dart';
import 'di_setup.dart';

final GoRouter router = GoRouter(
  initialLocation: RoutePaths.splash,
  debugLogDiagnostics: true,
  routes: [
    // Splash Screen
    GoRoute(
      path: RoutePaths.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: RoutePaths.consent,
      builder: (context, state) => const ConsentPage(),
    ),

    // Main App Shell with Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return PromoInitializer(
          child: AppShell(navigationShell: navigationShell),
        );
      },
      branches: [
        // =====================================================================
        // HOME (CALENDAR) BRANCH
        // =====================================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) {
                final dateStr = state.uri.queryParameters['date'];
                DateTime? initialDate;
                if (dateStr != null && dateStr.isNotEmpty) {
                  initialDate = DateTime.tryParse(dateStr);
                }

                return CalendarHomePage(initialDate: initialDate);
              },
              routes: [
                // Day details
                GoRoute(
                  path: RoutePaths.dayDetails,
                  builder: (context, state) {
                    final dateStr = state.uri.queryParameters['date'];
                    DateTime? date;
                    if (dateStr != null && dateStr.isNotEmpty) {
                      date = DateTime.tryParse(dateStr);
                    }

                    // If no date provided, default to today
                    date ??= DateTime.now();

                    return DayDetailsPage(date: date);
                  },
                ),
              ],
            ),
          ],
        ),

        // =====================================================================
        // VIEWS BRANCH
        // =====================================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.views,
              builder: (context, state) => const ViewsSelectorPage(),
              routes: [
                GoRoute(
                  path: RoutePaths.yearView,
                  builder: (context, state) => const YearViewPage(),
                ),
                GoRoute(
                  path: RoutePaths.weekView,
                  builder: (context, state) => const WeekViewPage(),
                ),
                GoRoute(
                  path: RoutePaths.dayView,
                  builder: (context, state) => const DayViewPage(),
                ),
              ],
            ),
          ],
        ),

        // =====================================================================
        // CONVERTER BRANCH
        // =====================================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.converter,
              builder: (context, state) => const ConverterPage(),
            ),
          ],
        ),

        // =====================================================================
        // EVENTS BRANCH
        // =====================================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.events,
              builder: (context, state) => const EventsListPage(),
              routes: [
                // Create new event
                GoRoute(
                  path: 'create',
                  builder: (context, state) {
                    final initialDate = state.extra as DateTime?;
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (context) => getIt<EventFormBloc>(),
                        ),
                        BlocProvider(
                          create: (context) =>
                              getIt<EventCategoriesBloc>()
                                ..add(const LoadEventCategories()),
                        ),
                      ],
                      child: EventFormPage(initialDate: initialDate),
                    );
                  },
                ),
                // Edit event
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (context) => getIt<EventFormBloc>(),
                        ),
                        BlocProvider(
                          create: (context) =>
                              getIt<EventCategoriesBloc>()
                                ..add(const LoadEventCategories()),
                        ),
                      ],
                      child: EventFormPage(eventId: id),
                    );
                  },
                ),

                // Event detail
                GoRoute(
                  path: ':id/detail',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    final occurrenceDate = state.extra is DateTime
                        ? state.extra as DateTime
                        : null;
                    return EventDetailPage(
                      eventId: id,
                      occurrenceDate: occurrenceDate,
                    );
                  },
                ),

                // Categories management
                GoRoute(
                  path: 'categories',
                  builder: (context, state) => BlocProvider(
                    create: (context) =>
                        getIt<EventCategoriesBloc>()
                          ..add(const LoadEventCategories()),
                    child: const CategoriesPage(),
                  ),
                ),
              ],
            ),
          ],
        ),

        // =====================================================================
        // SETTINGS BRANCH
        // =====================================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.settings,
              builder: (context, state) {
                return const SettingsPage();
              },
              routes: [
                GoRoute(
                  path: RoutePaths.themeSettings,
                  builder: (context, state) => const SettingsAppearancePage(),
                ),
                GoRoute(
                  path: RoutePaths.languageSettings,
                  builder: (context, state) => const SettingsLanguagePage(),
                ),
                GoRoute(
                  path: RoutePaths.displayPreferences,
                  builder: (context, state) =>
                      const SettingsDisplayPreferencesPage(),
                ),
                GoRoute(
                  path: RoutePaths.calendarConfig,
                  builder: (context, state) =>
                      const SettingsCalendarConfigurationPage(),
                ),
                GoRoute(
                  path: RoutePaths.privacyAndData,
                  builder: (context, state) => const SettingsPrivacyDataPage(),
                ),
                GoRoute(
                  path: RoutePaths.appUpdate,
                  builder: (context, state) {
                    final version = appVersion();
                    return SettingsAppUpdatePage(appVersion: version);
                  },
                ),
                GoRoute(
                  path: RoutePaths.about,
                  builder: (context, state) {
                    final version = appVersion();
                    return SettingsAboutPage(appVersion: version);
                  },
                  routes: [
                    GoRoute(
                      path: RoutePaths.privacyPolicy,
                      builder: (context, state) => PrivacyPolicyPage(
                        title:
                            AppLocalizations.of(context)?.privacyPolicy ??
                            'Privacy policy',
                        message:
                            AppLocalizations.of(
                              context,
                            )?.privacyPolicyContentHint ??
                            'App privacy & policy contents will be here.',
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: RoutePaths.widgets,
                  builder: (context, state) => BlocProvider(
                    create: (context) =>
                        getIt<WidgetBloc>()..add(const LoadWidgetConfig()),
                    child: const WidgetSettingsPage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],

  // Error handling
  errorBuilder: (context, state) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.errorTitle ?? 'Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n?.pageNotFound ?? 'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.error.toString(),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(RoutePaths.home),
                child: Text(l10n?.goToHome ?? 'Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
