import 'package:shared_preferences/shared_preferences.dart';

import 'whats_new_content.dart';

/// A feature to announce, with the version that added it.
class PendingWhatsNew {
  const PendingWhatsNew(this.version, this.item);

  final String version;
  final WhatsNewItem item;
}

/// Remembers the last version whose features the user has seen, and works
/// out what to announce after an update.
class WhatsNewStore {
  WhatsNewStore(
    this._prefs, {
    required this.currentVersion,
    this.releases = whatsNewReleases,
  });

  static const lastSeenKey = 'whats_new_last_seen';

  /// Where the old promo carousel kept the same thing.
  static const legacyKey = 'promo_last_version';

  final SharedPreferences _prefs;
  final String currentVersion;
  final List<WhatsNewRelease> releases;

  String? get lastSeen =>
      _prefs.getString(lastSeenKey) ?? _prefs.getString(legacyKey);

  /// Features added after [lastSeen] up to [currentVersion], newest first.
  /// Empty when nothing was seen yet: a new install is introduced by
  /// onboarding instead (see [markSeen]).
  List<PendingWhatsNew> pending() {
    final seen = lastSeen;
    if (seen == null) return const [];
    return [
      for (final r in releases)
        if (compareVersions(r.version, seen) > 0 &&
            compareVersions(r.version, currentVersion) <= 0)
          for (final item in r.items) PendingWhatsNew(r.version, item),
    ];
  }

  /// Releases up to [currentVersion], newest first, for the history page.
  List<WhatsNewRelease> history() => [
    for (final r in releases)
      if (compareVersions(r.version, currentVersion) <= 0) r,
  ];

  Future<void> markSeen() => _prefs.setString(lastSeenKey, currentVersion);

  /// Forgets what was seen (debug "show again").
  Future<void> reset(String version) => _prefs.setString(lastSeenKey, version);

  /// Compares dotted versions ("2.2.10" > "2.2.9"); build numbers after
  /// "+" are ignored.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) =>
        v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < 3; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d.sign;
    }
    return 0;
  }
}
