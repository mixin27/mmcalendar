import 'dart:convert';

import 'package:events/events.dart' show SmartNotificationScheduler;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:holidays/holidays.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

/// Saves a file: the share sheet on phones (Files, Drive, iCloud...), a
/// save dialog or a download elsewhere.
typedef BackupFileSaver =
    Future<void> Function(Uint8List bytes, String name, String mimeType);

/// Lets the user pick a file with [extension]; null when they cancel.
typedef BackupFilePicker = Future<Uint8List?> Function(String extension);

/// Settings › Privacy & Data › Backup and restore: one file with events,
/// categories, notes, custom holidays and holiday reminder choices; restore
/// by merging or replacing; and events to and from .ics calendar files.
class BackupPage extends StatefulWidget {
  const BackupPage({
    super.key,
    this.database,
    this.saveFile,
    this.pickFile,
    this.today,
  });

  /// The app database when null.
  final AppDatabase? database;
  final BackupFileSaver? saveFile;
  final BackupFilePicker? pickFile;

  /// For file names; now when null.
  final DateTime? today;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false;

  AppDatabase get _db => widget.database ?? GetIt.instance<AppDatabase>();

  static bool get _phone =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _save(Uint8List bytes, String name, String mimeType) async {
    if (widget.saveFile case final save?) return save(bytes, name, mimeType);
    if (_phone) {
      await SharePlus.instance.share(
        ShareParams(
          subject: name,
          files: [XFile.fromData(bytes, mimeType: mimeType, name: name)],
          fileNameOverrides: [name],
        ),
      );
    } else {
      await FilePicker.platform.saveFile(fileName: name, bytes: bytes);
    }
  }

  Future<Uint8List?> _pick(String extension) async {
    if (widget.pickFile case final pick?) return pick(extension);
    // Phone pickers can't filter by an unregistered extension.
    final result = await FilePicker.platform.pickFiles(
      type: _phone ? FileType.any : FileType.custom,
      allowedExtensions: _phone ? null : [extension],
      withData: true,
    );
    return result?.files.single.bytes;
  }

