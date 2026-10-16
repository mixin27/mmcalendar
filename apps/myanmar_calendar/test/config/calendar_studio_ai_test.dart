import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmcalendar/config/calendar_studio_ai.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  const request = CalendarStudioTextSuggestionRequest(
    kind: CalendarStudioTextKind.title,
    language: CalendarStudioLanguage.both,
    year: 2027,
    month: 4,
    pageLabel: 'April',
    templateName: 'Jade wall',
    currentText: 'Happy Thingyan',
    holidays: ['Thingyan', 'Thingyan', 'Myanmar New Year'],
    sabbathDays: [7, 14],
  );

  test('prompt carries calendar context and language rules', () {
    final prompt = studioSuggestionPrompt(request);
    expect(prompt, contains('page titles'));
    expect(prompt, contains('April 2027'));
    expect(prompt, contains('Jade wall'));
    expect(prompt, contains('Thingyan, Myanmar New Year'));
    expect(prompt, contains('7, 14'));
    expect(prompt, contains('Burmese followed by " / "'));
    expect(prompt, contains('Happy Thingyan'));
  });

  test('prompt omits empty context', () {
    final prompt = studioSuggestionPrompt(
      const CalendarStudioTextSuggestionRequest(
        kind: CalendarStudioTextKind.quote,
        language: CalendarStudioLanguage.english,
        year: 2027,
        month: 2,
        pageLabel: 'February',
        templateName: 'Plain planner',
      ),
    );
    expect(prompt, isNot(contains('holidays')));
    expect(prompt, isNot(contains('Sabbath')));
    expect(prompt, contains('Write in English.'));
  });

  test('suggestions are parsed defensively', () {
    expect(parseStudioSuggestions(null), isEmpty);
    expect(parseStudioSuggestions('not json'), isEmpty);
    expect(parseStudioSuggestions('{"a": 1}'), isEmpty);
    expect(
      parseStudioSuggestions(
        '[" Spring ", "Spring", "", 4, "${'x' * 200}", "A", "B", "C", "D", "E", "F"]',
      ),
      ['Spring', 'A', 'B', 'C', 'D', 'E'],
    );
  });

  test('suggestions stay hidden while the remote flag is off', () async {
    final suggester = FirebaseStudioTextSuggester(_RemoteConfig({}));
    expect(await suggester.isAvailable(), isFalse);
  });
}

class _RemoteConfig implements RemoteConfigPort {
  _RemoteConfig(this.values);
  final Map<String, Object> values;

  @override
  Future<void> initialize() async {}
  @override
  Future<RemoteFetchResult> fetchAndActivate() async =>
      RemoteFetchResult.noChange;
  @override
  bool getBool(String key) => values[key] == true;
  @override
  String getString(String key) => values[key]?.toString() ?? '';
  @override
  int getInt(String key) => 0;
  @override
  double getDouble(String key) => 0;
  @override
  Map<String, Object> getAll() => values;
}
