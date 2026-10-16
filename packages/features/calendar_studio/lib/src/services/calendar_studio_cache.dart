import 'dart:typed_data';

import 'package:flutter/foundation.dart' show SynchronousFuture;

import '../models/calendar_studio_types.dart';
import 'calendar_studio_contracts.dart';

/// Memoizes [CalendarStudioDataProvider.daysFor] per source and month so
/// rebuilds (drags, zoom, thumbnails) never recompute calendar data.
///
/// Completed months are readable synchronously through [peek], which lets
/// grids paint on the first frame without a `FutureBuilder` flicker.
class CachedCalendarStudioDataProvider implements CalendarStudioDataProvider {
  CachedCalendarStudioDataProvider(this.delegate, {this.maxEntries = 96});

  final CalendarStudioDataProvider delegate;
  final int maxEntries;
  final _pending = <_DaysKey, Future<List<CalendarStudioDayData>>>{};
  final _resolved = <_DaysKey, List<CalendarStudioDayData>>{};

  List<CalendarStudioDayData>? peek(
    CalendarStudioSource source, {
    required int month,
  }) {
    final key = _DaysKey(source, month);
    final value = _resolved.remove(key);
    if (value != null) _resolved[key] = value;
    return value;
  }

  @override
  Future<List<CalendarStudioDayData>> daysFor(
    CalendarStudioSource source, {
    required int month,
  }) {
    final key = _DaysKey(source, month);
    if (peek(source, month: month) case final days?) {
      return SynchronousFuture(days);
    }
    return _pending[key] ??= delegate
        .daysFor(source, month: month)
        .then((days) {
          _pending.remove(key);
          _resolved[key] = days;
          while (_resolved.length > maxEntries) {
            _resolved.remove(_resolved.keys.first);
          }
          return days;
        })
        .catchError((Object error) {
          _pending.remove(key);
          throw error;
        });
  }

  /// Resolves every month in [months] ahead of the first paint.
  Future<void> warm(CalendarStudioSource source, Iterable<int> months) =>
      Future.wait([for (final month in months) daysFor(source, month: month)]);
}

class _DaysKey {
  const _DaysKey(this.source, this.month);
  final CalendarStudioSource source;
  final int month;

  @override
  bool operator ==(Object other) =>
      other is _DaysKey && other.source == source && other.month == month;

  @override
  int get hashCode => Object.hash(source, month);
}

/// Keeps recently used asset bytes in memory as stable [Uint8List] instances,
/// so `MemoryImage` keys stay identical and images decode once.
class CachedCalendarStudioAssetStore implements CalendarStudioAssetStore {
  CachedCalendarStudioAssetStore(this.delegate, {this.maxBytes = 96 << 20});

  final CalendarStudioAssetStore delegate;
  final int maxBytes;
  final _bytes = <String, Uint8List>{};
  final _pending = <String, Future<Uint8List?>>{};
  var _size = 0;

  Uint8List? peekBytes(String assetId) {
    final value = _bytes.remove(assetId);
    if (value != null) _bytes[assetId] = value;
    return value;
  }

  @override
  Future<Uint8List?> loadBytes(String assetId) {
    if (peekBytes(assetId) case final bytes?) return SynchronousFuture(bytes);
    return _pending[assetId] ??= delegate.loadBytes(assetId).then((raw) {
      _pending.remove(assetId);
      if (raw == null || raw.isEmpty) return null;
      final bytes = raw is Uint8List ? raw : Uint8List.fromList(raw);
      _put(assetId, bytes);
      return bytes;
    });
  }

  void _put(String assetId, Uint8List bytes) {
    final previous = _bytes.remove(assetId);
    if (previous != null) _size -= previous.lengthInBytes;
    _bytes[assetId] = bytes;
    _size += bytes.lengthInBytes;
    while (_size > maxBytes && _bytes.length > 1) {
      final oldest = _bytes.keys.first;
      _size -= _bytes.remove(oldest)!.lengthInBytes;
    }
  }

  @override
  Future<CalendarStudioAsset> importAsset(CalendarStudioAssetInput input) =>
      delegate.importAsset(input);

  @override
  Future<CalendarStudioAsset?> load(String assetId) => delegate.load(assetId);

  @override
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds) {
    _bytes.removeWhere((id, bytes) {
      if (usedAssetIds.contains(id)) return false;
      _size -= bytes.lengthInBytes;
      return true;
    });
    return delegate.deleteUnusedAssets(usedAssetIds);
  }
}
