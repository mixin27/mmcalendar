import 'package:integrations_firebase/integrations_firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to handle widget interactions and track analytics
class WidgetClickHandler {
  final AnalyticsService analyticsService;

  WidgetClickHandler({required this.analyticsService});

  /// Check if app was opened from widget and handle accordingly
  Future<void> checkWidgetLaunch(BuildContext context) async {
    try {
      // Get launch intent extras (Android)
      final intent = await _getIntentExtras();

      if (intent != null) {
        final openedFromWidget = intent['opened_from_widget'] as bool?;
        final widgetId = intent['widget_id'] as int?;
        final timestamp = intent['timestamp'] as int?;
        final action = intent['action'] as String?;

        if (openedFromWidget == true) {
          debugPrint('📱 App opened from widget!');
          debugPrint('  Widget ID: $widgetId');
          debugPrint('  Timestamp: $timestamp');
          debugPrint('  Action: $action');

          // Log to analytics
          await analyticsService.logWidgetInteraction(
            widgetName: 'home_screen_widget',
            actionType: 'widget_clicked',
            metadata: {
              'widget_id': widgetId?.toString() ?? 'unknown',
              'timestamp':
                  timestamp?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              'action': action ?? 'view_today',
            },
          );

          // Handle specific actions if needed
          if (action != null && context.mounted) {
            _handleWidgetAction(context, action);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error checking widget launch: $e');
    }
  }

  /// Get Android intent extras
  Future<Map<String, dynamic>?> _getIntentExtras() async {
    try {
      const platform = MethodChannel('dev.mixin27.mmcalendar/intent');
      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'getIntentExtras',
      );

      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      debugPrint('Could not get intent extras: $e');
    }
    return null;
  }

  /// Handle specific widget actions
  void _handleWidgetAction(BuildContext context, String action) {
    switch (action) {
      case 'view_today':
        // Navigate to today's date (already default behavior)
        debugPrint('📅 Viewing today\'s date');
        break;
      case 'view_astrology':
        // Navigate to astrology page
        debugPrint('⭐ Viewing astrology');
        // Navigator.pushNamed(context, '/astrology');
        break;
      case 'view_holidays':
        // Navigate to holidays page
        debugPrint('🎉 Viewing holidays');
        // Navigator.pushNamed(context, '/holidays');
        break;
      default:
        debugPrint('Unknown action: $action');
    }
  }
}
