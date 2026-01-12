import 'package:promo_carousel/promo_carousel.dart';

/// Contextual promo slides for user behavior-based promotions
class ContextualPromoSlides {
  /// Promo to encourage using event categories
  static List<PromoSlide> getCategoryDiscoveryPromo() {
    return [
      PromoSlide(
        id: 'discover_categories',
        title: 'Did You Know?',
        subtitle: 'You can organize events with custom categories and colors',
        visualType: PromoVisualType.featureHighlight,
        cta: PromoCTA(
          text: 'Create Category',
          action: PromoAction.navigate,
          target: '/categories/create',
        ),
        rules: PromoRules(showOnce: true),
        semanticLabel: 'Category feature discovery',
      ),
    ];
  }

  /// Promo to encourage creating first event
  static List<PromoSlide> getCreateEventPromo() {
    return [
      PromoSlide(
        id: 'create_first_event',
        title: 'Never Miss Important Dates',
        subtitle:
            'Create events and get reminders for birthdays, meetings, and more',
        visualType: PromoVisualType.animation,
        cta: PromoCTA(
          text: 'Create Event',
          action: PromoAction.navigate,
          target: '/events/create',
        ),
        rules: PromoRules(showOnce: true),
        semanticLabel: 'Create first event prompt',
      ),
    ];
  }

  /// Promo to encourage setting up home widget (Android only)
  static List<PromoSlide> getHomeWidgetPromo() {
    return [
      PromoSlide(
        id: 'home_widget_setup',
        title: 'Add Calendar Widget',
        subtitle: 'See today\'s date on your home screen',
        visualType: PromoVisualType.animation,
        cta: PromoCTA(
          text: 'Set Up Widget',
          action: PromoAction.openFeature,
          target: 'widget_settings',
        ),
        rules: PromoRules(showOnce: true, deviceTypes: [DeviceType.mobile]),
        semanticLabel: 'Home widget setup prompt',
      ),
    ];
  }

  /// Promo for Myanmar holidays feature
  static List<PromoSlide> getMyanmarHolidaysPromo() {
    return [
      PromoSlide(
        id: 'myanmar_holidays',
        title: 'Never Miss Myanmar Holidays',
        subtitle: 'View traditional holidays and auspicious days',
        visualType: PromoVisualType.featureHighlight,
        cta: PromoCTA(
          text: 'View Holidays',
          action: PromoAction.navigate,
          target: '/holidays',
        ),
        rules: PromoRules(showOnce: true),
        semanticLabel: 'Myanmar holidays feature',
      ),
    ];
  }
}
