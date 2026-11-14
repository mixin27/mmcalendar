import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_widgets/home_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // home_widget's storage, as the native widgets see it.
  final store = <String, Object?>{};
  void Function()? onRead;

  setUp(() {
    store.clear();
    onRead = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (
          call,
        ) async {
          final args = call.arguments as Map<Object?, Object?>;
          switch (call.method) {
            case 'getWidgetData':
              onRead?.call();
              return store[args['id']];
            case 'saveWidgetData':
              store[args['id'] as String] = args['data'];
              return true;
          }
          return null;
        });
  });

  Map<String, Object> tick(int id, String day, {bool done = true}) => {
    'id': id,
    'd': day,
    'rec': false,
    'done': done,
  };

  WidgetAgendaEvent event(int id, DateTime date, {bool done = false}) =>
      WidgetAgendaEvent(
        id: id,
        date: date,
        title: 'Event $id',
        color: 0xFF000000,
        done: done,
      );

  group('parse', () {
    test('reads what the native widgets write', () {
      final toggles = WidgetActions.parse(
        jsonEncode([
          {'id': 5, 'd': '2026-11-13', 'rec': true, 'done': true},
        ]),
      );
      expect(toggles, [
        WidgetEventToggle(
          id: 5,
          date: DateTime(2026, 11, 13),
          done: true,
          recurring: true,
        ),
      ]);
    });

    test('skips what it cannot read', () {
      expect(WidgetActions.parse(null), isEmpty);
      expect(WidgetActions.parse('not json'), isEmpty);
      expect(WidgetActions.parse('{"id": 1}'), isEmpty);
      expect(
        WidgetActions.parse(
          jsonEncode([
            {'id': 'x', 'd': '2026-11-13', 'done': true},
            {'id': 1, 'd': 'no date', 'done': true},
            tick(2, '2026-11-13'),
          ]),
        ).map((t) => t.id),
        [2],
      );
    });

    test('round-trips through toJson', () {
      final t = WidgetEventToggle(
        id: 3,
        date: DateTime(2026, 1, 2),
        done: false,
        recurring: true,
      );
      expect(WidgetEventToggle.fromJson(t.toJson()), t);
    });
  });

  test('the last tap on an occurrence wins', () {
    final latest = WidgetActions.latest(
      WidgetActions.parse(
        jsonEncode([
          tick(1, '2026-11-13'),
          tick(2, '2026-11-13'),
          tick(1, '2026-11-13', done: false),
          tick(1, '2026-11-14'),
        ]),
      ),
    );
    expect([for (final t in latest) (t.id, t.date.day, t.done)], [
      (2, 13, true),
      (1, 13, false),
      (1, 14, true),
    ]);
  });

  test('overlay ticks the matching occurrences only', () {
    final events = [
      event(1, DateTime(2026, 11, 13)),
      event(1, DateTime(2026, 11, 20)),
      event(2, DateTime(2026, 11, 13), done: true),
    ];
    final shown = WidgetActions.overlay(
      events,
      WidgetActions.parse(
        jsonEncode([
          tick(1, '2026-11-13'),
          tick(2, '2026-11-13', done: false),
        ]),
      ),
    );
    expect([for (final e in shown) e.done], [true, false, false]);
    expect(shown.first.title, 'Event 1');
  });

  group('apply', () {
    test('saves each tick and empties the queue', () async {
      store[WidgetActions.key] = jsonEncode([
        tick(1, '2026-11-13'),
        tick(1, '2026-11-13', done: false),
        tick(2, '2026-11-14'),
      ]);
      final saved = <WidgetEventToggle>[];
      final count = await WidgetActions.apply((t) async => saved.add(t));
      expect(count, 2);
      expect([for (final t in saved) (t.id, t.done)], [(1, false), (2, true)]);
      expect(WidgetActions.parse(store[WidgetActions.key] as String), isEmpty);
    });

    test('keeps ticks made while it runs', () async {
      store[WidgetActions.key] = jsonEncode([tick(1, '2026-11-13')]);
      var reads = 0;
      onRead = () {
        // A tap on the widget between the first read and the clean-up.
        if (++reads == 2) {
          store[WidgetActions.key] = jsonEncode([
            tick(1, '2026-11-13'),
            tick(7, '2026-11-15'),
          ]);
        }
      };
      await WidgetActions.apply((_) async {});
      expect(
        WidgetActions.parse(store[WidgetActions.key] as String).map((t) => t.id),
        [7],
      );
    });

    test('drops a tick that fails, applies the rest', () async {
      store[WidgetActions.key] = jsonEncode([
        tick(1, '2026-11-13'),
        tick(2, '2026-11-13'),
      ]);
      final count = await WidgetActions.apply((t) async {
        if (t.id == 1) throw StateError('deleted');
      });
      expect(count, 1);
      expect(WidgetActions.parse(store[WidgetActions.key] as String), isEmpty);
    });

    test('does nothing with an empty queue', () async {
      expect(await WidgetActions.apply((_) async => fail('no ticks')), 0);
      expect(store.containsKey(WidgetActions.key), isFalse);
    });
  });
}
