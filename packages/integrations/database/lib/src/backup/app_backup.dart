import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// A backup that can't be restored: not a backup file, or from a newer app.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message, {this.newerVersion = false});

  final String message;

  /// The file is a backup from a newer app version.
  final bool newerVersion;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// How many of each thing a backup holds, or a restore added.
class BackupSummary {
  const BackupSummary({
    required this.events,
    required this.categories,
    required this.notes,
    required this.customHolidays,
  });

  final int events;
  final int categories;
  final int notes;
  final int customHolidays;

  bool get isEmpty =>
      events == 0 && categories == 0 && notes == 0 && customHolidays == 0;

  @override
  String toString() =>
      'BackupSummary(events: $events, categories: $categories, '
      'notes: $notes, customHolidays: $customHolidays)';
}

/// A parsed backup file.
class BackupFile {
  BackupFile._(this._json);

  final Map<String, dynamic> _json;

  /// When it was made.
  DateTime get createdAt =>
      DateTime.tryParse(_json['createdAt'] as String? ?? '') ?? DateTime(0);

  /// App settings saved with it (holiday reminder choices...).
  Map<String, dynamic> get settings =>
      Map<String, dynamic>.from(_json['settings'] as Map? ?? const {});

  List<Map<String, dynamic>> _rows(String table) => [
    for (final row in (_json['tables'] as Map)[table] as List? ?? const [])
      Map<String, dynamic>.from(row as Map),
  ];

  BackupSummary get summary => BackupSummary(
    events: _rows(AppBackup._events).length,
    categories: _rows(AppBackup._categories).length,
    notes: _rows(AppBackup._notes).length,
    customHolidays: _rows(AppBackup._customHolidays).length,
  );
}

/// Backs up and restores what people make in the app: events (with their
/// reminders, repeat rules and edited or skipped occurrences), event
/// categories, custom holidays and day notes. Calendar Studio projects have
/// their own export and aren't included.
///
/// The file is JSON: `{format, version, createdAt, settings, tables}`, each
/// table a list of rows as drift writes them.
class AppBackup {
  AppBackup(this._db);

  final AppDatabase _db;

  /// Written into every file, and checked on restore.
  static const format = 'mmcalendar-backup';
  static const version = 1;

  /// The file extension, without the dot.
  static const extension = 'mmcbackup';

  static const _categories = 'eventCategories';
  static const _events = 'calendarEvents';
  static const _reminders = 'eventReminders';
  static const _rules = 'eventRecurrenceRules';
  static const _exceptions = 'recurringEventExceptions';
  static const _customHolidays = 'customHolidays';
  static const _notes = 'dayNotes';

  /// Everything, as the bytes of a backup file. [settings] are stored as
  /// they are and handed back by [BackupFile.settings].
  Future<List<int>> export({
    Map<String, Object?> settings = const {},
    DateTime? now,
  }) async {
    List<Map<String, dynamic>> rows(List<DataClass> list) => [
      for (final r in list) r.toJson(),
    ];
    final json = {
      'format': format,
      'version': version,
      'createdAt': (now ?? DateTime.now()).toIso8601String(),
      'settings': settings,
      'tables': {
        _categories: rows(await _db.select(_db.eventCategories).get()),
        _events: rows(await _db.select(_db.calendarEvents).get()),
        _reminders: rows(await _db.select(_db.eventReminders).get()),
        _rules: rows(await _db.select(_db.eventRecurrenceRules).get()),
        _exceptions: rows(await _db.select(_db.recurringEventExceptions).get()),
        _customHolidays: rows(await _db.select(_db.customHolidays).get()),
        _notes: rows(await _db.select(_db.dayNotes).get()),
      },
    };
    return utf8.encode(jsonEncode(json));
  }

