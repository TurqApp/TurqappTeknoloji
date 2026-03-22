import 'scoped_snapshot_store.dart';

class MemoryScopedSnapshotStore<T> implements ScopedSnapshotStore<T> {
  final Map<String, _MemoryScopedSnapshotEntry<T>> _entries =
      <String, _MemoryScopedSnapshotEntry<T>>{};

  @override
  Future<ScopedSnapshotRecord<T>?> read(
    ScopedSnapshotKey key, {
    bool allowStale = true,
  }) async {
    return _entries[key.storageKey]?.record;
  }

  @override
  Future<void> write(
    ScopedSnapshotKey key,
    ScopedSnapshotRecord<T> record,
  ) async {
    _entries[key.storageKey] = _MemoryScopedSnapshotEntry<T>(
      key: key,
      record: record,
    );
  }

  @override
  Future<void> clearScope(ScopedSnapshotKey key) async {
    _entries.remove(key.storageKey);
  }

  @override
  Future<void> clearSurface(
    String surfaceKey, {
    String? userId,
  }) async {
    final normalizedSurface = surfaceKey.trim();
    final normalizedUser = (userId ?? '').trim();
    _entries.removeWhere((_, entry) {
      if (entry.key.surfaceKey.trim() != normalizedSurface) {
        return false;
      }
      if (normalizedUser.isEmpty) {
        return true;
      }
      return entry.key.userId.trim() == normalizedUser;
    });
  }
}

class _MemoryScopedSnapshotEntry<T> {
  const _MemoryScopedSnapshotEntry({
    required this.key,
    required this.record,
  });

  final ScopedSnapshotKey key;
  final ScopedSnapshotRecord<T> record;
}

