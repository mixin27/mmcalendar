import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:promo/promo.dart';
import 'package:settings/settings.dart';

import '../../config/di_setup.dart';

/// Wrapper widget that shows promo carousels after the app is fully initialized
class PromoInitializer extends StatefulWidget {
  final Widget child;

  const PromoInitializer({super.key, required this.child});

  @override
  State<PromoInitializer> createState() => _PromoInitializerState();
}

class _PromoInitializerState extends State<PromoInitializer> {
  bool _promosQueued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _queuePromosIfReady(context.read<SettingsBloc>().state);
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

  void _queuePromosIfReady(SettingsState state) {
    if (_promosQueued) return;
    if (state is! SettingsLoaded) return;
    if (!state.settings.hasShownConsentDialog) return;

    _promosQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPromos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (_, state) => state is SettingsLoaded,
      listener: (context, state) => _queuePromosIfReady(state),
      child: widget.child,
    );
  }
}
