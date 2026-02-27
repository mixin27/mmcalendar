import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';

import '../../domain/entities/event.dart';
import '../../domain/usecases/create_user_event.dart';
import '../../domain/usecases/update_user_event.dart';
import '../../services/smart_notification_scheduler.dart';

/// Coordinates persistence + notification scheduling for event mutations.
class EventFlowService {
  final CreateUserEvent createUserEvent;
  final UpdateUserEvent updateUserEvent;
  final SmartNotificationScheduler smartNotificationScheduler;

  EventFlowService({
    required this.createUserEvent,
    required this.updateUserEvent,
    required this.smartNotificationScheduler,
  });

  Future<Either<Failure, EventFlowResult>> saveEvent(Event event) async {
    final isUpdate = event.id != null;

    final result = isUpdate
        ? await updateUserEvent(UpdateUserEventParams(event))
        : await createUserEvent(CreateUserEventParams(event));

    Failure? failed;
    Event? persisted;
    result.fold((failure) => failed = failure, (event) => persisted = event);
    if (failed != null) {
      return Left(failed!);
    }

    String? warning;
    try {
      if (isUpdate && persisted!.id != null) {
        await smartNotificationScheduler.cancelEventNotifications(
          persisted!.id!,
        );
      }
      if (persisted!.hasNotifications) {
        await smartNotificationScheduler.scheduleEventNotification(persisted!);
      }
    } catch (_) {
      warning =
          'Event saved, but reminder scheduling failed. Please refresh reminders.';
    }

    return Right(
      EventFlowResult(
        event: persisted!,
        isNew: !isUpdate,
        warningMessage: warning,
      ),
    );
  }
}

class EventFlowResult {
  final Event event;
  final bool isNew;
  final String? warningMessage;

  const EventFlowResult({
    required this.event,
    required this.isNew,
    this.warningMessage,
  });
}
