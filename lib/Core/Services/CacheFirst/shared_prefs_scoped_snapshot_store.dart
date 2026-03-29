import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cache_first_serialization.dart';
import 'cached_resource.dart';
import 'scoped_snapshot_store.dart';

class SharedPrefsScopedSnapshotStore<T> implements ScopedSnapshotStore<T> {
  SharedPrefsScopedSnapshotStore({
    required this.prefsPrefix,
    required this.encode,
    required this.decode,
  });

  final String prefsPrefix;
  final SnapshotEncoder<T> encode;
  final SnapshotDecoder<T> decode;

  SharedPreferences? _prefs;

  @override
  Future<ScopedSnapshotRecord<T>?> read(
    ScopedSnapshotKey key, {
    bool allowStale = true,
  }) async {
    final prefsKey = _prefsKey(key);
    try {
      final prefs = await _ensurePrefs();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await prefs.remove(prefsKey);
        return null;
      }
      final payload =
          Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
      final snapshotAtMs = (payload['snapshotAt'] as num?)?.toInt() ?? 0;
      final schemaVersion = (payload['schemaVersion'] as num?)?.toInt() ?? 1;
      final generationId = (payload['generationId'] ?? '').toString().trim();
      final source = _parseSource(payload['source']);
      final dataMap = payload['data'];
      if (snapshotAtMs <= 0 || dataMap is! Map) {
        await prefs.remove(prefsKey);
        return null;
      }
      return ScopedSnapshotRecord<T>(
        data:
            decode(Map<String, dynamic>.from(dataMap.cast<dynamic, dynamic>())),
        snapshotAt: DateTime.fromMillisecondsSinceEpoch(snapshotAtMs),
        schemaVersion: schemaVersion,
        generationId: generationId,
        source: source,
      );
    } catch (_) {
      try {
        final prefs = await _ensurePrefs();
        await prefs.remove(prefsKey);
      } catch (_) {}
      return null;
    }
  }

  @override
  Future<void> write(
    ScopedSnapshotKey key,
    ScopedSnapshotRecord<T> record,
  ) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _prefsKey(key),
      jsonEncode(<String, dynamic>{
        'surfaceKey': key.surfaceKey,
        'userId': key.userId,
        'scopeId': key.scopeId,
        'snapshotAt': record.snapshotAt.millisecondsSinceEpoch,
        'schemaVersion': record.schemaVersion,
        'generationId': record.generationId,
        'source': record.source.name,
        'data': encode(record.data),
      }),
    );
  }

  @override
  Future<void> clearScope(ScopedSnapshotKey key) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_prefsKey(key));
  }

  @override
  Future<void> clearSurface(
    String surfaceKey, {
    String? userId,
  }) async {
    final prefs = await _ensurePrefs();
    final normalizedSurface = surfaceKey.trim();
    final normalizedUser = (userId ?? '').trim();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('$prefsPrefix:'))
        .toList(growable: false);
    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) {
        await prefs.remove(key);
        continue;
      }
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          await prefs.remove(key);
          continue;
        }
        final payload =
            Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
        final storedSurface = (payload['surfaceKey'] ?? '').toString().trim();
        final storedUser = (payload['userId'] ?? '').toString().trim();
        if (storedSurface != normalizedSurface) continue;
        if (normalizedUser.isNotEmpty && storedUser != normalizedUser) {
          continue;
        }
        await prefs.remove(key);
      } catch (_) {
        await prefs.remove(key);
      }
    }
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String _prefsKey(ScopedSnapshotKey key) => '$prefsPrefix:${key.storageKey}';

  CachedResourceSource _parseSource(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    for (final source in CachedResourceSource.values) {
      if (source.name == value) return source;
    }
    return CachedResourceSource.scopedDisk;
  }
}
