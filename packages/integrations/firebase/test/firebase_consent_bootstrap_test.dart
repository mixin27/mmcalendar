import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:integrations_firebase/integrations_firebase.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('analytics and crash reports stay off until the user agrees', () async {
    final consent = await const FirebaseConsentBootstrap().loadConsent(
      database: database,
    );
    expect(consent.enableAnalytics, isFalse);
    expect(consent.enableCrashlytics, isFalse);
  });

  test('a saved choice is kept', () async {
    await database.settingsDao.setSetting('enable_analytics', 'true');
    await database.settingsDao.setSetting('enable_crashlytics', 'false');
    final consent = await const FirebaseConsentBootstrap().loadConsent(
      database: database,
    );
    expect(consent.enableAnalytics, isTrue);
    expect(consent.enableCrashlytics, isFalse);
  });
}
