import 'package:flutter/foundation.dart';

class EventCreationDiagnostic {
  static int _createCallCount = 0;
  static int _insertCallCount = 0;
  static final List<String> _creationLog = [];

  /// Call this at the START of createEvent() in EventFormBloc
  static void logBlocCreateStart(String eventTitle) {
    _createCallCount++;
    final message = '[$_createCallCount] BLoC: Creating event "$eventTitle"';
    _creationLog.add(message);
    debugPrint('🔵 $message');
  }

  /// Call this at the START of createEvent() in Repository
  static void logRepositoryCreateStart(String eventTitle) {
    final message = '  → Repository: Creating event "$eventTitle"';
    _creationLog.add(message);
    debugPrint('🟢 $message');
  }

  /// Call this at the START of createEvent() in LocalDataSource
  static void logDatasourceCreateStart(String eventTitle) {
    final message = '    → DataSource: Creating event "$eventTitle"';
    _creationLog.add(message);
    debugPrint('🟡 $message');
  }

  /// Call this at the START of DAO insert
  static void logDaoInsertStart(String eventTitle) {
    _insertCallCount++;
    final message =
        '      → DAO: INSERT #$_insertCallCount into database for "$eventTitle"';
    _creationLog.add(message);
    debugPrint('🔴 $message');
  }

  /// Call this to check results
  static void printDiagnosticReport() {
    debugPrint('\n${'=' * 60}');
    debugPrint('EVENT CREATION DIAGNOSTIC REPORT');
    debugPrint('=' * 60);
    debugPrint('Total BLoC create calls: $_createCallCount');
    debugPrint('Total Database inserts: $_insertCallCount');
    debugPrint('');

    if (_insertCallCount == _createCallCount) {
      debugPrint('✅ CORRECT: 1 BLoC call = 1 Database insert');
    } else if (_insertCallCount > _createCallCount) {
      debugPrint(
        '❌ PROBLEM: $_createCallCount BLoC calls resulted in $_insertCallCount database inserts!',
      );
      debugPrint(
        '   This means multiple rows are being created for one event.',
      );
      debugPrint('   Check your DataSource or DAO code.');
    } else {
      debugPrint('⚠️  UNUSUAL: More BLoC calls than inserts');
    }

    debugPrint('\nFull Log:');
    for (final log in _creationLog) {
      debugPrint(log);
    }
    debugPrint('=' * 60 + '\n');
  }

  /// Reset counters
  static void reset() {
    _createCallCount = 0;
    _insertCallCount = 0;
    _creationLog.clear();
  }
}
