import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this person has been through onboarding.
class OnboardingStore {
  OnboardingStore(this._prefs);

  final SharedPreferences _prefs;

  /// Where the old promo carousel recorded that onboarding was seen.
  static const _legacyCampaigns = 'promo_seen_campaigns';

  bool get completed =>
      _prefs.getBool(StorageKeys.onboardingCompleted) ?? false;

  Future<void> complete() =>
      _prefs.setBool(StorageKeys.onboardingCompleted, true);

  Future<void> reset() => _prefs.remove(StorageKeys.onboardingCompleted);

  /// Marks onboarding done for people who used the app before it existed:
  /// they made the consent choice, or saw the old carousel.
  Future<void> migrate({required bool madeConsentChoice}) async {
    if (completed) return;
    final sawCarousel =
        _prefs.getStringList(_legacyCampaigns)?.contains('onboarding_v1') ??
        false;
    if (madeConsentChoice || sawCarousel) await complete();
  }
}
