import 'package:flutter/foundation.dart';
import 'package:promo_carousel/promo_carousel.dart';

import '../repositories/promo_repository.dart';

/// Use case to get feature announcement slides for new versions
class GetFeatureAnnouncements {
  final PromoRepository repository;

  const GetFeatureAnnouncements(this.repository);

  /// Execute the use case
  /// Returns null if announcements have already been seen for this version
  Future<List<PromoSlide>?> call(String currentVersion) async {
    final lastSeenVersion = await repository.getLastSeenVersion();

    // If this is the same version, don't show announcements
    if (lastSeenVersion == currentVersion) {
      return null;
    }

    // Get version-specific announcements
    final slides = _getAnnouncementsForVersion(currentVersion);

    // If no announcements for this version, return null
    if (slides.isEmpty) {
      return null;
    }

    return slides;
  }

  List<PromoSlide> _getAnnouncementsForVersion(String version) {
    // Version 2.1.4 announcements
    if (version == '2.1.4') {
      return [
        PromoSlide(
          id: 'v2_1_4_recurring_events',
          title: 'Recurring Events',
          subtitle: 'Create daily, weekly, monthly, or yearly recurring events',
          visualType: PromoVisualType.animation,
          cta: PromoCTA(
            text: 'Try It Now',
            action: PromoAction.navigate,
            target: '/events/create',
          ),
          rules: PromoRules(showOnce: kReleaseMode, minAppVersion: '2.1.4'),
          semanticLabel: 'Recurring events feature announcement',
        ),
        PromoSlide(
          id: 'v2_1_4_date_converter_tools',
          title: 'Date Converter and Finder Tools',
          subtitle:
              'Convert between Myanmar and Gregorian dates, find next moon phases, and more',
          visualType: PromoVisualType.featureHighlight,
          cta: PromoCTA(
            text: 'Try It Now',
            action: PromoAction.navigate,
            target: '/converter',
          ),
          rules: PromoRules(showOnce: kReleaseMode, minAppVersion: '2.1.4'),
          semanticLabel: 'Date converter tools feature announcement',
        ),
      ];
    }

    // Version 2.2.0 announcements
    if (version == '2.2.0') {
      return [
        PromoSlide(
          id: 'v2_2_0_calendar_generation',
          title: 'Calendar Generation',
          subtitle:
              'Create monthly or yearly printable calendars with live preview.',
          visualType: PromoVisualType.featureHighlight,
          cta: PromoCTA(
            text: 'Open Generator',
            action: PromoAction.navigate,
            target: '/settings/calendar-generation',
          ),
          rules: PromoRules(showOnce: kReleaseMode, minAppVersion: '2.2.0'),
          semanticLabel: 'Calendar generation feature announcement',
        ),
        PromoSlide(
          id: 'v2_2_0_calendar_editor',
          title: 'Design Editor',
          subtitle:
              'Add text, emoji, stickers, and photos with interactive placement.',
          visualType: PromoVisualType.animation,
          cta: PromoCTA(
            text: 'Try Editor',
            action: PromoAction.navigate,
            target: '/settings/calendar-generation',
          ),
          rules: PromoRules(showOnce: kReleaseMode, minAppVersion: '2.2.0'),
          semanticLabel: 'Calendar design editor feature announcement',
        ),
        PromoSlide(
          id: 'v2_2_0_export_tools',
          title: 'Image and PDF Export',
          subtitle:
              'Export your calendar pages and save them to your device folders.',
          visualType: PromoVisualType.featureHighlight,
          cta: PromoCTA(
            text: 'Start Exporting',
            action: PromoAction.navigate,
            target: '/settings/calendar-generation',
          ),
          rules: PromoRules(showOnce: kReleaseMode, minAppVersion: '2.2.0'),
          semanticLabel: 'Calendar export tools feature announcement',
        ),
      ];
    }

    // Version 2.2.1/2.2.2 announcements
    if (version == '2.2.1' || version == '2.2.2') {
      return [
        PromoSlide(
          id: 'v2_2_1_app_icon_personalization',
          title: 'New: App Icon Themes',
          subtitle:
              'Switch between Default, Moon, Forest, Minimal Flat, Premium Dark, and Traditional Myanmar styles.',
          visualType: PromoVisualType.image,
          imageAsset: 'assets/branding/app_icon_1024.png',
          cta: PromoCTA(
            text: 'Choose Icon',
            action: PromoAction.navigate,
            target: '/settings/theme',
          ),
          rules: PromoRules(showOnce: kReleaseMode, minAppVersion: '2.2.1'),
          semanticLabel: 'App icon theme feature announcement',
        ),
      ];
    }

    return [];
  }
}
