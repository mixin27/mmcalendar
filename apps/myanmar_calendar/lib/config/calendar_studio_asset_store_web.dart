import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import 'calendar_studio_web_asset_store.dart';

CalendarStudioAssetStore createCalendarStudioAssetStore(
  SharedPreferences preferences,
) => WebCalendarStudioAssetStore(preferences, _IndexedDbAssetBytes());

/// Image bytes in IndexedDB, which allows far more than localStorage and
/// stores the bytes as they are, without base64.
class _IndexedDbAssetBytes implements StudioAssetBytes {
  static const _databaseName = 'calendar_studio_assets';
  static const _storeName = 'bytes';
  Future<web.IDBDatabase>? _database;

  Future<web.IDBDatabase> _open() => _database ??= () {
    final request = web.window.indexedDB.open(_databaseName, 1);
    request.onupgradeneeded = (web.Event _) {
      (request.result! as web.IDBDatabase).createObjectStore(_storeName);
    }.toJS;
    return _result(request).then((value) => value! as web.IDBDatabase);
  }();

  Future<web.IDBObjectStore> _store(String mode) async => (await _open())
      .transaction(_storeName.toJS, mode)
      .objectStore(_storeName);

  static Future<JSAny?> _result(web.IDBRequest request) {
    final completer = Completer<JSAny?>();
    request.onsuccess = (web.Event _) {
      completer.complete(request.result);
    }.toJS;
    request.onerror = (web.Event _) {
      completer.completeError(
        StateError('IndexedDB: ${request.error?.message ?? 'request failed'}'),
      );
    }.toJS;
    return completer.future;
  }

  @override
  Future<Uint8List?> read(String id) async {
    final value = await _result((await _store('readonly')).get(id.toJS));
    return (value as JSUint8Array?)?.toDart;
  }

  @override
  Future<void> write(String id, Uint8List bytes) async {
    await _result((await _store('readwrite')).put(bytes.toJS, id.toJS));
  }

  @override
  Future<void> delete(String id) async {
    await _result((await _store('readwrite')).delete(id.toJS));
  }
}
