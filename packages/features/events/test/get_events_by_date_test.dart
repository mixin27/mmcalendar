import 'package:dartz/dartz.dart';
import 'package:events/events.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

class _Repository implements EventsRepository {
  _Repository(this.events);
  final List<Event> events;

  @override
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date) async =>
      Right(events);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'a daily event appears once on its day, not with tomorrow too',
    () async {
      final day = DateTime(2026, 10, 16);
      final event = Event(
        id: 1,
        title: 'Morning offering',
        eventDate: DateTime(2026, 10, 1),
        category: EventCategory.religious,
        recurrenceRule: const RecurrenceRule(type: RecurrenceType.daily),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final result = await GetEventsByDate(
        _Repository([event.copyWith(eventDate: day)]),
      )(GetEventsByDateParams(day));

      final events = result.getOrElse(() => const []);
      expect(events, hasLength(1));
      expect(events.single.eventDate, day);
    },
  );
}
