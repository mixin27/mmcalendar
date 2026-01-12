import 'package:flutter/foundation.dart';
import 'package:promo_carousel/promo_carousel.dart';

import '../repositories/promo_repository.dart';

/// Use case to get onboarding slides if they should be shown
class GetOnboardingSlides {
  final PromoRepository repository;

  const GetOnboardingSlides(this.repository);

  /// Execute the use case
  /// Returns null if onboarding has already been seen
  Future<List<PromoSlide>?> call() async {
    const campaignId = 'onboarding_v1';

    // Check if user has already seen onboarding
    final hasSeenOnboarding = await repository.hasSeenCampaign(campaignId);
    if (hasSeenOnboarding) {
      return null;
    }

    // Return onboarding slides
    return _getOnboardingSlides();
  }

  List<PromoSlide> _getOnboardingSlides() {
    return [
      PromoSlide(
        id: 'welcome',
        title: 'Welcome to Myanmar Calendar',
        subtitle: 'Your traditional calendar companion with modern features',
        visualType: PromoVisualType.featureHighlight,
        cta: PromoCTA(text: 'Next', action: PromoAction.next),
        rules: PromoRules(showOnce: kReleaseMode),
        semanticLabel: 'Welcome screen',
      ),
      PromoSlide(
        id: 'events',
        title: 'Create & Manage Events',
        subtitle:
            'Set reminders for important dates with recurring event support',
        visualType: PromoVisualType.animation,
        cta: PromoCTA(text: 'Next', action: PromoAction.next),
        rules: PromoRules(showOnce: kReleaseMode),
        semanticLabel: 'Events feature introduction',
      ),
      PromoSlide(
        id: 'traditional_calendar',
        title: 'Myanmar Traditional Calendar',
        subtitle: 'View Myanmar dates, holidays, and auspicious days',
        visualType: PromoVisualType.featureHighlight,
        cta: PromoCTA(text: 'Next', action: PromoAction.next),
        rules: PromoRules(showOnce: kReleaseMode),
        semanticLabel: 'Traditional calendar features',
      ),
      PromoSlide(
        id: 'privacy',
        title: '100% Privacy & Offline',
        subtitle:
            'All your data stays on your device. Works completely offline!',
        visualType: PromoVisualType.featureHighlight,
        cta: PromoCTA(text: 'Get Started', action: PromoAction.close),
        rules: PromoRules(showOnce: kReleaseMode),
        semanticLabel: 'Privacy and offline features',
      ),
    ];
  }
}
