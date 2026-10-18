import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onboarding/onboarding.dart';
import 'package:shared_core/shared_core.dart';
import 'package:whats_new/whats_new.dart';

import '../../config/di_setup.dart';

/// Shows What's new once after an update, over the app shell.
class WhatsNewPresenter extends StatefulWidget {
  const WhatsNewPresenter({super.key, required this.child});

  final Widget child;

  @override
  State<WhatsNewPresenter> createState() => _WhatsNewPresenterState();
}

class _WhatsNewPresenterState extends State<WhatsNewPresenter> {
  var _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  Future<void> _show() async {
    if (!mounted || !getIt<OnboardingStore>().completed) return;
    final store = getIt<WhatsNewStore>();
    final pending = store.pending();
    if (pending.isEmpty) {
      await store.markSeen();
      return;
    }
    final router = GoRouter.of(context);
    try {
      await showWhatsNewSheet(
        context,
        items: pending,
        currentVersion: store.currentVersion,
        onOpen: router.go,
        onSeeAll: () => router.go(RoutePaths.whatsNewPath()),
      );
    } finally {
      await store.markSeen();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
