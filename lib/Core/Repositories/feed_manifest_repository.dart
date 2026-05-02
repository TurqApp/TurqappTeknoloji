import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/app_firebase_storage.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class FeedManifestEntry {
  const FeedManifestEntry({
    required this.post,
    required this.canonicalId,
    required this.slotId,
    required this.slotPath,
  });

  final PostsModel post;
  final String canonicalId;
  final String slotId;
  final String slotPath;
}

class FeedManifestPoolResult {
  const FeedManifestPoolResult({
    required this.manifestId,
    required this.entries,
    required this.slotCount,
    required this.loadedSlotCount,
    required this.generatedAt,
  });

  final String manifestId;
  final List<FeedManifestEntry> entries;
  final int slotCount;
  final int loadedSlotCount;
  final int generatedAt;

  List<PostsModel> get posts =>
      entries.map((entry) => entry.post).toList(growable: false);
}

class FeedManifestRepository extends GetxService {
  FeedManifestRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? AppFirestore.instance,
        _storage = storage ?? AppFirebaseStorage.instance;

  static const Duration manifestWindowCadence = Duration(hours: 3);
  static const Duration _manifestPublishDelay = Duration(minutes: 5);
  static const int _maxSlotBytes = 16 * 1024 * 1024;
  static const int _maxConcurrentSlotLoads = 6;
  static const int _maxCachedManifestWindows = 24;
  static const Duration _activeRetryDelay = Duration(milliseconds: 700);
  static const Duration _authReadyTimeout = Duration(milliseconds: 1600);
  static const Duration _slotDownloadTimeout = Duration(milliseconds: 4000);
  static const String _localWindowsPrefsKey = 'feed_manifest_windows_v1';
  static const String _localSlotPrefsPrefix = 'feed_manifest_slot_v1';
  static const String _refreshGraceSyncPrefsKey =
      'feed_manifest_refresh_grace_sync_v1';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  String _manifestId = '';
  int _generatedAt = 0;
  bool _startupAuthPrimed = false;
  bool _localCacheHydrated = false;
  SharedPreferences? _prefs;
  final List<_FeedManifestWindow> _windows = <_FeedManifestWindow>[];
  final Map<String, List<FeedManifestEntry>> _slotEntries =
      <String, List<FeedManifestEntry>>{};
  Future<FeedManifestPoolResult>? _loadFuture;
  Future<void>? _backgroundActiveSyncFuture;
  Future<void>? _backgroundSlotPrefetchFuture;

