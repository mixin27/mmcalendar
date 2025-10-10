import '../app_event.dart';

class EventCreatedEvent extends AppEvent {
  final int eventId;
  final String title;
  EventCreatedEvent(this.eventId, this.title);
}

class EventUpdatedEvent extends AppEvent {
  final int eventId;
  final String title;
  EventUpdatedEvent(this.eventId, this.title);
}

class EventDeletedEvent extends AppEvent {
  final int eventId;
  EventDeletedEvent(this.eventId);
}
