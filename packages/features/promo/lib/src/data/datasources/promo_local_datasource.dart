import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/promo_interaction.dart';

/// Local data source for promo data using SharedPreferences
class PromoLocalDataSource {
  final SharedPreferences prefs;

  static const String _seenCampaignsKey = 'promo_seen_campaigns';
  static const String _lastVersionKey = 'promo_last_version';
  static const String _interactionsKey = 'promo_interactions';

  const PromoLocalDataSource(this.prefs);

  /// Check if a campaign has been seen
  Future<bool> hasSeenCampaign(String campaignId) async {
    final seenCampaigns = _getSeenCampaigns();
    return seenCampaigns.contains(campaignId);
  }

  /// Mark a campaign as seen
  Future<void> markCampaignAsSeen(String campaignId) async {
    final seenCampaigns = _getSeenCampaigns();
    if (!seenCampaigns.contains(campaignId)) {
      seenCampaigns.add(campaignId);
      await prefs.setStringList(_seenCampaignsKey, seenCampaigns);
    }
  }

  /// Get list of seen campaign IDs
  List<String> _getSeenCampaigns() {
    return prefs.getStringList(_seenCampaignsKey) ?? [];
  }

  /// Track a promo interaction
  Future<void> trackInteraction(PromoInteraction interaction) async {
    final interactions = await getInteractions();

    // Add new interaction
    interactions.add(interaction);

    // Keep only last 30 days of interactions
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final recentInteractions = interactions
        .where((i) => i.timestamp.isAfter(cutoffDate))
        .toList();

    // Save to preferences
    final jsonList = recentInteractions.map((i) => i.toJson()).toList();
    await prefs.setString(_interactionsKey, jsonEncode(jsonList));
  }

  /// Get all interactions
  Future<List<PromoInteraction>> getInteractions() async {
    final jsonString = prefs.getString(_interactionsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map(
            (json) => PromoInteraction.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  /// Get interactions for a specific campaign
  Future<List<PromoInteraction>> getInteractionsForCampaign(
    String campaignId,
  ) async {
    final allInteractions = await getInteractions();
    return allInteractions.where((i) => i.campaignId == campaignId).toList();
  }

  /// Get the last app version the user saw
  Future<String?> getLastSeenVersion() async {
    return prefs.getString(_lastVersionKey);
  }

  /// Set the last app version the user saw
  Future<void> setLastSeenVersion(String version) async {
    await prefs.setString(_lastVersionKey, version);
  }

  /// Clear all promo data
  Future<void> clearAllData() async {
    await Future.wait([
      prefs.remove(_seenCampaignsKey),
      prefs.remove(_lastVersionKey),
      prefs.remove(_interactionsKey),
    ]);
  }
}
