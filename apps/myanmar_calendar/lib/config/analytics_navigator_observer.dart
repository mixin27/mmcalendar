import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreenView(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logScreenView(newRoute);
  }

  void _logScreenView(Route<dynamic>? route) {
    if (route?.settings.name == null) {
      return;
    }
    if (kReleaseMode) {
      FirebaseAnalytics.instance.logEvent(
        name: 'screen_view',
        parameters: {'screen_name': route!.settings.name ?? "UnknownScreen"},
      );
    }
    debugPrint('Screen viewed: ${route?.settings.name}');
  }
}