  /// Reads a backup file, or throws [BackupFormatException].
  static BackupFile read(List<int> bytes) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupFormatException('Not a backup file');
    }
    if (json is! Map || json['format'] != format || json['tables'] is! Map) {
      throw const BackupFormatException('Not a backup file');
    }
    final v = json['version'];
    if (v is! int || v > version) {
      throw const BackupFormatException(
        'Made by a newer version of the app',
        newerVersion: true,
      );
    }
    return BackupFile._(Map<String, dynamic>.from(json));
  }

  /// Restores [file]. Returns what it added.
  ///
  /// With [replace], every event, category, custom holiday and note here is
  /// deleted first and the backup's are written as they were.
  ///
  /// Otherwise it merges: new rows get new ids (so nothing here is
  /// overwritten), categories are matched by name, events already here
  /// (same title, date and creation time) and custom holidays already here
  /// (same name and date) are skipped, and a day's note is kept unless the
  /// backup's is newer.
  Future<BackupSummary> restore(BackupFile file, {bool replace = false}) =>
      _db.transaction(() => replace ? _replace(file) : _merge(file));

  Future<BackupSummary> _replace(BackupFile file) async {
    await _db.delete(_db.eventReminders).go();
    await _db.delete(_db.eventRecurrenceRules).go();
    await _db.delete(_db.recurringEventExceptions).go();
    await _db.delete(_db.calendarEvents).go();
    await _db.delete(_db.eventCategories).go();
    await _db.delete(_db.customHolidays).go();
    await _db.delete(_db.dayNotes).go();
    await _db.batch((b) {
      b.insertAll(_db.eventCategories, [
        for (final r in file._rows(_categories)) EventCategory.fromJson(r),
      ]);
      b.insertAll(_db.calendarEvents, [
        for (final r in file._rows(_events)) CalendarEvent.fromJson(r),
      ]);
      b.insertAll(_db.eventReminders, [
        for (final r in file._rows(_reminders)) EventReminder.fromJson(r),
      ]);
      b.insertAll(_db.eventRecurrenceRules, [
        for (final r in file._rows(_rules)) EventRecurrenceRule.fromJson(r),
      ]);
      b.insertAll(_db.recurringEventExceptions, [
        for (final r in file._rows(_exceptions))
          RecurringEventException.fromJson(r),
      ]);
      b.insertAll(_db.customHolidays, [
        for (final r in file._rows(_customHolidays)) CustomHoliday.fromJson(r),
      ]);
      b.insertAll(_db.dayNotes, [
        for (final r in file._rows(_notes)) DayNoteRow.fromJson(r),
      ]);
    });
    return file.summary;
  }

  Future<BackupSummary> _merge(BackupFile file) async {
    var addedCategories = 0, addedEvents = 0, addedHolidays = 0;
    var addedNotes = 0;

    // Categories, matched by their unique name.
    final categoryIds = <int, int>{};
    final existingCategories = {
      for (final c in await _db.select(_db.eventCategories).get()) c.name: c.id,
    };
    for (final r in file._rows(_categories)) {
      final c = EventCategory.fromJson(r);
      final id =
          existingCategories[c.name] ??
          await _db
              .into(_db.eventCategories)
              .insert(c.toCompanion(true).copyWith(id: const Value.absent()));
      if (!existingCategories.containsKey(c.name)) addedCategories++;
      existingCategories[c.name] = id;
      categoryIds[c.id] = id;
    }

    // Events; the ones already here are skipped with everything attached.
    String key(String title, DateTime date, DateTime created) =>
        '$title|${date.millisecondsSinceEpoch}|'
        '${created.millisecondsSinceEpoch}';
    final existingEvents = {
      for (final e in await _db.select(_db.calendarEvents).get())
        key(e.title, e.eventDate, e.createdAt),
    };
    final eventIds = <int, int>{};
    for (final r in file._rows(_events)) {
      final e = CalendarEvent.fromJson(r);
      if (existingEvents.contains(key(e.title, e.eventDate, e.createdAt))) {
        continue;
      }
      eventIds[e.id] = await _db
          .into(_db.calendarEvents)
          .insert(
            e
                .toCompanion(true)
                .copyWith(
                  id: const Value.absent(),
                  categoryId: Value(
                    e.categoryId == null ? null : categoryIds[e.categoryId],
                  ),
                  // Unique; it only ties the row to pre-v3 data here.
                  legacyEventId: const Value(null),
                ),
          );
      addedEvents++;
    }
    for (final r in file._rows(_reminders)) {
      final m = EventReminder.fromJson(r);
      final eventId = eventIds[m.eventId];
      if (eventId == null) continue;
      await _db
          .into(_db.eventReminders)
          .insert(
            m
                .toCompanion(true)
                .copyWith(id: const Value.absent(), eventId: Value(eventId)),
            mode: InsertMode.insertOrIgnore,
          );
    }
    for (final r in file._rows(_rules)) {
      final rule = EventRecurrenceRule.fromJson(r);
      final eventId = eventIds[rule.eventId];
      if (eventId == null) continue;
      await _db
          .into(_db.eventRecurrenceRules)
          .insert(
            rule.toCompanion(true).copyWith(eventId: Value(eventId)),
            mode: InsertMode.insertOrIgnore,
          );
    }
    for (final r in file._rows(_exceptions)) {
      final x = RecurringEventException.fromJson(r);
      final eventId = eventIds[x.masterEventId];
      if (eventId == null) continue;
      await _db
          .into(_db.recurringEventExceptions)
          .insert(
            x
                .toCompanion(true)
                .copyWith(
                  id: const Value.absent(),
                  masterEventId: Value(eventId),
                ),
          );
    }

    // Custom holidays, matched by name and date.
    final existingHolidays = {
      for (final h in await _db.select(_db.customHolidays).get())
        '${h.name}|${h.date.millisecondsSinceEpoch}',
    };
    for (final r in file._rows(_customHolidays)) {
      final h = CustomHoliday.fromJson(r);
      if (!existingHolidays.add('${h.name}|${h.date.millisecondsSinceEpoch}')) {
        continue;
      }
      await _db
          .into(_db.customHolidays)
          .insert(h.toCompanion(true).copyWith(id: const Value.absent()));
      addedHolidays++;
    }

    // Notes: one per day; the newer one wins.
    final existingNotes = {
      for (final n in await _db.select(_db.dayNotes).get()) n.day: n,
    };
    for (final r in file._rows(_notes)) {
      final n = DayNoteRow.fromJson(r);
      final here = existingNotes[n.day];
      if (here != null && !n.updatedAt.isAfter(here.updatedAt)) continue;
      await _db.into(_db.dayNotes).insertOnConflictUpdate(n);
      if (here == null) addedNotes++;
    }

    return BackupSummary(
      events: addedEvents,
      categories: addedCategories,
      notes: addedNotes,
      customHolidays: addedHolidays,
    );
  }
}
