import 'package:equatable/equatable.dart';

/// Represents a promotional campaign
class PromoCampaign extends Equatable {
  /// Unique identifier for the campaign
  final String id;

  /// Type of campaign
  final PromoCampaignType type;

  /// Minimum app version required to show this campaign
  final String? minAppVersion;

  /// Maximum app version allowed to show this campaign
  final String? maxAppVersion;

  /// Whether this campaign should only be shown once
  final bool showOnce;

  /// Date after which this campaign should be shown
  final DateTime? showAfterDate;

  /// Date before which this campaign should be shown
  final DateTime? showBeforeDate;

  /// Custom metadata for the campaign
  final Map<String, dynamic>? metadata;

  const PromoCampaign({
    required this.id,
    required this.type,
    this.minAppVersion,
    this.maxAppVersion,
    this.showOnce = true,
    this.showAfterDate,
    this.showBeforeDate,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    minAppVersion,
    maxAppVersion,
    showOnce,
    showAfterDate,
    showBeforeDate,
    metadata,
  ];
}

/// Types of promotional campaigns
enum PromoCampaignType {
  /// First-time user onboarding
  onboarding,

  /// Feature announcement for new versions
  featureAnnouncement,

  /// Contextual promotion based on user behavior
  contextual,

  /// General promotional content
  general,
}
