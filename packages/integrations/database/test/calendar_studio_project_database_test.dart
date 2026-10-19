import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart';

void main() {
  test('Calendar Studio projects persist, order, update, and delete', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final projects = CalendarStudioProjectDatabase(database);
    final older = DateTime.utc(2027, 1);
    final newer = DateTime.utc(2027, 2);

    await projects.save(
      id: 'older',
      name: 'Older project',
      templateId: 'jade-wall',
      documentSchemaVersion: 2,
      documentJson: '{"id":"older"}',
      createdAt: older,
      updatedAt: older,
    );
    await projects.save(
      id: 'newer',
      name: 'Newer project',
      templateId: 'story',
      documentSchemaVersion: 2,
      documentJson: '{"id":"newer"}',
      createdAt: newer,
      updatedAt: newer,
    );

    expect((await projects.list()).map((row) => row.id), ['newer', 'older']);

    await projects.save(
      id: 'older',
      name: 'Renamed project',
      templateId: 'jade-wall',
      documentSchemaVersion: 3,
      documentJson: '{"id":"older","version":3}',
      createdAt: older,
      updatedAt: DateTime.utc(2027, 3),
    );
    final updated = await projects.load('older');
    expect(updated?.name, 'Renamed project');
    expect(updated?.documentSchemaVersion, 3);

    await projects.delete('older');
    expect(await projects.load('older'), isNull);

    await database.close();
  });
}
