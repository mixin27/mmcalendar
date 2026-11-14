import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' show AppTokens;

import '../datasources/widget_local_datasource.dart';
import '../payload/widget_palettes.dart';
import 'widget_actions.dart';

/// Keeps the widgets current while the app runs: rewrites their data when
/// the app's colours, the next two weeks of events or of notes change, and
/// applies events ticked done on the widgets ([applyWidgetTicks]) at start
/// and whenever the app comes back.
class WidgetSync {
  WidgetSync(this._dataSource, {EventMarkersPort? events, DayNotesPort? notes})
    : _eventsPort = events,
      _notesPort = notes;

  final WidgetLocalDataSource _dataSource;
  final EventMarkersPort? _eventsPort;
  final DayNotesPort? _notesPort;
  StreamSubscription<Object?>? _events;
  StreamSubscription<Object?>? _notes;
  Timer? _debounce;
  String? _palette;
  AppLifecycleListener? _lifecycle;
  Future<void>? _applying;

  /// Starts watching events and notes. Safe to call more than once.
  void start() {
    unawaited(applyWidgetTicks());
    _lifecycle ??= AppLifecycleListener(
      onResume: () => unawaited(applyWidgetTicks()),
    );
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final notes = _notesPort;
    if (notes != null && _notes == null) {
      _notes = notes
          .watchNotePreviews(start, start.add(const Duration(days: 14)))
          .skip(1)
          .listen((_) => schedule());
    }
    final port = _eventsPort;
    if (port == null || _events != null) return;
    _events = port
        .watchEventMarkers(
          startDate: start,
          endDate: start.add(const Duration(days: 14)),
        )
        // The first value is what was just written at startup.
        .skip(1)
        .listen((_) => schedule());
  }

  /// Saves the events ticked done on the widgets (see [WidgetActions]),
  /// then rewrites the widgets' data. One run at a time.
  Future<void> applyWidgetTicks() {
    final port = _eventsPort;
    if (port == null) return Future.value();
    return _applying ??= () async {
      try {
        // The events stream would also notice, but its first value after
        // start is skipped, so rewrite here.
        if (await WidgetActions.applyWith(port) > 0) schedule();
      } catch (e) {
        debugPrint('Widget ticks not applied: $e');
      } finally {
        _applying = null;
      }
    }();
  }

  /// The app's colours changed (style, mode, preset or custom colours):
  /// "Follow app" widgets pick them up.
  Future<void> updateAppPalette(AppTokens light, AppTokens dark) async {
    final lightPalette = WidgetPalette.fromTokens(light);
    final darkPalette = WidgetPalette.fromTokens(dark);
    final key = jsonEncode([lightPalette.toJson(), darkPalette.toJson()]);
    if (key == _palette) return;
    final first = _palette == null;
    _palette = key;
    await _dataSource.saveAppPalette(lightPalette, darkPalette);
    // The startup write already used the saved palette.
    if (!first) schedule();
  }

  /// Rewrites the widgets' data soon, once changes settle.
  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        await _dataSource.writePayload();
      } catch (e) {
        debugPrint('Widget sync failed: $e');
      }
    });
  }

  void dispose() {
    _lifecycle?.dispose();
    _debounce?.cancel();
    _events?.cancel();
    _notes?.cancel();
  }
}