  String get manifestId => _manifestId;
  int get generatedAt => _generatedAt;
  DateTime? get nextExpectedRefreshAt {
    if (_generatedAt <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(_generatedAt).add(
      manifestWindowCadence + _manifestPublishDelay,
    );
  }

  Future<FeedManifestPoolResult> loadRollingPool({
    bool forceRefresh = false,
    int? maxSlotsToLoad,
  }) {
    if (!forceRefresh) {
      final existing = _loadFuture;
      if (existing != null) return existing;
    }
    final future = _loadRollingPool(
      forceRefresh: forceRefresh,
      maxSlotsToLoad: maxSlotsToLoad,
    );
    _loadFuture = future;
    return future.whenComplete(() {
      if (identical(_loadFuture, future)) {
        _loadFuture = null;
      }
    });
  }

  Future<void> warmStartupWindow({
    int? maxSlotsToLoad,
  }) async {
    final result = await loadRollingPool(
      maxSlotsToLoad: maxSlotsToLoad,
    );
    if (kDebugMode) {
      debugPrint(
        '[FeedManifestRepo] stage=warm_complete '
        'manifestId=${result.manifestId} '
        'slotCount=${result.slotCount} '
        'loadedSlotCount=${result.loadedSlotCount} '
        'entryCount=${result.entries.length} '
        'maxSlotsToLoad=${maxSlotsToLoad ?? 0}',
      );
    }
  }

  Future<bool> syncActiveWindowIfRefreshGraceDue() async {
    await _hydrateLocalCache();
    final prefs = await _ensurePrefs();
    final now = DateTime.now();
    final reference = now.subtract(_manifestPublishDelay);
    final dueWindowKey = _slotWindowKeyFor(reference);
    final lastWindowKey = prefs.getString(_refreshGraceSyncPrefsKey) ?? '';
    if (dueWindowKey.isEmpty || dueWindowKey == lastWindowKey) {
      return false;
    }
    await prefs.setString(_refreshGraceSyncPrefsKey, dueWindowKey);
    final changed = await syncActiveWindowIfChanged();
    if (kDebugMode) {
      debugPrint(
        '[FeedManifestRepo] stage=refresh_grace_sync '
        'windowKey=$dueWindowKey changed=$changed '
        'manifestId=$_manifestId',
      );
    }
    return changed;
  }

  Future<FeedManifestPoolResult> _loadRollingPool({
    required bool forceRefresh,
    required int? maxSlotsToLoad,
  }) async {
    await _hydrateLocalCache();
    final hasLocalWindows = _windows.isNotEmpty;
    if (forceRefresh || !hasLocalWindows) {
      try {
        final active = await _loadActiveManifestDoc();
        final activeData = active.data() ?? const <String, dynamic>{};
        final nextManifestId =
            (activeData['manifestId'] ?? '').toString().trim();
        final generatedAt =
            int.tryParse('${activeData['generatedAt'] ?? 0}') ?? 0;
        final slotRefs = _parseSlotRefs(activeData['slots']);

        if (nextManifestId.isNotEmpty && slotRefs.isNotEmpty) {
          _manifestId = nextManifestId;
          _generatedAt = generatedAt;
          await _mergeActiveWindow(
            manifestId: nextManifestId,
            generatedAt: generatedAt,
            slotRefs: slotRefs,
          );
        } else if (_windows.isEmpty) {
          _reset();
          return const FeedManifestPoolResult(
            manifestId: '',
            entries: <FeedManifestEntry>[],
            slotCount: 0,
            loadedSlotCount: 0,
            generatedAt: 0,
          );
        }
      } catch (error) {
        if (_windows.isEmpty) rethrow;
        if (kDebugMode) {
          debugPrint(
            '[FeedManifestRepo] stage=active_fallback_to_local error=$error',
          );
        }
      }
    } else {
      _scheduleBackgroundActiveSyncIfNeeded();
    }
    final slotRefs = _flattenWindowSlotRefs();
    if (slotRefs.isEmpty) {
      return const FeedManifestPoolResult(
        manifestId: '',
        entries: <FeedManifestEntry>[],
        slotCount: 0,
        loadedSlotCount: 0,
        generatedAt: 0,
      );
    }
    final effectiveSlotRefs = maxSlotsToLoad != null && maxSlotsToLoad > 0
        ? slotRefs.take(maxSlotsToLoad).toList(growable: false)
        : slotRefs;
    await _ensureSlotsLoaded(
      effectiveSlotRefs,
      forceRefresh: forceRefresh,
    );
    _scheduleBackgroundSlotPrefetch(slotRefs);
    final entries = <FeedManifestEntry>[];
    var loadedSlotCount = 0;
    for (final slot in effectiveSlotRefs) {
      final slotEntries = _slotEntries[slot.path];
      if (slotEntries == null) continue;
      loadedSlotCount++;
      entries.addAll(slotEntries);
    }

    if (kDebugMode) {
      final preview = entries
          .take(12)
          .map(
            (entry) =>
                '${entry.post.docID}'
                '@${entry.slotId}'
                ' ts=${entry.post.timeStamp}'
                ' path=${entry.slotPath}',
          )
          .join(' | ');
      debugPrint(
        '[FeedManifestRepo] stage=pool_loaded '
        'manifestId=$_manifestId '
        'slotCount=${effectiveSlotRefs.length} '
        'loadedSlotCount=$loadedSlotCount '
        'entryCount=${entries.length} '
        'preview=$preview',
      );
    }

    return FeedManifestPoolResult(
      manifestId: _manifestId,
      entries: entries,
      slotCount: effectiveSlotRefs.length,
      loadedSlotCount: loadedSlotCount,
      generatedAt: _generatedAt,
    );
  }

  Future<bool> syncActiveWindowIfChanged() async {
    await _hydrateLocalCache();
    final active = await _loadActiveManifestDoc();
    final activeData = active.data() ?? const <String, dynamic>{};
    final nextManifestId = (activeData['manifestId'] ?? '').toString().trim();
    final generatedAt = int.tryParse('${activeData['generatedAt'] ?? 0}') ?? 0;
    final slotRefs = _parseSlotRefs(activeData['slots']);
    if (nextManifestId.isEmpty || slotRefs.isEmpty) {
      return false;
    }
    final changed =
        nextManifestId != _manifestId || generatedAt != _generatedAt;
    if (!changed) {
      return false;
    }
    await _mergeActiveWindow(
      manifestId: nextManifestId,
      generatedAt: generatedAt,
      slotRefs: slotRefs,
    );
    return true;
  }

  void _scheduleBackgroundActiveSyncIfNeeded() {
    if (_backgroundActiveSyncFuture != null) return;
    final nextRefreshAt = nextExpectedRefreshAt;
    final now = DateTime.now();
    final shouldSync =
        nextRefreshAt == null || !now.isBefore(nextRefreshAt);
    if (!shouldSync) return;

    final future = () async {
      try {
        await syncActiveWindowIfChanged();
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            '[FeedManifestRepo] stage=background_active_sync_skip error=$error',
          );
        }
      }
    }();
    _backgroundActiveSyncFuture = future.whenComplete(() {
      if (identical(_backgroundActiveSyncFuture, future)) {
        _backgroundActiveSyncFuture = null;
      }
    });
  }

  void _scheduleBackgroundSlotPrefetch(List<_FeedManifestSlotRef> slots) {
    if (_backgroundSlotPrefetchFuture != null || slots.isEmpty) return;
    final pending = slots
        .where((slot) =>
            slot.path.isNotEmpty && !_slotEntries.containsKey(slot.path))
        .toList(growable: false);
    if (pending.isEmpty) return;
    final future = _ensureSlotsLoaded(
      pending,
      forceRefresh: false,
    );
    _backgroundSlotPrefetchFuture = future.whenComplete(() {
      if (identical(_backgroundSlotPrefetchFuture, future)) {
        _backgroundSlotPrefetchFuture = null;
      }
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>>
      _loadActiveManifestDoc() async {
    await _ensureManifestAccessReady();
    try {
      return await _firestore.collection('feedManifest').doc('active').get();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      if (defaultTargetPlatform == TargetPlatform.android) {
        rethrow;
      }
      await _ensureManifestAccessReady(forceTokenRefresh: true);
      await Future<void>.delayed(_activeRetryDelay);
      return _firestore.collection('feedManifest').doc('active').get();
    }
  }

  Future<void> _ensureManifestAccessReady({
    bool forceTokenRefresh = false,
  }) async {
    final currentUser = CurrentUserService.instance;
    if (!forceTokenRefresh && !currentUser.hasAuthUser) {
      return;
    }
    final shouldForceRefresh = forceTokenRefresh || !_startupAuthPrimed;
    await currentUser.ensureAuthReady(
      waitForAuthState: true,
      forceTokenRefresh: shouldForceRefresh,
      timeout: _authReadyTimeout,
      recordTimeoutFailure: false,
    );
    _startupAuthPrimed = true;
  }

  Future<void> _ensureSlotsLoaded(
    List<_FeedManifestSlotRef> slots, {
    required bool forceRefresh,
  }) async {
    final pending = slots
        .where((slot) =>
            slot.path.isNotEmpty &&
            (forceRefresh || !_slotEntries.containsKey(slot.path)))
        .toList(growable: false);
    for (var start = 0;
        start < pending.length;
        start += _maxConcurrentSlotLoads) {
      final end = (start + _maxConcurrentSlotLoads).clamp(0, pending.length);
      final batch = pending.sublist(start, end);
      await Future.wait(
        batch.map((slot) => _loadSlot(slot, forceRefresh: forceRefresh)),
      );
    }
  }

  String _slotWindowKeyFor(DateTime timestamp) {
    final local = timestamp.toLocal();
    final slotHour = (local.hour ~/ 3) * 3;
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = slotHour.toString().padLeft(2, '0');
    return '${local.year}-$month-$day:$hour';
  }

  Future<void> _loadSlot(
    _FeedManifestSlotRef slot, {
    required bool forceRefresh,
  }) async {
    final prefs = await _ensurePrefs();
    if (!forceRefresh) {
      final cachedRaw = prefs.getString(_slotPrefsKey(slot.path));
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final parsed = parseSlotEntries(
          cachedRaw,
          fallbackSlotId: slot.slotId,
          slotPath: slot.path,
        );
        _slotEntries[slot.path] = parsed;
        return;
      }
    }
    try {
      final bytes = await _storage
          .ref(slot.path)
          .getData(_maxSlotBytes)
          .timeout(_slotDownloadTimeout);
      if (bytes == null || bytes.isEmpty) {
        _slotEntries[slot.path] = const <FeedManifestEntry>[];
        await prefs.remove(_slotPrefsKey(slot.path));
        return;
      }
      final rawJson = utf8.decode(bytes);
      _slotEntries[slot.path] = parseSlotEntries(
        rawJson,
        fallbackSlotId: slot.slotId,
        slotPath: slot.path,
      );
      await prefs.setString(_slotPrefsKey(slot.path), rawJson);
    } catch (error) {
      _slotEntries.remove(slot.path);
      if (kDebugMode) {
        debugPrint(
          '[FeedManifestRepo] stage=slot_load_skip path=${slot.path} '
          'error=$error',
        );
      }
    }
  }

  void _reset() {
    _manifestId = '';
    _generatedAt = 0;
    _windows.clear();
    _slotEntries.clear();
  }

  Future<void> _hydrateLocalCache() async {
    if (_localCacheHydrated) return;
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_localWindowsPrefsKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _windows
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map(
                    (entry) => _FeedManifestWindow.fromJson(
                      Map<String, dynamic>.from(
                        entry.cast<dynamic, dynamic>(),
                      ),
                    ),
                  )
                  .where((entry) => entry.isValid),
            );
        }
      } catch (_) {}
    }
    _windows
        .sort((left, right) => right.generatedAt.compareTo(left.generatedAt));
    if (_windows.isNotEmpty) {
      _manifestId = _windows.first.manifestId;
      _generatedAt = _windows.first.generatedAt;
    }
    _localCacheHydrated = true;
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??=
        await ensureLocalPreferenceRepository().sharedPreferences();
  }

  Future<void> _mergeActiveWindow({
    required String manifestId,
    required int generatedAt,
    required List<_FeedManifestSlotRef> slotRefs,
  }) async {
    final manifestChanged =
        manifestId != _manifestId || generatedAt != _generatedAt;
    final next = _FeedManifestWindow(
      manifestId: manifestId,
      generatedAt: generatedAt,
      slots: slotRefs,
    );
    _windows.removeWhere((entry) => entry.manifestId == manifestId);
    _windows.add(next);
    _windows
        .sort((left, right) => right.generatedAt.compareTo(left.generatedAt));

    final retained =
        _windows.take(_maxCachedManifestWindows).toList(growable: false);
    final retainedPaths = retained
        .expand((entry) => entry.slots)
        .map((slot) => slot.path)
        .where((path) => path.isNotEmpty)
        .toSet();
    final removedPaths = _windows
        .skip(_maxCachedManifestWindows)
        .expand((entry) => entry.slots)
        .map((slot) => slot.path)
        .where((path) => path.isNotEmpty && !retainedPaths.contains(path))
        .toSet();
    final invalidatedPaths = <String>{
      ...removedPaths,
      if (manifestChanged) ...retainedPaths,
    };

    _windows
      ..clear()
      ..addAll(retained);
    _manifestId = _windows.isEmpty ? '' : _windows.first.manifestId;
    _generatedAt = _windows.isEmpty ? 0 : _windows.first.generatedAt;
    for (final path in invalidatedPaths) {
      _slotEntries.remove(path);
    }
    await _persistLocalCache(removedPaths: invalidatedPaths);
  }

  Future<void> _persistLocalCache({
    Set<String> removedPaths = const <String>{},
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _localWindowsPrefsKey,
      jsonEncode(_windows.map((entry) => entry.toJson()).toList()),
    );
    for (final path in removedPaths) {
      await prefs.remove(_slotPrefsKey(path));
    }
  }

  List<_FeedManifestSlotRef> _flattenWindowSlotRefs() {
    final output = <_FeedManifestSlotRef>[];
    final seenPaths = <String>{};
    for (final window in _windows) {
      for (final slot in window.slots) {
        if (slot.path.isEmpty || !seenPaths.add(slot.path)) continue;
        output.add(slot);
      }
    }
    return output;
  }

  String _slotPrefsKey(String path) {
    final encoded = base64Url.encode(utf8.encode(path));
    return '$_localSlotPrefsPrefix:$encoded';
  }

  static List<FeedManifestEntry> parseSlotEntries(
    String rawJson, {
    required String fallbackSlotId,
    required String slotPath,
  }) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) return const <FeedManifestEntry>[];
    final slotId = (decoded['slotId'] ?? fallbackSlotId).toString().trim();
    final itemsRaw = decoded['items'];
    if (itemsRaw is! List) return const <FeedManifestEntry>[];
    final entries = <FeedManifestEntry>[];
    final seenCanonicalIds = <String>{};
    for (final raw in itemsRaw) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final docId = (map['docId'] ?? '').toString().trim();
      if (docId.isEmpty) continue;
      final canonicalId = _canonicalIdForManifestItem(map, docId);
      if (canonicalId.isEmpty || !seenCanonicalIds.add(canonicalId)) {
        continue;
      }
      entries.add(
        FeedManifestEntry(
          post: PostsModel.fromMap(_manifestItemToPostMap(map), docId),
          canonicalId: canonicalId,
          slotId: slotId,
          slotPath: slotPath,
        ),
      );
    }
    return entries;
  }

  static List<_FeedManifestSlotRef> _parseSlotRefs(dynamic raw) {
    if (raw is! List) return const <_FeedManifestSlotRef>[];
    final output = <_FeedManifestSlotRef>[];
    final seenPaths = <String>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final path = (map['path'] ?? '').toString().trim();
      if (path.isEmpty || !seenPaths.add(path)) continue;
      output.add(
        _FeedManifestSlotRef(
          path: path,
          slotId: (map['slotId'] ?? '').toString().trim(),
          date: (map['date'] ?? '').toString().trim(),
          slotHour: int.tryParse('${map['slotHour'] ?? 0}') ?? 0,
        ),
      );
    }
    return output;
  }

  static String _canonicalIdForManifestItem(
    Map<String, dynamic> item,
    String docId,
  ) {
    final direct = (item['canonicalId'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final flags = item['flags'] is Map
        ? Map<String, dynamic>.from(item['flags'] as Map)
        : const <String, dynamic>{};
    final mainFlood =
        (flags['mainFlood'] ?? item['mainFlood'] ?? '').toString().trim();
    if (mainFlood.isNotEmpty) return mainFlood;
    final floodCount =
        num.tryParse('${flags['floodCount'] ?? item['floodCount'] ?? 1}') ?? 1;
    if (floodCount > 1) return docId;
    return docId.replaceFirst(RegExp(r'_\d+$'), '');
  }

  static Map<String, dynamic> _manifestItemToPostMap(
    Map<String, dynamic> item,
  ) {
    final stats = item['stats'] is Map
        ? Map<String, dynamic>.from(item['stats'] as Map)
        : const <String, dynamic>{};
    final flags = item['flags'] is Map
        ? Map<String, dynamic>.from(item['flags'] as Map)
        : const <String, dynamic>{};
    final hlsMasterUrl = (item['hlsMasterUrl'] ?? '').toString().trim();
    final videoUrl = (item['video'] ?? '').toString().trim();
    final hasPlayableVideo = hlsMasterUrl.isNotEmpty || videoUrl.isNotEmpty;
    final posters = item['posterCandidates'] is List
        ? (item['posterCandidates'] as List)
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty && value != 'null')
            .toList(growable: false)
        : <String>[];
    return <String, dynamic>{
      'userID': item['userID'],
      'authorNickname': item['authorNickname'],
      'authorDisplayName': item['authorDisplayName'],
      'authorAvatarUrl': item['authorAvatarUrl'],
      'rozet': item['rozet'],
      'metin': item['metin'],
      'thumbnail': item['thumbnail'],
      'img': hasPlayableVideo ? const <String>[] : posters,
      'video': item['video'],
      'hlsMasterUrl': item['hlsMasterUrl'],
      'hlsStatus': item['hlsStatus'],
      'aspectRatio': item['aspectRatio'],
      'timeStamp': item['timeStamp'],
      'createdAtTs': item['createdAtTs'],
      'shortId': item['shortId'],
      'shortUrl': item['shortUrl'],
      'stats': stats,
      'likeCount': stats['likeCount'],
      'commentCount': stats['commentCount'],
      'savedCount': stats['savedCount'],
      'retryCount': stats['retryCount'],
      'statsCount': stats['statsCount'],
      'deletedPost': flags['deletedPost'] == true,
      'gizlendi': flags['gizlendi'] == true,
      'arsiv': flags['arsiv'] == true,
      'flood': flags['flood'] == true,
      'floodCount': flags['floodCount'] ?? 1,
      'mainFlood': flags['mainFlood'] ?? '',
      'paylasGizliligi': flags['paylasGizliligi'] ?? 0,
      'isUploading': false,
      'stabilized': true,
    };
  }
}

