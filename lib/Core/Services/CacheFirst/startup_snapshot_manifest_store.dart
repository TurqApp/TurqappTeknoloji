import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cache_scope_namespace.dart';
import 'cached_resource.dart';

class StartupSnapshotSurfaceRecord {
  const StartupSnapshotSurfaceRecord({
    required this.surface,
    required this.itemCount,
    required this.hasLocalSnapshot,
    required this.source,
    required this.isStale,
    required this.recordedAtMs,
    this.snapshotAgeMs,
  });

  final String surface;
  final int itemCount;
  final bool hasLocalSnapshot;
  final String source;
  final bool isStale;
  final int recordedAtMs;
  final int? snapshotAgeMs;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface,
      'itemCount': itemCount,
      'hasLocalSnapshot': hasLocalSnapshot,
      'source': source,
      'isStale': isStale,
      'recordedAtMs': recordedAtMs,
      'snapshotAgeMs': snapshotAgeMs,
    };
  }

  factory StartupSnapshotSurfaceRecord.fromJson(Map<String, dynamic> json) {
    return StartupSnapshotSurfaceRecord(
      surface: (json['surface'] ?? '').toString().trim(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      hasLocalSnapshot: json['hasLocalSnapshot'] == true,
      source:
          (json['source'] ?? CachedResourceSource.none.name).toString().trim(),
      isStale: json['isStale'] == true,
      recordedAtMs: (json['recordedAtMs'] as num?)?.toInt() ?? 0,
      snapshotAgeMs: (json['snapshotAgeMs'] as num?)?.toInt(),
    );
  }
}

class StartupSnapshotManifest {
  const StartupSnapshotManifest({
    required this.schemaVersion,
    required this.actorId,
    required this.savedAtMs,
    required this.routeHint,
    required this.loggedIn,
    required this.minimumStartupPrepared,
    required this.surfaces,
    this.launchToRouteMs,
    this.extra = const <String, dynamic>{},
  });

  final int schemaVersion;
  final String actorId;
  final int savedAtMs;
  final String routeHint;
  final bool loggedIn;
  final bool minimumStartupPrepared;
  final int? launchToRouteMs;
  final Map<String, StartupSnapshotSurfaceRecord> surfaces;
  final Map<String, dynamic> extra;

  StartupSnapshotManifest copyWith({
    int? schemaVersion,
    String? actorId,
    int? savedAtMs,
    String? routeHint,
    bool? loggedIn,
    bool? minimumStartupPrepared,
    int? launchToRouteMs,
    Map<String, StartupSnapshotSurfaceRecord>? surfaces,
    Map<String, dynamic>? extra,
  }) {
    return StartupSnapshotManifest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      actorId: actorId ?? this.actorId,
      savedAtMs: savedAtMs ?? this.savedAtMs,
      routeHint: routeHint ?? this.routeHint,
      loggedIn: loggedIn ?? this.loggedIn,
      minimumStartupPrepared:
          minimumStartupPrepared ?? this.minimumStartupPrepared,
      launchToRouteMs: launchToRouteMs ?? this.launchToRouteMs,
      surfaces: surfaces ?? this.surfaces,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'actorId': actorId,
      'savedAtMs': savedAtMs,
      'routeHint': routeHint,
      'loggedIn': loggedIn,
      'minimumStartupPrepared': minimumStartupPrepared,
      'launchToRouteMs': launchToRouteMs,
      'surfaces': surfaces.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'extra': extra,
    };
  }

  factory StartupSnapshotManifest.fromJson(Map<String, dynamic> json) {
    final rawSurfaces = Map<String, dynamic>.from(
        json['surfaces'] as Map? ?? const <String, dynamic>{});
    final surfaces = <String, StartupSnapshotSurfaceRecord>{};
    rawSurfaces.forEach((key, value) {
      if (value is! Map) return;
      surfaces[key] = StartupSnapshotSurfaceRecord.fromJson(
        Map<String, dynamic>.from(value),
      );
    });

    return StartupSnapshotManifest(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      actorId: (json['actorId'] ?? CacheScopeNamespace.guestActorId)
          .toString()
          .trim(),
      savedAtMs: (json['savedAtMs'] as num?)?.toInt() ?? 0,
      routeHint: (json['routeHint'] ?? '').toString().trim(),
      loggedIn: json['loggedIn'] == true,
      minimumStartupPrepared: json['minimumStartupPrepared'] == true,
      launchToRouteMs: (json['launchToRouteMs'] as num?)?.toInt(),
      surfaces: surfaces,
      extra: _sanitizeExtraMap(
        Map<String, dynamic>.from(
            json['extra'] as Map? ?? const <String, dynamic>{}),
      ),
    );
  }
}

class StartupSnapshotManifestStore extends GetxService {
  static const int schemaVersion = 1;
  static const String _keyPrefix = 'startup_snapshot_manifest_v1';
  static const String _defaultRouteHint = 'unknown';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _prefsInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<StartupSnapshotManifest?> load({
    String? userId,
  }) async {
    try {
      final prefs = await _prefsInstance();
      final raw = prefs.getString(_storageKey(userId));
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final manifest = StartupSnapshotManifest.fromJson(decoded);
      if (manifest.schemaVersion != schemaVersion) {
        await prefs.remove(_storageKey(userId));
        return null;
      }
      return manifest;
    } catch (_) {
      return null;
    }
  }

