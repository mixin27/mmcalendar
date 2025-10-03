import 'package:calendar/calendar.dart';
import 'package:converter/converter.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:settings/settings.dart';
import 'package:views/views.dart';

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

    // Main App Shell with Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home (Calendar)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const CalendarHomePage(),
              routes: [
                // Day details
                GoRoute(
                  path: RoutePaths.dayDetails,
                  builder: (context, state) {
                    final date = state.extra as DateTime;
                    context.read<ViewsBloc>().add(LoadDayView(date));
                    return DayViewPage(date: date);
                  },
                ),
              ],
            ),
          ],
        ),

        // Branch 1: Views (Placeholder for now)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.views,
              builder: (context, state) => const ViewsSelectorPage(),
            ),
          ],
        ),

        // Branch 2: Converter (Placeholder for now)
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

        // Branch 3: Settings (Placeholder for now)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.settings,
              builder: (context, state) => const SettingsPage(),
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
