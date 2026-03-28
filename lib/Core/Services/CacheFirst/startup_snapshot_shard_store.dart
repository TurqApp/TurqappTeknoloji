import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cache_scope_namespace.dart';

class StartupSnapshotShardRecord {
  const StartupSnapshotShardRecord({
    required this.schemaVersion,
    required this.actorId,
    required this.surface,
    required this.savedAtMs,
    required this.snapshotAtMs,
    required this.itemCount,
    required this.limit,
    required this.source,
    required this.payload,
  });

  final int schemaVersion;
  final String actorId;
  final String surface;
  final int savedAtMs;
  final int snapshotAtMs;
  final int itemCount;
  final int limit;
  final String source;
  final Map<String, dynamic> payload;

  DateTime? get snapshotAt => snapshotAtMs <= 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(snapshotAtMs);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'actorId': actorId,
      'surface': surface,
      'savedAtMs': savedAtMs,
      'snapshotAtMs': snapshotAtMs,
      'itemCount': itemCount,
      'limit': limit,
      'source': source,
      'payload': payload,
    };
  }

  factory StartupSnapshotShardRecord.fromJson(Map<String, dynamic> json) {
    final rawPayload = Map<String, dynamic>.from(
      json['payload'] as Map? ?? const <String, dynamic>{},
    );
    return StartupSnapshotShardRecord(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      actorId: (json['actorId'] ?? CacheScopeNamespace.guestActorId)
          .toString()
          .trim(),
      surface: (json['surface'] ?? '').toString().trim(),
      savedAtMs: (json['savedAtMs'] as num?)?.toInt() ?? 0,
      snapshotAtMs: (json['snapshotAtMs'] as num?)?.toInt() ?? 0,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      source: (json['source'] ?? 'scopedDisk').toString().trim(),
      payload: _sanitizePayloadMap(rawPayload),
    );
  }
}

class StartupSnapshotShardStore extends GetxService {
  static const int schemaVersion = 1;
  static const String _keyPrefix = 'startup_snapshot_shard_v1';
  static const int _maxSerializedChars = 220000;
  static const Duration defaultFreshWindow = Duration(hours: 18);

  SharedPreferences? _prefs;

  Future<SharedPreferences> _prefsInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<StartupSnapshotShardRecord?> load({
    required String surface,
    String? userId,
    Duration? maxAge,
  }) async {
    final normalizedSurface = surface.trim();
    if (normalizedSurface.isEmpty) return null;
    try {
      final prefs = await _prefsInstance();
      final raw = prefs.getString(
        _storageKey(
          userId: userId,
          surface: normalizedSurface,
        ),
      );
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final record = StartupSnapshotShardRecord.fromJson(
        Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>()),
      );
      if (record.schemaVersion != schemaVersion ||
          record.surface != normalizedSurface) {
        await clear(
          surface: normalizedSurface,
          userId: userId,
        );
        return null;
      }
      final maxAllowedAge = maxAge ?? defaultFreshWindow;
      if (_isExpired(record, maxAllowedAge)) {
        await clear(
          surface: normalizedSurface,
          userId: userId,
        );
        return null;
      }
      return record;
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required String surface,
    String? userId,
    required int itemCount,
    required int limit,
    required String source,
    required Map<String, dynamic> payload,
    DateTime? snapshotAt,
  }) async {
    final normalizedSurface = surface.trim();
    if (normalizedSurface.isEmpty) return;
    final sanitizedPayload = _sanitizePayloadMap(payload);
    if (sanitizedPayload.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final snapshotAtMs =
        (snapshotAt ?? DateTime.fromMillisecondsSinceEpoch(nowMs))
            .millisecondsSinceEpoch;
    final record = StartupSnapshotShardRecord(
      schemaVersion: schemaVersion,
      actorId: _normalizeActorId(userId),
      surface: normalizedSurface,
      savedAtMs: nowMs,
      snapshotAtMs: snapshotAtMs,
      itemCount: itemCount < 0 ? 0 : itemCount,
      limit: limit < 0 ? 0 : limit,
      source: source.trim().isEmpty ? 'scopedDisk' : source.trim(),
      payload: sanitizedPayload,
    );

    try {
      final prefs = await _prefsInstance();
      final storageKey = _storageKey(
        userId: userId,
        surface: normalizedSurface,
      );
      final encoded = jsonEncode(record.toJson());
      if (encoded.length > _maxSerializedChars) {
        await prefs.remove(storageKey);
        return;
      }
      await prefs.setString(storageKey, encoded);
    } catch (_) {}
  }

  Future<void> clear({
    required String surface,
    String? userId,
  }) async {
    final normalizedSurface = surface.trim();
    if (normalizedSurface.isEmpty) return;
    try {
      final prefs = await _prefsInstance();
      await prefs.remove(
        _storageKey(
          userId: userId,
          surface: normalizedSurface,
        ),
      );
    } catch (_) {}
  }

  String _storageKey({
    required String surface,
    String? userId,
  }) {
    return '$_keyPrefix::${_normalizeActorId(userId)}::${surface.trim()}';
  }

  String _normalizeActorId(String? userId) {
    final normalized = userId?.trim() ?? '';
    if (normalized.isEmpty) return CacheScopeNamespace.guestActorId;
    return normalized;
  }

  bool _isExpired(
    StartupSnapshotShardRecord record,
    Duration maxAge,
  ) {
    if (record.savedAtMs <= 0) return true;
    final ageMs = DateTime.now().millisecondsSinceEpoch - record.savedAtMs;
    if (ageMs < 0) return true;
    return ageMs > maxAge.inMilliseconds;
  }
}

StartupSnapshotShardStore? maybeFindStartupSnapshotShardStore() {
  final isRegistered = Get.isRegistered<StartupSnapshotShardStore>();
  if (!isRegistered) return null;
  return Get.find<StartupSnapshotShardStore>();
}

StartupSnapshotShardStore ensureStartupSnapshotShardStore() {
  final existing = maybeFindStartupSnapshotShardStore();
  if (existing != null) return existing;
  return Get.put(StartupSnapshotShardStore(), permanent: true);
}

Map<String, dynamic> _sanitizePayloadMap(Map<String, dynamic> raw) {
  final sanitized = <String, dynamic>{};
  raw.forEach((key, value) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) return;
    sanitized[normalizedKey] = _sanitizePayloadValue(value);
  });
  return sanitized;
}

Object? _sanitizePayloadValue(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is Map) {
    return _sanitizePayloadMap(
      Map<String, dynamic>.from(value.cast<dynamic, dynamic>()),
    );
  }
  if (value is List) {
    return value.map<Object?>((entry) => _sanitizePayloadValue(entry)).toList();
  }
  return value.toString();
}