  Future<void> recordSurface({
    required String surface,
    required String userId,
    required CachedResource<dynamic> resource,
    required int itemCount,
  }) async {
    await recordSurfaceState(
      surface: surface,
      userId: userId,
      itemCount: itemCount,
      hasLocalSnapshot: resource.hasLocalSnapshot,
      source: resource.source.name,
      isStale: resource.isStale,
      snapshotAgeMs: resource.snapshotAt == null
          ? null
          : DateTime.now().difference(resource.snapshotAt!).inMilliseconds,
    );
  }

  Future<void> recordSurfaceState({
    required String surface,
    required String userId,
    required int itemCount,
    required bool hasLocalSnapshot,
    required String source,
    bool isStale = false,
    int? snapshotAgeMs,
  }) async {
    final normalizedSurface = surface.trim();
    if (normalizedSurface.isEmpty) return;

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final existing = await load(userId: userId);
      final surfaces = <String, StartupSnapshotSurfaceRecord>{
        ...?existing?.surfaces,
      };
      surfaces[normalizedSurface] = StartupSnapshotSurfaceRecord(
        surface: normalizedSurface,
        itemCount: itemCount < 0 ? 0 : itemCount,
        hasLocalSnapshot: hasLocalSnapshot,
        source: source.trim().isEmpty ? CachedResourceSource.none.name : source,
        isStale: isStale,
        recordedAtMs: nowMs,
        snapshotAgeMs: snapshotAgeMs,
      );

      await _write(
        StartupSnapshotManifest(
          schemaVersion: schemaVersion,
          actorId: _normalizeActorId(userId),
          savedAtMs: nowMs,
          routeHint: existing?.routeHint ?? _defaultRouteHint,
          loggedIn: existing?.loggedIn ?? userId.trim().isNotEmpty,
          minimumStartupPrepared: existing?.minimumStartupPrepared ?? false,
          launchToRouteMs: existing?.launchToRouteMs,
          surfaces: surfaces,
          extra: existing?.extra ?? const <String, dynamic>{},
        ),
      );
    } catch (_) {}
  }

  Future<void> markNavigation({
    required String userId,
    required String routeHint,
    required bool loggedIn,
    required bool minimumStartupPrepared,
    int? launchToRouteMs,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    try {
      final existing = await load(userId: userId);
      await _write(
        StartupSnapshotManifest(
          schemaVersion: schemaVersion,
          actorId: _normalizeActorId(userId),
          savedAtMs: DateTime.now().millisecondsSinceEpoch,
          routeHint:
              routeHint.trim().isEmpty ? _defaultRouteHint : routeHint.trim(),
          loggedIn: loggedIn,
          minimumStartupPrepared: minimumStartupPrepared,
          launchToRouteMs: launchToRouteMs,
          surfaces: existing?.surfaces ??
              const <String, StartupSnapshotSurfaceRecord>{},
          extra: _sanitizeExtraMap(
            <String, dynamic>{
              ...?existing?.extra,
              ...extra,
            },
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> updateRouteHint({
    required String userId,
    required String routeHint,
    bool loggedIn = true,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    try {
      final existing = await load(userId: userId);
      await _write(
        StartupSnapshotManifest(
          schemaVersion: schemaVersion,
          actorId: _normalizeActorId(userId),
          savedAtMs: DateTime.now().millisecondsSinceEpoch,
          routeHint:
              routeHint.trim().isEmpty ? _defaultRouteHint : routeHint.trim(),
          loggedIn: loggedIn,
          minimumStartupPrepared: existing?.minimumStartupPrepared ?? false,
          launchToRouteMs: existing?.launchToRouteMs,
          surfaces: existing?.surfaces ??
              const <String, StartupSnapshotSurfaceRecord>{},
          extra: _sanitizeExtraMap(
            <String, dynamic>{
              ...?existing?.extra,
              ...extra,
            },
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> clear({
    String? userId,
  }) async {
    try {
      final prefs = await _prefsInstance();
      await prefs.remove(_storageKey(userId));
    } catch (_) {}
  }

  Future<void> _write(StartupSnapshotManifest manifest) async {
    final prefs = await _prefsInstance();
    await prefs.setString(
      _storageKey(manifest.actorId),
      jsonEncode(manifest.toJson()),
    );
  }

  String _storageKey(String? userId) {
    return '$_keyPrefix::${_normalizeActorId(userId)}';
  }

  String _normalizeActorId(String? userId) {
    final normalized = userId?.trim() ?? '';
    if (normalized.isEmpty) return CacheScopeNamespace.guestActorId;
    return normalized;
  }
}

StartupSnapshotManifestStore? maybeFindStartupSnapshotManifestStore() {
  final isRegistered = Get.isRegistered<StartupSnapshotManifestStore>();
  if (!isRegistered) return null;
  return Get.find<StartupSnapshotManifestStore>();
}

StartupSnapshotManifestStore ensureStartupSnapshotManifestStore() {
  final existing = maybeFindStartupSnapshotManifestStore();
  if (existing != null) return existing;
  return Get.put(StartupSnapshotManifestStore(), permanent: true);
}

Map<String, dynamic> _sanitizeExtraMap(Map<String, dynamic> raw) {
  final sanitized = <String, dynamic>{};
  raw.forEach((key, value) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) return;
    if (value == null || value is String || value is num || value is bool) {
      sanitized[normalizedKey] = value;
    } else {
      sanitized[normalizedKey] = value.toString();
    }
  });
  return sanitized;
}
