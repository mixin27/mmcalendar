import 'package:flutter/widgets.dart';

/// Shared UI action boundary for event feature navigation flows.
///
/// Feature consumers invoke these intents without depending on event route
/// paths or event UI implementation details.
abstract interface class EventActionsPort {
  Future<void> openCreateEvent(BuildContext context, {DateTime? initialDate});

  Future<void> openEventDetail(BuildContext context, {required int eventId});
}
