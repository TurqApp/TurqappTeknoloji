import 'dart:collection';

import 'scoped_snapshot_store.dart';

class MemoryScopedSnapshotStore<T> implements ScopedSnapshotStore<T> {
  MemoryScopedSnapshotStore({
    this.maxEntries = 96,
  });

  final int maxEntries;
  final LinkedHashMap<String, _MemoryScopedSnapshotEntry<T>> _entries =
      LinkedHashMap<String, _MemoryScopedSnapshotEntry<T>>();

  @override
  Future<ScopedSnapshotRecord<T>?> read(
    ScopedSnapshotKey key, {
    bool allowStale = true,
  }) async {
    final storageKey = key.storageKey;
    final entry = _entries.remove(storageKey);
    if (entry == null) return null;
    _entries[storageKey] = entry;
    return entry.record;
  }

  @override
  Future<void> write(
    ScopedSnapshotKey key,
    ScopedSnapshotRecord<T> record,
  ) async {
    final storageKey = key.storageKey;
    _entries.remove(storageKey);
    _entries[storageKey] = _MemoryScopedSnapshotEntry<T>(
      key: key,
      record: record,
    );
    _trimToLimit();
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

  void _trimToLimit() {
    if (maxEntries <= 0) {
      _entries.clear();
      return;
    }
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
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
