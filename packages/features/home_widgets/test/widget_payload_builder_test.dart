import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// The builder's own tests live in packages/shared/widget_payload; these
/// cover what the phone's widgets add to it: styles, prefs, links, config.
void main() {
  final today = DateTime(2026, 10, 18);

  Map<String, Object?> build(
    Language language, {
    List<WidgetAgendaEvent>? events,
  }) => WidgetPayloadBuilder.build(
    today: today,
    language: language,
    events: events ?? const [],
    styles: WidgetPalettes.all(),
    prefs: const WidgetConfig.defaults().toPayload(),
    generatedAt: DateTime(2026, 10, 18, 9),
  );

  test('events, styles and prefs are passed through', () {
    final payload = build(
      Language.english,
      events: [
        WidgetAgendaEvent(
          id: 3,
          date: today,
          title: 'Team call',
          color: 0xFF2F5BEA,
          time: DateTime(2026, 10, 18, 15, 30),
        ),
      ],
    );
    final event = (payload['events']! as List).single as Map;
    expect(event['t'], '15:30');
    expect(event['ti'], 'Team call');
    final styles = payload['styles']! as Map;
    for (final style in WidgetStyleId.values) {
      expect((styles[style.name] as Map).keys, containsAll(['light', 'dark']));
    }
    expect((payload['prefs']! as Map)['style'], 'app');
  });

  test('stays small enough to read on every widget refresh', () {
    final bytes = utf8.encode(jsonEncode(build(Language.myanmar))).length;
    expect(bytes, lessThan(160 * 1024));
  });

  group('links', () {
    String? go(String uri) => WidgetLinks.locationFor(Uri.parse(uri));

    test('map to app locations', () {
      expect(go('mmcalendar://today'), '/home');
      expect(
        go('mmcalendar://day/2026-10-18?homeWidget'),
        '/home/day-details?date=2026-10-18',
      );
      expect(go('mmcalendar://month/2026-11'), '/home?date=2026-11-01');
      expect(go('mmcalendar://event/12'), '/events/12/detail');
      expect(
        go('mmcalendar://events/new?date=2026-10-18'),
        '/events/create?date=2026-10-18',
      );
      expect(go('mmcalendar://events'), '/events');
      expect(
        go('mmcalendar://add-event?e=eyJ2Ijox'),
        '/events/shared?e=eyJ2Ijox',
      );
      expect(go('mmcalendar://add-event'), '/events');
    });

    test('ignore other schemes', () {
      expect(go('https://example.com/day/2026-10-18'), isNull);
      expect(WidgetLinks.locationFor(null), isNull);
    });
  });

  group('config', () {
    test('v1 themes migrate to styles', () {
      WidgetStyleId style(String theme) =>
          WidgetConfig.fromJson({'theme': theme}).style;
      expect(style('traditional'), WidgetStyleId.pagoda);
      expect(style('dark'), WidgetStyleId.plain);
      expect(style('gradientBlue'), WidgetStyleId.app);
    });

    test('round-trips', () {
      const config = WidgetConfig(
        style: WidgetStyleId.jade,
        showHolidays: false,
        showSabbath: true,
        showAstrology: false,
        showEvents: true,
        countdownTarget: CountdownTarget.thingyan,
        language: 'my',
      );
      expect(WidgetConfig.fromJson(config.toJson()), config);
    });
  });
}
