import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:promo/promo.dart';
import 'package:settings/settings.dart';
import 'package:whats_new/whats_new.dart';

import '../../config/di_setup.dart';

/// Shows onboarding, then What's new after an update, once the app is ready.
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
      final store = getIt<WhatsNewStore>();
      // A first run is introduced by onboarding, not What's new.
      final firstRun = store.lastSeen == null;

      await getIt<PromoService>().showOnboardingIfNeeded(context);
      if (!mounted) return;

      final pending = firstRun ? const <PendingWhatsNew>[] : store.pending();
      if (pending.isNotEmpty) {
        final router = GoRouter.of(context);
        await showWhatsNewSheet(
          context,
          items: pending,
          currentVersion: store.currentVersion,
          onOpen: router.go,
          onSeeAll: () => router.go(RoutePaths.whatsNewPath()),
        );
      }
      await store.markSeen();
    } catch (e) {
      debugPrint("⚠️ Error showing onboarding or What's new: $e");
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