  String get _stamp {
    final d = widget.today ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } on BackupFormatException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      context.showToast(
        e.newerVersion ? l10n.backupNewer : l10n.backupNotABackup,
        kind: AppToastKind.error,
      );
    } on Object catch (e) {
      debugPrint('Backup failed: $e');
      if (mounted) {
        context.showToast(
          AppLocalizations.of(context)!.backupFailed,
          kind: AppToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backUp() => _run(() async {
    final bytes = await AppBackup(
      _db,
    ).export(settings: {'holidayReminders': ?holidayReminders?.toBackup()});
    await _save(
      Uint8List.fromList(bytes),
      'myanmar-calendar-$_stamp.${AppBackup.extension}',
      'application/json',
    );
  });

  Future<void> _exportIcs() => _run(() async {
    final ics = await EventsIcs.fromDatabase(_db);
    await _save(
      Uint8List.fromList(utf8.encode(ics)),
      'myanmar-calendar-events-$_stamp.${EventsIcs.extension}',
      EventsIcs.mimeType,
    );
  });

  Future<void> _restore() => _run(() async {
    final bytes = await _pick(AppBackup.extension);
    if (bytes == null || !mounted) return;
    final file = AppBackup.read(bytes);
    final replace = await _askHow(file);
    if (replace == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (replace &&
        !await showAppConfirm(
          context: context,
          title: l10n.backupReplaceConfirm,
          confirmLabel: l10n.backupReplace,
          cancelLabel: l10n.cancel,
          destructive: true,
        )) {
      return;
    }
    await AppBackup(_db).restore(file, replace: replace);
    if (file.settings['holidayReminders'] case final Map<String, Object?> r) {
      await holidayReminders?.restoreBackup(r);
    }
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SmartNotificationScheduler>()) {
      await getIt<SmartNotificationScheduler>().rescheduleAllNotifications();
    }
    if (mounted) {
      context.showToast(l10n.backupRestored, kind: AppToastKind.success);
    }
  });

  /// Adds the events of an .ics file from another calendar.
  Future<void> _importIcs() => _run(() async {
    final bytes = await _pick(EventsIcs.extension);
    if (bytes == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final IcsCalendar calendar;
    try {
      calendar = IcsImport.parse(utf8.decode(bytes, allowMalformed: true));
    } on FormatException {
      context.showToast(l10n.icsNotACalendar, kind: AppToastKind.error);
      return;
    }
    if (calendar.events.isEmpty) {
      context.showToast(l10n.icsNoEvents, kind: AppToastKind.error);
      return;
    }
    final notes = [
      if (calendar.simplified > 0) l10n.icsSimplified(calendar.simplified),
      if (calendar.skipped > 0) l10n.icsSkipped(calendar.skipped),
    ];
    final yes = await showAppConfirm(
      context: context,
      title: l10n.icsImportQuestion(calendar.events.length),
      message: notes.isEmpty ? null : notes.join('\n'),
      confirmLabel: l10n.icsImportConfirm,
      cancelLabel: l10n.cancel,
    );
    if (!yes) return;
    final added = await IcsImport.importInto(_db, calendar);
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SmartNotificationScheduler>()) {
      await getIt<SmartNotificationScheduler>().rescheduleAllNotifications();
    }
    if (mounted) {
      context.showToast(l10n.icsImported(added), kind: AppToastKind.success);
    }
  });

  /// Shows what [file] holds; true to replace, false to merge, null to
  /// cancel.
  Future<bool?> _askHow(BackupFile file) {
    final l10n = AppLocalizations.of(context)!;
    final format = context.calendarFormat;
    final s = file.summary;
    String n(int v) => context.uiNumber(v);
    return showAppSheet<bool>(
      context: context,
      title: l10n.backupRestoreTitle,
      cancelLabel: l10n.cancel,
      useRootNavigator: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppGroup(
              footer: l10n.backupMadeOn(
                '${format.dayMonth(file.createdAt)} '
                '${format.westernNumber(file.createdAt.year)}',
              ),
              children: [
                AppRow(title: l10n.events, value: n(s.events)),
                AppRow(title: l10n.notesTitle, value: n(s.notes)),
                AppRow(title: l10n.categories, value: n(s.categories)),
                AppRow(
                  title: l10n.backupCustomHolidays,
                  value: n(s.customHolidays),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppGroup(
              children: [
                AppRow(
                  key: const ValueKey('backup-merge'),
                  title: l10n.backupMerge,
                  subtitle: l10n.backupMergeSubtitle,
                  tone: AppRowTone.accent,
                  onTap: () => Navigator.of(sheetContext).pop(false),
                ),
                AppRow(
                  key: const ValueKey('backup-replace'),
                  title: l10n.backupReplace,
                  subtitle: l10n.backupReplaceSubtitle,
                  tone: AppRowTone.destructive,
                  onTap: () => Navigator.of(sheetContext).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      title: l10n.backupTitle,
      previousTitle: l10n.privacyAndData,
      largeTitle: false,
      children: [
        AppGroup(
          footer: l10n.backupFooter,
          children: [
            AppRow(
              key: const ValueKey('backup-now'),
              icon: Icons.cloud_upload_outlined,
              iconColor: const Color(0xFF2F9E5B),
              title: l10n.backupNow,
              onTap: _busy ? null : _backUp,
            ),
            AppRow(
              key: const ValueKey('backup-restore'),
              icon: Icons.settings_backup_restore_rounded,
              iconColor: const Color(0xFF4C5BD4),
              title: l10n.backupRestore,
              onTap: _busy ? null : _restore,
            ),
          ],
        ),
        AppGroup(
          footer: l10n.backupIcsFooter,
          children: [
            AppRow(
              key: const ValueKey('backup-ics'),
              icon: Icons.event_available_outlined,
              iconColor: const Color(0xFFF08A1C),
              title: l10n.backupIcs,
              onTap: _busy ? null : _exportIcs,
            ),
            AppRow(
              key: const ValueKey('backup-ics-import'),
              icon: Icons.event_note_outlined,
              iconColor: const Color(0xFF8E6CEF),
              title: l10n.icsImport,
              onTap: _busy ? null : _importIcs,
            ),
          ],
        ),
        if (_busy) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
