import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart';

void main() {
  late AppDatabase database;
  late DayNotesDao notes;

  setUpAll(() {
    database = AppDatabase(NativeDatabase.memory());
    notes = database.dayNotesDao;
  });
  setUp(() => database.delete(database.dayNotes).go());

  test('saving a day again updates it and keeps its creation time', () async {
    final first = DateTime.utc(2027, 1, 1, 9);
    final later = DateTime.utc(2027, 1, 2, 9);
    await notes.save('2027-01-01', 'Buy flowers', first);
    await notes.save('2027-01-01', 'Buy flowers and candles', later);
    final row = (await notes.all()).single;
    expect(row.body, 'Buy flowers and candles');
    expect(row.createdAt.isAtSameMomentAs(first), isTrue);
    expect(row.updatedAt.isAtSameMomentAs(later), isTrue);
  });

  test('a range and search find the right days, latest first', () async {
    final now = DateTime.utc(2027);
    await notes.save('2027-03-01', 'Pagoda festival', now);
    await notes.save('2027-03-15', 'Offer food to monks', now);
    await notes.save('2027-04-01', 'Thingyan trip 100%', now);
    expect(
      (await notes.watchBetween('2027-03-01', '2027-03-31').first).map(
        (n) => n.day,
      ),
      ['2027-03-01', '2027-03-15'],
    );
    expect((await notes.search('pagoda')).single.day, '2027-03-01');
    expect((await notes.search('100%')).single.day, '2027-04-01');
    expect(await notes.search('_'), isEmpty);
  });

  test('deleting a day removes only its note', () async {
    final now = DateTime.utc(2027);
    await notes.save('2027-05-01', 'A', now);
    await notes.save('2027-05-02', 'B', now);
    await notes.deleteDay('2027-05-01');
    expect((await notes.all()).map((n) => n.day), ['2027-05-02']);
  });
}
