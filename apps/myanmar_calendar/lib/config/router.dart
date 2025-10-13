import 'package:calendar/calendar.dart';
import 'package:converter/converter.dart';
import 'package:core/core.dart';
import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:settings/settings.dart';
import 'package:views/views.dart';

import '../presentation/pages/privacy_policy_page.dart';
import '../presentation/pages/splash_page.dart';
import '../presentation/shell/app_shell.dart';
import 'analytics_navigator_observer.dart';
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

    // Main App Shell with Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Home (Calendar)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) {
                return const CalendarHomePage();
              },
              routes: [
                // Day details
                GoRoute(
                  path: RoutePaths.dayDetails,
                  builder: (context, state) {
                    final data = state.extra as Map<String, dynamic>;
                    final date = data["date"] as DateTime;
                    final events = data["events"] as List<Event>;
                    // context.read<ViewsBloc>().add(LoadDayView(date));
                    return DayDetailsPage(date: date, events: events);
                  },
                ),
              ],
            ),
          ],
        ),

        // Views
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

        // Converter
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.converter,
              builder: (context, state) => BlocProvider(
                create: (context) => getIt<ConverterBloc>(),
                child: const ConverterPage(),
              ),
            ),
          ],
        ),

        // Events shell
        // StatefulShellBranch(
        //   routes: [
        //     GoRoute(
        //       path: '/events',
        //       builder: (context, state) => BlocProvider(
        //         create: (context) => getIt<EventsBloc>(),
        //         child: const EventsListPage(),
        //       ),
        //       routes: [
        //         GoRoute(
        //           path: 'create',
        //           builder: (context, state) => BlocProvider.value(
        //             value: context.read<EventsBloc>(),
        //             child: const EventFormPage(),
        //           ),
        //         ),
        //         GoRoute(
        //           path: 'categories',
        //           builder: (context, state) => BlocProvider.value(
        //             value: context.read<EventsBloc>(),
        //             child: const CategoriesPage(),
        //           ),
        //         ),
        //         GoRoute(
        //           path: ':id',
        //           builder: (context, state) {
        //             final id = int.parse(state.pathParameters['id']!);
        //             return BlocProvider.value(
        //               value: context.read<EventsBloc>(),
        //               child: EventFormPage(eventId: id),
        //             );
        //           },
        //         ),
        //         GoRoute(
        //           path: ':id/detail',
        //           builder: (context, state) {
        //             final id = int.parse(state.pathParameters['id']!);
        //             return BlocProvider.value(
        //               value: context.read<EventsBloc>(),
        //               child: EventDetailPage(eventId: id),
        //             );
        //           },
        //         ),
        //       ],
        //     ),
        //   ],
        // ),

        // Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.settings,
              builder: (context, state) => const SettingsPage(),
              routes: [
                GoRoute(
                  path: RoutePaths.widgets,
                  builder: (context, state) => BlocProvider(
                    create: (context) =>
                        getIt<WidgetBloc>()..add(const LoadWidgetConfig()),
                    child: const WidgetSettingsPage(),
                  ),
                ),
                GoRoute(
                  path: RoutePaths.privacyPolicy,
                  builder: (context, state) => const PrivacyPolicyPage(
                    title: "Privacy policy",
                    message: "App privacy & policy contents will be here.",
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
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(state.error.toString()),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(RoutePaths.home),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  ),
  observers: [AnalyticsNavigatorObserver()],
);
