import 'package:equatable/equatable.dart';

/// Represents a user interaction with a promotional campaign
class PromoInteraction extends Equatable {
  /// Campaign ID that was interacted with
  final String campaignId;

  /// Timestamp of the interaction
  final DateTime timestamp;

  /// Type of interaction
  final PromoInteractionType type;

  /// Slide ID if interaction was with a specific slide
  final String? slideId;

  /// Additional metadata about the interaction
  final Map<String, dynamic>? metadata;

  const PromoInteraction({
    required this.campaignId,
    required this.timestamp,
    required this.type,
    this.slideId,
    this.metadata,
  });

  @override
  List<Object?> get props => [campaignId, timestamp, type, slideId, metadata];

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'campaignId': campaignId,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'slideId': slideId,
    'metadata': metadata,
  };

  /// Create from JSON
  factory PromoInteraction.fromJson(Map<String, dynamic> json) {
    return PromoInteraction(
      campaignId: json['campaignId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: PromoInteractionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      slideId: json['slideId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Types of promo interactions
enum PromoInteractionType {
  /// User viewed the promo
  viewed,

  /// User dismissed the promo
  dismissed,

  /// User completed the promo (went through all slides)
  completed,

  /// User clicked a CTA button
  ctaClicked,

  /// User skipped the promo
  skipped,
}
