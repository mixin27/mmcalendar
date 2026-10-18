import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' show AppTokens;

import '../datasources/widget_local_datasource.dart';
import '../payload/widget_palettes.dart';

/// Keeps the widgets current while the app runs: rewrites their data when
/// the app's colours or the next two weeks of events change.
class WidgetSync {
  WidgetSync(this._dataSource, {EventMarkersPort? events})
    : _eventsPort = events;

  final WidgetLocalDataSource _dataSource;
  final EventMarkersPort? _eventsPort;
  StreamSubscription<Object?>? _events;
  Timer? _debounce;
  String? _palette;

  /// Starts watching events. Safe to call more than once.
  void start() {
    final port = _eventsPort;
    if (port == null || _events != null) return;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    _events = port
        .watchEventMarkers(
          startDate: start,
          endDate: start.add(const Duration(days: 14)),
        )
        // The first value is what was just written at startup.
        .skip(1)
        .listen((_) => schedule());
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
    _debounce?.cancel();
    _events?.cancel();
  }
}
