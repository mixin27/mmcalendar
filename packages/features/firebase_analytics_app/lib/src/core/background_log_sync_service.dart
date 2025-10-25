import 'package:firebase_analytics_app/firebase_analytics_app.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to sync background task logs to Firebase
/// Call this when the main app starts
class BackgroundLogSyncService {
  final AnalyticsService analyticsService;
  final CrashlyticsService crashlyticsService;
  final SharedPreferences prefs;

  BackgroundLogSyncService({
    required this.analyticsService,
    required this.crashlyticsService,
    required this.prefs,
  });

  /// Sync all pending background logs to Firebase
  /// Call this in your app initialization
  Future<void> syncLogsToFirebase() async {
    try {
      debugPrint('🔄 Starting background log sync...');

      await _syncSuccessLogs();
      await _syncErrorLogs();
      await _clearOldLogs();

      debugPrint('✅ Background logs synced to Firebase');
    } catch (e, stackTrace) {
      debugPrint('⚠️ Failed to sync background logs: $e');
      await crashlyticsService.recordException(
        exception: e,
        stackTrace: stackTrace,
        reason: 'Failed to sync background logs',
      );
    }
  }

  /// Sync success logs to Firebase Analytics using custom events
  Future<void> _syncSuccessLogs() async {
    final logs = prefs.getStringList('background_logs') ?? [];

    if (logs.isEmpty) {
      debugPrint('  No success logs to sync');
      return;
    }

    debugPrint('  Syncing ${logs.length} success logs...');

    for (final log in logs) {
      try {
        final parts = log.split('|');
        if (parts.length >= 3 && parts[0] == 'SUCCESS') {
          // Use WidgetInteractionEvent for background updates
          await analyticsService.logWidgetInteraction(
            widgetName: 'home_screen_widget',
            actionType: 'background_update',
            metadata: {
              'task_name': parts[1],
              'timestamp': parts[2],
              'duration': parts.length > 3 ? parts[3] : 'unknown',
              'status': 'success',
            },
          );
        }
      } catch (e) {
        debugPrint('    ⚠️ Failed to sync success log: $e');
      }
    }

    // Log aggregate metrics
    final successCount = prefs.getInt('background_success_count') ?? 0;
    final lastUpdate = prefs.getString('last_background_update');
    final lastDuration = prefs.getInt('last_background_duration_ms');

    if (successCount > 0) {
      // Log background metrics (add this method to AnalyticsService)
      await analyticsService.logBackgroundMetrics(
        successCount: successCount,
        lastUpdate: lastUpdate ?? 'never',
        lastDurationMs: lastDuration ?? 0,
        healthStatus: isBackgroundHealthy() ? 'healthy' : 'unhealthy',
      );

      debugPrint('  ✅ Synced $successCount background successes');
    }
  }

  /// Sync error logs to Firebase Crashlytics
  Future<void> _syncErrorLogs() async {
    final errorLogs = prefs.getStringList('background_error_logs') ?? [];

    if (errorLogs.isEmpty) {
      debugPrint('  No error logs to sync');
      return;
    }

    debugPrint('  Syncing ${errorLogs.length} error logs...');

    for (final log in errorLogs) {
      try {
        final parts = log.split('|');
        if (parts.length >= 4 && parts[0] == 'ERROR') {
          final task = parts[1];
          final timestamp = parts[2];
          final errorMsg = parts[3];
          final duration = parts.length > 4 ? parts[4] : 'unknown';

          // Record non-fatal error to Crashlytics
          await crashlyticsService.recordException(
            exception: Exception('Background task error: $errorMsg'),
            stackTrace: StackTrace.current,
            reason: 'Background task: $task at $timestamp (took $duration)',
            fatal: false,
          );

          // Also log to analytics
          await analyticsService.logException(
            exceptionName: 'background_task_error',
            description: errorMsg,
            stackTrace: 'Task: $task, Time: $timestamp, Duration: $duration',
          );
        }
      } catch (e) {
        debugPrint('    ⚠️ Failed to sync error log: $e');
      }
    }

    // Log aggregate error metrics
    final errorCount = prefs.getInt('background_error_count') ?? 0;
    final lastError = prefs.getString('last_background_error');
    final lastErrorTime = prefs.getString('last_background_error_time');

    if (errorCount > 0) {
      // Log background error metrics
      await analyticsService.logBackgroundErrors(
        errorCount: errorCount,
        lastError: lastError ?? 'none',
        lastErrorTime: lastErrorTime ?? 'never',
      );

      debugPrint('  ⚠️ Synced $errorCount background errors');
    }
  }

  /// Clear old logs after successful sync
  Future<void> _clearOldLogs() async {
    // Clear synced logs (keep only recent ones)
    await prefs.setStringList('background_logs', []);
    await prefs.setStringList('background_error_logs', []);

    // Keep counters and last update info for reference
    debugPrint('  🧹 Old background logs cleared');
  }

  /// Get background task statistics
  Map<String, dynamic> getBackgroundStats() {
    return {
      'success_count': prefs.getInt('background_success_count') ?? 0,
      'error_count': prefs.getInt('background_error_count') ?? 0,
      'last_update': prefs.getString('last_background_update'),
      'last_task': prefs.getString('last_background_task'),
      'last_duration_ms': prefs.getInt('last_background_duration_ms'),
      'last_error': prefs.getString('last_background_error'),
      'last_error_time': prefs.getString('last_background_error_time'),
      'pending_logs': (prefs.getStringList('background_logs') ?? []).length,
      'pending_errors':
          (prefs.getStringList('background_error_logs') ?? []).length,
    };
  }

  /// Check if background updates are working
  bool isBackgroundHealthy() {
    final stats = getBackgroundStats();
    final lastUpdate = stats['last_update'] as String?;

    if (lastUpdate == null) return false;

    final lastUpdateTime = DateTime.tryParse(lastUpdate);
    if (lastUpdateTime == null) return false;

    // Consider healthy if updated within last 25 hours
    final hoursSinceUpdate = DateTime.now().difference(lastUpdateTime).inHours;
    return hoursSinceUpdate < 25;
  }

  /// Get health status message
  String getHealthStatusMessage() {
    if (isBackgroundHealthy()) {
      final lastUpdate = prefs.getString('last_background_update');
      final duration = prefs.getInt('last_background_duration_ms') ?? 0;
      return '✅ Working (${duration}ms, updated ${_formatTimestamp(lastUpdate)})';
    } else {
      final errorCount = prefs.getInt('background_error_count') ?? 0;
      if (errorCount > 0) {
        return '⚠️ Issues detected ($errorCount errors)';
      }
      return '❌ Not working (no recent updates)';
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'never';

    final dateTime = DateTime.tryParse(timestamp);
    if (dateTime == null) return 'never';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Reset all background statistics
  Future<void> resetStats() async {
    await prefs.remove('background_success_count');
    await prefs.remove('background_error_count');
    await prefs.remove('last_background_update');
    await prefs.remove('last_background_task');
    await prefs.remove('last_background_duration_ms');
    await prefs.remove('last_background_error');
    await prefs.remove('last_background_error_stack');
    await prefs.remove('last_background_error_time');
    await prefs.setStringList('background_logs', []);
    await prefs.setStringList('background_error_logs', []);

    debugPrint('🧹 Background statistics reset');
  }
}
