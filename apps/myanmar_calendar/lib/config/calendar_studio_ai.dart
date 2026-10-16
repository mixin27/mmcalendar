import 'dart:async';
import 'dart:convert';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_core/shared_core.dart';

/// Remote Config keys that control Calendar Studio AI without a release.
abstract final class CalendarStudioAiFlags {
  /// Must be `true` for "Suggest text" to appear. Off by default.
  static const textSuggestionsEnabled = 'studio_ai_text_suggestions_enabled';

  /// Gemini model name; empty uses [defaultModel].
  static const model = 'studio_ai_model';

  static const defaultModel = 'gemini-3.1-flash-lite';
}

/// Text suggestions through Firebase AI Logic (Gemini Developer API).
///
/// No Gemini key ships in the app: requests are authorised by the Firebase
/// project and protected by App Check. Only canonical calendar context is
/// sent (month, public holidays, Sabbath days, template), never user events.
class FirebaseStudioTextSuggester implements CalendarStudioTextSuggester {
  FirebaseStudioTextSuggester(this._remoteConfig, {FirebaseAI? ai}) : _ai = ai;

  final RemoteConfigPort _remoteConfig;
  final FirebaseAI? _ai;

  @override
  Future<bool> isAvailable() async =>
      Firebase.apps.isNotEmpty &&
      _remoteConfig.getBool(CalendarStudioAiFlags.textSuggestionsEnabled);

  @override
  Future<List<String>> suggest(
    CalendarStudioTextSuggestionRequest request,
  ) async {
    final configured = _remoteConfig.getString(CalendarStudioAiFlags.model);
    final model = (_ai ?? FirebaseAI.googleAI()).generativeModel(
      model: configured.trim().isEmpty
          ? CalendarStudioAiFlags.defaultModel
          : configured.trim(),
      systemInstruction: Content.system(studioSuggestionInstructions),
      generationConfig: GenerationConfig(
        temperature: .9,
        maxOutputTokens: 600,
        responseMimeType: 'application/json',
        responseSchema: Schema.array(
          items: Schema.string(),
          minItems: 3,
          maxItems: 6,
        ),
      ),
    );
    final response = await model
        .generateContent([Content.text(studioSuggestionPrompt(request))])
        .timeout(const Duration(seconds: 25));
    return parseStudioSuggestions(response.text);
  }
}

const studioSuggestionInstructions =
    'You write short text for printed wall and desk calendars made in a '
    'Myanmar calendar app. Be warm, culturally respectful and accurate. '
    'Never invent holidays, dates or facts beyond the context given. '
    'Myanmar text must be standard Unicode Burmese, never Zawgyi. '
    'Reply only with a JSON array of strings.';

/// Builds the user prompt; kept pure for tests.
String studioSuggestionPrompt(CalendarStudioTextSuggestionRequest request) {
  final kind = switch (request.kind) {
    CalendarStudioTextKind.title => 'page titles of at most 6 words each',
    CalendarStudioTextKind.quote =>
      'short inspirational quotes or proverbs of at most 20 words each',
    CalendarStudioTextKind.caption => 'short captions of at most 12 words each',
  };
  final language = switch (request.language) {
    CalendarStudioLanguage.myanmar => 'Write in Burmese.',
    CalendarStudioLanguage.english => 'Write in English.',
    CalendarStudioLanguage.both =>
      'Write each suggestion in Burmese followed by " / " and its English '
          'translation.',
  };
  return [
    'Suggest 5 $kind for the ${request.pageLabel} ${request.year} page '
        '(month ${request.month}) of a "${request.templateName}" calendar.',
    language,
    if (request.holidays.isNotEmpty)
      'Public holidays this month: ${request.holidays.toSet().join(', ')}.',
    if (request.sabbathDays.isNotEmpty)
      'Sabbath (ဥပုသ်) days this month: ${request.sabbathDays.join(', ')}.',
    if (request.currentText.trim().isNotEmpty)
      'The current text is "${request.currentText.trim()}"; offer '
          'alternatives in a similar spirit.',
  ].join('\n');
}

/// Parses the model's JSON array defensively: trims, de-duplicates, drops
/// empty or overly long items and caps the list.
List<String> parseStudioSuggestions(String? text) {
  if (text == null || text.trim().isEmpty) return const [];
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return const [];
  }
  if (decoded is! List) return const [];
  final seen = <String>{};
  return [
    for (final item in decoded)
      if (item is String)
        if (item.trim() case final value
            when value.isNotEmpty && value.length <= 160 && seen.add(value))
          value,
  ].take(6).toList();
}
