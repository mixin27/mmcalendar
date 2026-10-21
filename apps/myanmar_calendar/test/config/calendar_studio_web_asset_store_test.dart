import 'dart:convert';
import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmcalendar/config/calendar_studio_web_asset_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryBytes implements StudioAssetBytes {
  final values = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String id) async => values[id];

  @override
  Future<void> write(String id, Uint8List bytes) async => values[id] = bytes;

  @override
  Future<void> delete(String id) async => values.remove(id);
}

void main() {
  late _MemoryBytes bytes;

  Future<WebCalendarStudioAssetStore> store([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    bytes = _MemoryBytes();
    return WebCalendarStudioAssetStore(
      await SharedPreferences.getInstance(),
      bytes,
    );
  }

  // localStorage holds about 5 MB per site; base64 photos there made every
  // web image import fail.
  test('image bytes stay out of preferences', () async {
    final assets = await store();
    final photo = Uint8List(4 << 20);
    final asset = await assets.importAsset(
      CalendarStudioAssetInput(
        name: 'photo.jpg',
        bytes: photo,
        width: 4000,
        height: 3000,
      ),
    );

    final preferences = await SharedPreferences.getInstance();
    final manifest = preferences.getString(
      WebCalendarStudioAssetStore.manifestKey,
    )!;
    expect(manifest.length, lessThan(200));
    expect(await assets.loadBytes(asset.id), photo);
    expect((await assets.load(asset.id))!.width, 4000);
  });

  test('images saved by earlier releases move out of preferences', () async {
    final assets = await store({
      WebCalendarStudioAssetStore.legacyKey: jsonEncode({
        'old': {
          'name': 'logo.png',
          'bytes': base64Encode([1, 2, 3]),
          'width': 10,
          'height': 20,
        },
      }),
    });

    expect(await assets.loadBytes('old'), [1, 2, 3]);
    expect((await assets.load('old'))!.name, 'logo.png');
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.containsKey(WebCalendarStudioAssetStore.legacyKey),
      isFalse,
    );
  });

  test('unused images are deleted with their bytes', () async {
    final assets = await store();
    Future<String> add() async => (await assets.importAsset(
      CalendarStudioAssetInput(
        name: 'a.png',
        bytes: Uint8List(1),
        width: 1,
        height: 1,
      ),
    )).id;
    final kept = await add();
    final dropped = await add();

    await assets.deleteUnusedAssets({kept});

    expect(bytes.values.keys, [kept]);
    expect(await assets.load(dropped), isNull);
  });
}
