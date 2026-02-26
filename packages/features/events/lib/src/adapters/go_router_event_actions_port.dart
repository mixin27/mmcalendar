import 'package:shared_core/shared_core.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class GoRouterEventActionsPort implements EventActionsPort {
  @override
  Future<void> openCreateEvent(
    BuildContext context, {
    DateTime? initialDate,
  }) async {
    await GoRouter.of(
      context,
    ).push(RoutePaths.eventsCreate(), extra: initialDate);
  }

  @override
  Future<void> openEventDetail(
    BuildContext context, {
    required int eventId,
  }) async {
    await GoRouter.of(context).push(RoutePaths.eventsDetail(eventId));
  }
}
