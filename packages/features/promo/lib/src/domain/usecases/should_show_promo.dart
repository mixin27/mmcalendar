import '../entities/promo_campaign.dart';
import '../repositories/promo_repository.dart';

/// Use case to determine if a promo should be shown
class ShouldShowPromo {
  final PromoRepository repository;

  const ShouldShowPromo(this.repository);

  /// Execute the use case
  /// Returns true if the promo should be shown based on campaign rules
  Future<bool> call(PromoCampaign campaign, String currentVersion) async {
    // Check if campaign should only be shown once
    if (campaign.showOnce) {
      final hasSeenCampaign = await repository.hasSeenCampaign(campaign.id);
      if (hasSeenCampaign) {
        return false;
      }
    }

    // Check version constraints
    if (campaign.minAppVersion != null) {
      if (_compareVersions(currentVersion, campaign.minAppVersion!) < 0) {
        return false;
      }
    }

    if (campaign.maxAppVersion != null) {
      if (_compareVersions(currentVersion, campaign.maxAppVersion!) > 0) {
        return false;
      }
    }

    // Check date constraints
    final now = DateTime.now();

    if (campaign.showAfterDate != null) {
      if (now.isBefore(campaign.showAfterDate!)) {
        return false;
      }
    }

    if (campaign.showBeforeDate != null) {
      if (now.isAfter(campaign.showBeforeDate!)) {
        return false;
      }
    }

    return true;
  }

  /// Compare two semantic version strings
  /// Returns -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }
}
