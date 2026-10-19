import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart';

void main() {
  test(
    'Calendar Studio templates persist with previews, update and delete',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final templates = CalendarStudioTemplateDatabase(database);
      final older = DateTime.utc(2027, 1);
      final newer = DateTime.utc(2027, 2);

      await templates.save(
        id: 'a',
        name: 'Gold wall',
        formatVersion: 1,
        documentJson: '{"id":"a"}',
        preview: Uint8List.fromList([1, 2, 3]),
        createdAt: older,
        updatedAt: older,
      );
      await templates.save(
        id: 'b',
        name: 'Story',
        formatVersion: 1,
        documentJson: '{"id":"b"}',
        createdAt: newer,
        updatedAt: newer,
      );

      var rows = await templates.list();
      expect(rows.map((row) => row.id), ['b', 'a']);
      expect(rows.last.preview, [1, 2, 3]);
      expect(rows.first.preview, isNull);

      await templates.save(
        id: 'a',
        name: 'Renamed',
        formatVersion: 1,
        documentJson: '{"id":"a"}',
        createdAt: older,
        updatedAt: DateTime.utc(2027, 3),
      );
      rows = await templates.list();
      expect(rows.map((row) => row.name), ['Renamed', 'Story']);

      await templates.delete('b');
      expect((await templates.list()).map((row) => row.id), ['a']);
    },
  );
}
