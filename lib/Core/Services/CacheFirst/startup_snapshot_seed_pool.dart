import 'package:get/get.dart';

import 'cache_scope_namespace.dart';
import 'startup_snapshot_shard_store.dart';

class StartupSnapshotSeedPool extends GetxService {
  static const Duration defaultFreshWindow = Duration(hours: 2);

  final Map<String, StartupSnapshotShardRecord> _records =
      <String, StartupSnapshotShardRecord>{};

  StartupSnapshotShardRecord? load({
    required String surface,
    String? userId,
    Duration? maxAge,
  }) {
    final normalizedSurface = surface.trim();
    if (normalizedSurface.isEmpty) return null;
    final record = _records[_storageKey(surface: normalizedSurface, userId: userId)];
    if (record == null) return null;
    final maxAllowedAge = maxAge ?? defaultFreshWindow;
    final ageMs = DateTime.now().millisecondsSinceEpoch - record.savedAtMs;
    if (ageMs < 0 || ageMs > maxAllowedAge.inMilliseconds) {
      clear(surface: normalizedSurface, userId: userId);
      return null;
    }
    return record;
  }

  void save({
    required String surface,
    String? userId,
    required int itemCount,
    required int limit,
    required String source,
    required Map<String, dynamic> payload,
    DateTime? snapshotAt,
  }) {
    final normalizedSurface = surface.trim();
    if (normalizedSurface.isEmpty) return;
    final now = DateTime.now();
    final record = StartupSnapshotShardRecord(
      schemaVersion: StartupSnapshotShardStore.schemaVersion,
      actorId: _normalizeActorId(userId),
      surface: normalizedSurface,
      savedAtMs: now.millisecondsSinceEpoch,
      snapshotAtMs: (snapshotAt ?? now).millisecondsSinceEpoch,
      itemCount: itemCount < 0 ? 0 : itemCount,
      limit: limit < 0 ? 0 : limit,
      source: source.trim().isEmpty ? 'memorySeed' : source.trim(),
      payload: payload,
    );
    if (!record.isValid) return;
    _records[_storageKey(surface: normalizedSurface, userId: userId)] = record;
  }

  void clear({
    required String surface,
    String? userId,
  }) {
    final normalizedSurface = surface.trim();
    if (normalizedSurface.isEmpty) return;
    _records.remove(_storageKey(surface: normalizedSurface, userId: userId));
  }

  String _storageKey({
    required String surface,
    String? userId,
  }) {
    return '${_normalizeActorId(userId)}::${surface.trim()}';
  }

  String _normalizeActorId(String? userId) {
    final normalized = userId?.trim() ?? '';
    if (normalized.isEmpty) return CacheScopeNamespace.guestActorId;
    return normalized;
  }
}

StartupSnapshotSeedPool? maybeFindStartupSnapshotSeedPool() {
  if (!Get.isRegistered<StartupSnapshotSeedPool>()) return null;
  return Get.find<StartupSnapshotSeedPool>();
}

StartupSnapshotSeedPool ensureStartupSnapshotSeedPool() {
  final existing = maybeFindStartupSnapshotSeedPool();
  if (existing != null) return existing;
  return Get.put(StartupSnapshotSeedPool(), permanent: true);
}
