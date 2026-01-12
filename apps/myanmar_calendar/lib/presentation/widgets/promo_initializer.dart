import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:promo/promo.dart';

import '../../config/di_setup.dart';

/// Wrapper widget that shows promo carousels after the app is fully initialized
class PromoInitializer extends StatefulWidget {
  final Widget child;

  const PromoInitializer({super.key, required this.child});

  @override
  State<PromoInitializer> createState() => _PromoInitializerState();
}

class _PromoInitializerState extends State<PromoInitializer> {
  bool _promosShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Show promos only once after the first build
    if (!_promosShown) {
      _promosShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPromos();
      });
    }
  }

  Future<void> _showPromos() async {
    if (!mounted) return;

    try {
      final promoService = getIt<PromoService>();

      // Show onboarding for first-time users
      await promoService.showOnboardingIfNeeded(context);

      if (!mounted) return;

      // Show feature announcements for new version
      await promoService.showFeatureAnnouncementsIfNeeded(
        context,
        AppConstants.appVersion,
      );
    } catch (e) {
      debugPrint('⚠️ Error showing promos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
