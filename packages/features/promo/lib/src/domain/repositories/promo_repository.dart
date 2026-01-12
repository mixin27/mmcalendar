import '../entities/promo_interaction.dart';

/// Repository interface for promo data management
abstract class PromoRepository {
  /// Check if a campaign has been seen by the user
  Future<bool> hasSeenCampaign(String campaignId);

  /// Mark a campaign as seen
  Future<void> markCampaignAsSeen(String campaignId);

  /// Track a user interaction with a promo
  Future<void> trackInteraction(PromoInteraction interaction);

  /// Get the last app version the user saw
  Future<String?> getLastSeenVersion();

  /// Set the last app version the user saw
  Future<void> setLastSeenVersion(String version);

  /// Get all interactions for a specific campaign
  Future<List<PromoInteraction>> getInteractionsForCampaign(String campaignId);

  /// Clear all promo data (for testing or reset)
  Future<void> clearAllData();
}
