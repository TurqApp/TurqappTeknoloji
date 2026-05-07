import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/CacheFirst/memory_scoped_snapshot_store.dart';
import 'package:turqappv2/Core/Services/CacheFirst/scoped_snapshot_store.dart';

void main() {
  test('memory scoped snapshot store evicts least recently used entries',
      () async {
    final store = MemoryScopedSnapshotStore<String>(maxEntries: 2);

    ScopedSnapshotKey key(String scopeId) => ScopedSnapshotKey(
          surfaceKey: 'feed',
          userId: 'user',
          scopeId: scopeId,
        );

    ScopedSnapshotRecord<String> record(String data) => ScopedSnapshotRecord(
          data: data,
          snapshotAt: DateTime.fromMillisecondsSinceEpoch(1),
          schemaVersion: 1,
          generationId: 'test',
          source: CachedResourceSource.memory,
        );

    await store.write(key('a'), record('a'));
    await store.write(key('b'), record('b'));
    expect((await store.read(key('a')))?.data, 'a');

    await store.write(key('c'), record('c'));

    expect(await store.read(key('b')), isNull);
    expect((await store.read(key('a')))?.data, 'a');
    expect((await store.read(key('c')))?.data, 'c');
  });
}