class _FeedManifestSlotRef {
  const _FeedManifestSlotRef({
    required this.path,
    required this.slotId,
    required this.date,
    required this.slotHour,
  });

  final String path;
  final String slotId;
  final String date;
  final int slotHour;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'slotId': slotId,
        'date': date,
        'slotHour': slotHour,
      };

  bool get isValid => path.trim().isNotEmpty;

  factory _FeedManifestSlotRef.fromJson(Map<String, dynamic> json) {
    return _FeedManifestSlotRef(
      path: (json['path'] ?? '').toString().trim(),
      slotId: (json['slotId'] ?? '').toString().trim(),
      date: (json['date'] ?? '').toString().trim(),
      slotHour: int.tryParse('${json['slotHour'] ?? 0}') ?? 0,
    );
  }
}

class _FeedManifestWindow {
  const _FeedManifestWindow({
    required this.manifestId,
    required this.generatedAt,
    required this.slots,
  });

  final String manifestId;
  final int generatedAt;
  final List<_FeedManifestSlotRef> slots;

  bool get isValid =>
      manifestId.trim().isNotEmpty &&
      generatedAt > 0 &&
      slots.any((slot) => slot.isValid);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'manifestId': manifestId,
        'generatedAt': generatedAt,
        'slots': slots.map((slot) => slot.toJson()).toList(growable: false),
      };

  factory _FeedManifestWindow.fromJson(Map<String, dynamic> json) {
    final slotsRaw = json['slots'];
    final slots = slotsRaw is List
        ? slotsRaw
            .whereType<Map>()
            .map(
              (entry) => _FeedManifestSlotRef.fromJson(
                Map<String, dynamic>.from(entry.cast<dynamic, dynamic>()),
              ),
            )
            .where((slot) => slot.isValid)
            .toList(growable: false)
        : const <_FeedManifestSlotRef>[];
    return _FeedManifestWindow(
      manifestId: (json['manifestId'] ?? '').toString().trim(),
      generatedAt: int.tryParse('${json['generatedAt'] ?? 0}') ?? 0,
      slots: slots,
    );
  }
}

FeedManifestRepository ensureFeedManifestRepository() {
  if (Get.isRegistered<FeedManifestRepository>()) {
    return Get.find<FeedManifestRepository>();
  }
  return Get.put(FeedManifestRepository(), permanent: true);
}
