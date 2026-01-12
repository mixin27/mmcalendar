import 'package:core/core.dart';
import 'package:firebase_analytics_app/firebase_analytics_app.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:promo_carousel/promo_carousel.dart';

import '../../domain/entities/promo_interaction.dart';
import '../../domain/repositories/promo_repository.dart';
import '../../domain/usecases/get_feature_announcements.dart';
import '../../domain/usecases/get_onboarding_slides.dart';

/// High-level service for showing promos with analytics integration
class PromoService {
  final PromoRepository repository;
  final GetOnboardingSlides getOnboardingSlides;
  final GetFeatureAnnouncements getFeatureAnnouncements;
  final AnalyticsService? analyticsService;

  const PromoService({
    required this.repository,
    required this.getOnboardingSlides,
    required this.getFeatureAnnouncements,
    this.analyticsService,
  });

  /// Show onboarding carousel if needed
  Future<void> showOnboardingIfNeeded(BuildContext context) async {
    final isMobile = ResponsiveUtils.isMobile(context);
    const campaignId = 'onboarding_v1';

    // Check if already seen
    final hasSeenOnboarding = await repository.hasSeenCampaign(campaignId);
    if (hasSeenOnboarding) return;

    // Get slides
    final slides = await getOnboardingSlides();
    if (slides == null || slides.isEmpty) return;

    // Track view
    await _trackInteraction(
      campaignId: campaignId,
      type: PromoInteractionType.viewed,
    );

    if (!context.mounted) return;

    // Show carousel
    await PromoCarousel.show(
      context: context,
      slides: slides,
      config: PromoCarouselConfig.onboarding().copyWith(
        displayMode: !isMobile ? DisplayMode.dialog : DisplayMode.fullscreen,
      ),
    );

    // Mark as seen
    await repository.markCampaignAsSeen(campaignId);
  }

  /// Show feature announcements if needed
  Future<void> showFeatureAnnouncementsIfNeeded(
    BuildContext context,
    String currentVersion,
  ) async {
    final campaignId = 'feature_announcement_$currentVersion';

    // Check if already seen for this version
    final lastSeenVersion = await repository.getLastSeenVersion();
    if (lastSeenVersion == currentVersion) return;

    // Get slides
    final slides = await getFeatureAnnouncements(currentVersion);
    if (slides == null || slides.isEmpty) {
      // No announcements for this version, just update the version
      await repository.setLastSeenVersion(currentVersion);
      return;
    }

    // Track view
    await _trackInteraction(
      campaignId: campaignId,
      type: PromoInteractionType.viewed,
    );

    if (!context.mounted) return;

    // Show carousel
    await PromoCarousel.show(
      context: context,
      slides: slides,
      config: PromoCarouselConfig.announcement(),
      onAction: (action, target) async {
        await _handleAction(
          campaignId: campaignId,
          action: action,
          target: target,
          context: context,
        );
      },
    );

    // Mark version as seen
    await repository.setLastSeenVersion(currentVersion);
    await repository.markCampaignAsSeen(campaignId);
  }

  /// Show a contextual promo
  Future<void> showContextualPromo(
    BuildContext context, {
    required String campaignId,
    required List<PromoSlide> slides,
  }) async {
    // Check if already seen
    final hasSeenPromo = await repository.hasSeenCampaign(campaignId);
    if (hasSeenPromo) return;

    // Track view
    await _trackInteraction(
      campaignId: campaignId,
      type: PromoInteractionType.viewed,
    );

    if (!context.mounted) return;

    // Show carousel
    await PromoCarousel.show(
      context: context,
      slides: slides,
      config: PromoCarouselConfig(),
      onAction: (action, target) async {
        await _handleAction(
          campaignId: campaignId,
          action: action,
          target: target,
          context: context,
        );
      },
    );

    // Mark as seen
    await repository.markCampaignAsSeen(campaignId);
  }

  /// Handle promo action
  Future<void> _handleAction({
    required String campaignId,
    required PromoAction action,
    String? target,
    required BuildContext context,
  }) async {
    // Track CTA click
    await _trackInteraction(
      campaignId: campaignId,
      type: PromoInteractionType.ctaClicked,
      metadata: {'action': action.toString(), 'target': target},
    );

    // Log to analytics
    _logAnalyticsEvent('promo_cta_clicked', {
      'campaign_id': campaignId,
      'action': action.toString(),
      'target': target,
    });

    // Handle navigation using GoRouter
    if (action == PromoAction.navigate && target != null && context.mounted) {
      context.go(target);
    }
  }

  /// Track a promo interaction
  Future<void> _trackInteraction({
    required String campaignId,
    required PromoInteractionType type,
    String? slideId,
    Map<String, dynamic>? metadata,
  }) async {
    final interaction = PromoInteraction(
      campaignId: campaignId,
      timestamp: DateTime.now(),
      type: type,
      slideId: slideId,
      metadata: metadata,
    );

    await repository.trackInteraction(interaction);
  }

  /// Log analytics event
  void _logAnalyticsEvent(String eventName, Map<String, Object?> parameters) {
    if (analyticsService == null) return;

    // Filter out null values from parameters
    final nonNullParams = parameters.entries
        .where((entry) => entry.value != null)
        .fold<Map<String, Object>>(
          {},
          (map, entry) => map..[entry.key] = entry.value!,
        );

    analyticsService!.logEvent(
      _PromoAnalyticsEvent(name: eventName, parameters: nonNullParams),
    );
  }
}

/// Custom analytics event for promo tracking
class _PromoAnalyticsEvent extends AnalyticsEvent {
  const _PromoAnalyticsEvent({required super.name, required super.parameters});
}
