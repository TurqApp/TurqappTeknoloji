import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Services/app_firebase_storage.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/manifest_disk_cipher.dart';
import 'package:turqappv2/Core/Services/short_resume_state_store.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class ShortManifestPageResult {
  const ShortManifestPageResult({
    required this.posts,
    required this.hasMore,
    required this.manifestId,
    required this.slotIndex,
  });

  final List<PostsModel> posts;
  final bool hasMore;
  final String manifestId;
  final int slotIndex;
}

class ShortManifestCursorSnapshot {
  const ShortManifestCursorSnapshot({
    required this.manifestId,
    required this.slotIndex,
    required this.itemIndex,
    required this.hasMore,
  });

  final String manifestId;
  final int slotIndex;
  final int itemIndex;
  final bool hasMore;
}

class ShortManifestRepository extends GetxService {
  ShortManifestRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? AppFirestore.instance,
        _storage = storage ?? AppFirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const Duration _authReadyTimeout = Duration(milliseconds: 1600);
  static const int _maxIndexBytes = 1024 * 1024;
  static const int _maxSlotBytes = 16 * 1024 * 1024;
  static const int _maxCachedSlotPrefs = 12;
  static const String _localIndexPrefsKey = 'short_manifest_index_v1';
  static const String _localSlotPrefsPrefix = 'short_manifest_slot_v1';
  static const String _localSlotListPrefsKey = 'short_manifest_cached_slots_v1';

  String _manifestId = '';
  String _indexPath = '';
  Map<String, dynamic>? _index;
  final Map<int, List<PostsModel>> _slots = <int, List<PostsModel>>{};
  final Map<int, Future<List<PostsModel>>> _slotLoads =
      <int, Future<List<PostsModel>>>{};
  int _cursorSlotIndex = 0;
  int _cursorItemIndex = 0;
  Future<void>? _loadFuture;
  Future<void>? _tailSlotFuture;
  SharedPreferences? _prefs;
  static const int _retainedConsumedSlotCount = 1;
  static const int _rollingWindowSlotCount = 3;

  void _logTiming(
    String stage, {
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[ShortManifestRepo] stage=$stage metadata=$metadata',
    );
  }

  Future<ShortManifestPageResult> takeNextPage({
    required int pageSize,
  }) async {
    final normalizedPageSize = pageSize <= 0 ? 1 : pageSize;
    await _ensureLoaded();

    final output = <PostsModel>[];
    while (output.length < normalizedPageSize) {
      var currentPath = _slotPath(_cursorSlotIndex);
      if (currentPath.isEmpty) {
        await _ensureActiveTailSlot();
        currentPath = _slotPath(_cursorSlotIndex);
      }
      if (currentPath.isEmpty) {
        break;
      }
      final slot = await _ensureSlot(_cursorSlotIndex);
      if (slot.isEmpty) {
        _cursorSlotIndex++;
        _cursorItemIndex = 0;
        unawaited(_ensureRollingWindow());
        continue;
      }
      while (_cursorItemIndex < slot.length &&
          output.length < normalizedPageSize) {
        output.add(slot[_cursorItemIndex]);
        _cursorItemIndex++;
      }
      if (_cursorItemIndex >= slot.length) {
        final completedSlotIndex = _cursorSlotIndex;
        _cursorSlotIndex++;
        _cursorItemIndex = 0;
        await _ensureActiveTailSlot();
        _trimConsumedSlots(completedSlotIndex: completedSlotIndex);
        unawaited(_ensureRollingWindow());
      }
    }

    return ShortManifestPageResult(
      posts: output,
      hasMore: await _hasMore(),
      manifestId: _manifestId,
      slotIndex: _cursorSlotIndex,
    );
  }

  ShortManifestCursorSnapshot currentCursorSnapshot() {
    return ShortManifestCursorSnapshot(
      manifestId: _manifestId,
      slotIndex: _cursorSlotIndex,
      itemIndex: _cursorItemIndex,
      hasMore: _slotPath(_cursorSlotIndex).isNotEmpty,
    );
  }

  Future<bool> refreshIfActiveManifestChanged() async {
    await _ensureManifestAccessReady();
    final active = await _loadActiveManifestDoc();
    final activeData = active.data() ?? const <String, dynamic>{};
    final nextManifestId = (activeData['manifestId'] ?? '').toString();
    final indexPath = (activeData['indexPath'] ?? '').toString();
    final date = (activeData['date'] ?? '').toString();
    if (nextManifestId.isEmpty || indexPath.isEmpty || date.isEmpty) {
      return false;
    }
    if (nextManifestId == _manifestId) {
      return false;
    }
    _reset();
    await _loadManifest();
    return _manifestId == nextManifestId && _index != null;
  }

  Future<void> _ensureLoaded() {
    final existing = _loadFuture;
    if (existing != null) return existing;
    final future = _loadManifest();
    _loadFuture = future;
    return future.whenComplete(() {
      if (identical(_loadFuture, future)) {
        _loadFuture = null;
      }
    });
  }

  Future<void> warmStartupWindow() async {
    await _ensureLoaded();
    await _ensureStartupSlotsLoaded();
  }

  Future<void> _loadManifest() async {
    final totalStartedAt = DateTime.now();
    final authStartedAt = DateTime.now();
    await _ensureManifestAccessReady();
    _logTiming(
      'auth_ready',
      metadata: <String, Object?>{
        'elapsedMs': DateTime.now().difference(authStartedAt).inMilliseconds,
      },
    );
    final activeStartedAt = DateTime.now();
    final active = await _loadActiveManifestDoc();
    _logTiming(
      'active_doc_ready',
      metadata: <String, Object?>{
        'elapsedMs': DateTime.now().difference(activeStartedAt).inMilliseconds,
      },
    );
    final activeData = active.data() ?? const <String, dynamic>{};
    final nextManifestId = (activeData['manifestId'] ?? '').toString();
    final indexPath = (activeData['indexPath'] ?? '').toString();
    final date = (activeData['date'] ?? '').toString();
    if (nextManifestId.isEmpty || indexPath.isEmpty || date.isEmpty) {
      _reset();
      return;
    }

    if (_manifestId == nextManifestId && _index != null) {
      await _ensureRollingWindow();
      _logTiming(
        'load_manifest_reuse',
        metadata: <String, Object?>{
          'manifestId': _manifestId,
          'elapsedMs': DateTime.now().difference(totalStartedAt).inMilliseconds,
        },
      );
      return;
    }

    final decodedIndex = await _loadIndex(
      manifestId: nextManifestId,
      indexPath,
      stage: 'index_download_ready',
    );
    if (decodedIndex == null) {
      _reset();
      return;
    }
    _manifestId = nextManifestId;
    _indexPath = indexPath;
    _index = decodedIndex;
    _slots.clear();
    _slotLoads.clear();
    _cursorSlotIndex = 0;
    _cursorItemIndex = 0;
    await _restorePersistedCursorIfNeeded();
    await _ensureSlot(_cursorSlotIndex);
    unawaited(_primeRollingWindow());
    _logTiming(
      'load_manifest_complete',
      metadata: <String, Object?>{
        'manifestId': _manifestId,
        'slotCount': _slotCount(_index),
        'elapsedMs': DateTime.now().difference(totalStartedAt).inMilliseconds,
      },
    );
  }

  Future<Map<String, dynamic>?> _loadIndex(
    String indexPath, {
    required String manifestId,
    required String stage,
  }) async {
    final cached = await _readIndexSnapshot(
      manifestId: manifestId,
      indexPath: indexPath,
    );
    if (cached != null) {
      _logTiming(
        'index_cache_hit',
        metadata: <String, Object?>{
          'manifestId': manifestId,
          'path': indexPath,
        },
      );
      return cached;
    }
    final downloaded = await _downloadIndex(
      indexPath,
      stage: stage,
    );
    if (downloaded != null) {
      await _writeIndexSnapshot(
        manifestId: manifestId,
        indexPath: indexPath,
        index: downloaded,
      );
    }
    return downloaded;
  }

  Future<Map<String, dynamic>?> _downloadIndex(
    String indexPath, {
    required String stage,
  }) async {
    final indexStartedAt = DateTime.now();
    final bytes = await _storage.ref(indexPath).getData(_maxIndexBytes);
    _logTiming(
      stage,
      metadata: <String, Object?>{
        'path': indexPath,
        'elapsedMs': DateTime.now().difference(indexStartedAt).inMilliseconds,
        'bytes': bytes?.length ?? 0,
      },
    );
    if (bytes == null || bytes.isEmpty) return null;
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _ensureManifestAccessReady({
    bool forceTokenRefresh = false,
  }) async {
    final currentUser = CurrentUserService.instance;
    if (!forceTokenRefresh && !currentUser.hasAuthUser) {
      return;
    }
    await currentUser.ensureAuthReady(
      waitForAuthState: true,
      forceTokenRefresh: forceTokenRefresh,
      timeout: _authReadyTimeout,
      recordTimeoutFailure: false,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>>
      _loadActiveManifestDoc() async {
    try {
      return await _firestore.collection('shortManifest').doc('active').get();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      if (!CurrentUserService.instance.hasAuthUser) {
        rethrow;
      }
      await _ensureManifestAccessReady(forceTokenRefresh: true);
      return _firestore.collection('shortManifest').doc('active').get();
    }
  }

  Future<bool> _restorePersistedCursorIfNeeded() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty || _manifestId.isEmpty) return false;
    final persisted = await ensureShortResumeStateStore().load(
      userId: userId,
    );
    if (persisted == null) return false;
    if (persisted.manifestId != _manifestId) return false;
    var restoredSlotIndex =
        persisted.cursorSlotIndex < 0 ? 0 : persisted.cursorSlotIndex;
    var restoredItemIndex =
        persisted.cursorItemIndex < 0 ? 0 : persisted.cursorItemIndex;
    while (true) {
      final path = _slotPath(restoredSlotIndex);
      if (path.isEmpty) {
        await ensureShortResumeStateStore().clear(userId: userId);
        _cursorSlotIndex = 0;
        _cursorItemIndex = 0;
        _logTiming(
          'cursor_restore_ignored',
          metadata: <String, Object?>{
            'reason': 'slot_out_of_range',
            'manifestId': _manifestId,
            'persistedSlotIndex': persisted.cursorSlotIndex,
            'persistedItemIndex': persisted.cursorItemIndex,
            'slotCount': (_index?['slots'] as List?)?.length ?? 0,
          },
        );
        return false;
      }
      final slot = await _ensureSlot(restoredSlotIndex);
      if (restoredItemIndex < slot.length) {
        break;
      }
      restoredSlotIndex++;
      restoredItemIndex = 0;
    }
    _cursorSlotIndex = restoredSlotIndex;
    _cursorItemIndex = restoredItemIndex;
    _logTiming(
      'cursor_restore_ready',
      metadata: <String, Object?>{
        'manifestId': _manifestId,
        'slotIndex': _cursorSlotIndex,
        'itemIndex': _cursorItemIndex,
      },
    );
    return true;
  }

  Future<ShortManifestPageResult> takeNextPageFromPersistedCursor({
    required int pageSize,
  }) async {
    await _ensureLoaded();
    final restored = await _restorePersistedCursorIfNeeded();
    if (!restored) {
      return ShortManifestPageResult(
        posts: const <PostsModel>[],
        hasMore: await _hasMore(),
        manifestId: _manifestId,
        slotIndex: _cursorSlotIndex,
      );
    }
    return takeNextPage(pageSize: pageSize);
  }

  void _reset() {
    _manifestId = '';
    _indexPath = '';
    _index = null;
    _slots.clear();
    _slotLoads.clear();
    _cursorSlotIndex = 0;
    _cursorItemIndex = 0;
  }

  int _slotCount(Map<String, dynamic>? index) {
    final slotsRaw = index?['slots'];
    return slotsRaw is List ? slotsRaw.length : 0;
  }

  void _trimConsumedSlots({required int completedSlotIndex}) {
    final retainFromSlot = _cursorSlotIndex - _retainedConsumedSlotCount;
    if (retainFromSlot <= 0) return;
    final removedSlots = <int>[];
    for (final slotIndex in List<int>.from(_slots.keys)) {
      if (slotIndex < retainFromSlot) {
        _slots.remove(slotIndex);
        removedSlots.add(slotIndex);
      }
    }
    if (removedSlots.isEmpty) return;
    _logTiming(
      'consumed_slots_trimmed',
      metadata: <String, Object?>{
        'completedSlotIndex': completedSlotIndex,
        'cursorSlotIndex': _cursorSlotIndex,
        'removedSlots': removedSlots,
        'cachedSlots': _slots.keys.toList(growable: false)..sort(),
      },
    );
  }

  Future<bool> _hasMore() async {
    var slotIndex = _cursorSlotIndex;
    var itemIndex = _cursorItemIndex;
    while (true) {
      final path = _slotPath(slotIndex);
      if (path.isEmpty) return false;
      final slot = await _ensureSlot(slotIndex);
      if (itemIndex < slot.length) {
        return true;
      }
      slotIndex++;
      itemIndex = 0;
    }
  }

  Future<void> _ensureRollingWindow() async {
    final startedAt = DateTime.now();
    final firstSlot = _cursorSlotIndex;
    final lastSlot = _cursorSlotIndex + _rollingWindowSlotCount - 1;
    final futures = <Future<void>>[];
    for (var slotIndex = firstSlot; slotIndex <= lastSlot; slotIndex++) {
      futures.add(_ensureSlot(slotIndex).then((_) {}));
    }
    await Future.wait<void>(futures, eagerError: false);
    _logTiming(
      'rolling_window_ready',
      metadata: <String, Object?>{
        'firstSlot': firstSlot,
        'lastSlot': lastSlot,
        'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
      },
    );
  }

  Future<void> _ensureStartupSlotsLoaded() async {
    final index = _index;
    final slotsRaw = index?['slots'];
    if (slotsRaw is! List || slotsRaw.isEmpty) {
      return;
    }
    final startedAt = DateTime.now();
    final futures = <Future<void>>[];
    final slotCount = slotsRaw.length < _rollingWindowSlotCount
        ? slotsRaw.length
        : _rollingWindowSlotCount;
    for (var slotIndex = 0; slotIndex < slotCount; slotIndex++) {
      futures.add(_ensureSlot(slotIndex).then((_) {}));
    }
    await Future.wait<void>(futures, eagerError: false);
    _logTiming(
      'startup_slots_loaded',
      metadata: <String, Object?>{
        'slotCount': slotCount,
        'availableSlotCount': slotsRaw.length,
        'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
      },
    );
  }

  Future<List<PostsModel>> _ensureSlot(int slotIndex) async {
    if (slotIndex < 0) return const <PostsModel>[];
    final cached = _slots[slotIndex];
    if (cached != null) {
      _logTiming(
        'slot_cache_hit',
        metadata: <String, Object?>{
          'slotIndex': slotIndex,
          'count': cached.length,
        },
      );
      return cached;
    }
    final inFlight = _slotLoads[slotIndex];
    if (inFlight != null) {
      return inFlight;
    }
    final future = _loadSlot(slotIndex);
    _slotLoads[slotIndex] = future;
    return future.whenComplete(() {
      if (identical(_slotLoads[slotIndex], future)) {
        _slotLoads.remove(slotIndex);
      }
    });
  }

  Future<void> _primeRollingWindow() async {
    final firstSlot = _cursorSlotIndex;
    final lastSlot = _cursorSlotIndex + _rollingWindowSlotCount - 1;
    final futures = <Future<void>>[];
    for (var slotIndex = firstSlot; slotIndex <= lastSlot; slotIndex++) {
      futures.add(_ensureSlot(slotIndex).then((_) {}));
    }
    await Future.wait<void>(futures, eagerError: false);
    _logTiming(
      'rolling_window_primed',
      metadata: <String, Object?>{
        'firstSlot': firstSlot,
        'lastSlot': lastSlot,
      },
    );
  }

  Future<void> _ensureActiveTailSlot() {
    final existing = _tailSlotFuture;
    if (existing != null) return existing;
    final future = _appendActiveTailSlotIfNeeded();
    _tailSlotFuture = future;
    return future.whenComplete(() {
      if (identical(_tailSlotFuture, future)) {
        _tailSlotFuture = null;
      }
    });
  }

  Future<void> _appendActiveTailSlotIfNeeded() async {
    final index = _index;
    final slotsRaw = index?['slots'];
    if (index == null || slotsRaw is! List) return;
    final neededSlotIndex = _cursorSlotIndex + _rollingWindowSlotCount - 1;
    if (neededSlotIndex < slotsRaw.length) return;

    await _ensureManifestAccessReady();
    final active = await _loadActiveManifestDoc();
    final activeData = active.data() ?? const <String, dynamic>{};
    final rawTailSlot = activeData['tailSlot'];
    if (rawTailSlot is! Map) {
      _logTiming(
        'tail_slot_skip',
        metadata: <String, Object?>{
          'reason': 'missing_tail_slot',
          'cursorSlotIndex': _cursorSlotIndex,
          'slotCount': slotsRaw.length,
        },
      );
      return;
    }
    final tailSlot = Map<String, dynamic>.from(rawTailSlot);
    final path = (tailSlot['path'] ?? '').toString().trim();
    if (path.isEmpty) return;

    final existingPaths = slotsRaw
        .whereType<Map>()
        .map((slot) => (slot['path'] ?? '').toString())
        .toSet();
    if (existingPaths.contains(path)) {
      _logTiming(
        'tail_slot_skip',
        metadata: <String, Object?>{
          'reason': 'duplicate_path',
          'path': path,
          'cursorSlotIndex': _cursorSlotIndex,
          'slotCount': slotsRaw.length,
        },
      );
      return;
    }

    final nextSlotIndex = slotsRaw.length;
    slotsRaw.add(<String, Object?>{
      'slotId': (tailSlot['slotId'] ?? 'tail_slot_$nextSlotIndex').toString(),
      'slotIndex': nextSlotIndex,
      'itemCount': _parseSlotItemCount(tailSlot['itemCount']),
      'path': path,
      'date': (tailSlot['date'] ?? '').toString(),
    });
    index['slotCount'] = slotsRaw.length;
    index['itemCount'] = _sumSlotItemCount(slotsRaw);
    final currentManifestId = _manifestId.trim();
    final currentIndexPath = _indexPath.trim();
    if (currentManifestId.isNotEmpty && currentIndexPath.isNotEmpty) {
      await _writeIndexSnapshot(
        manifestId: currentManifestId,
        indexPath: currentIndexPath,
        index: index,
      );
    }
    _logTiming(
      'tail_slot_appended',
      metadata: <String, Object?>{
        'slotIndex': nextSlotIndex,
        'path': path,
        'date': (tailSlot['date'] ?? '').toString(),
        'slotCount': slotsRaw.length,
      },
    );
    unawaited(_ensureSlot(nextSlotIndex));
  }

  Future<List<PostsModel>> _loadSlot(int slotIndex) async {
    final path = _slotPath(slotIndex);
    if (path.isEmpty) return const <PostsModel>[];

    final cachedSlot = await _readSlotSnapshot(
      path: path,
    );
    if (cachedSlot != null) {
      _slots[slotIndex] = cachedSlot;
      _logTiming(
        'slot_cache_hit_disk',
        metadata: <String, Object?>{
          'slotIndex': slotIndex,
          'path': path,
          'count': cachedSlot.length,
        },
      );
      return cachedSlot;
    }

    final startedAt = DateTime.now();
    final bytes = await _storage.ref(path).getData(_maxSlotBytes);
    _logTiming(
      'slot_download_ready',
      metadata: <String, Object?>{
        'slotIndex': slotIndex,
        'path': path,
        'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
        'bytes': bytes?.length ?? 0,
      },
    );
    if (bytes == null || bytes.isEmpty) return const <PostsModel>[];
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) return const <PostsModel>[];
    final itemsRaw = decoded['items'];
    if (itemsRaw is! List) return const <PostsModel>[];
    final posts = <PostsModel>[];
    for (final raw in itemsRaw) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final docId = (map['docId'] ?? '').toString().trim();
      if (docId.isEmpty) continue;
      posts.add(PostsModel.fromMap(_manifestItemToPostMap(map), docId));
    }
    _slots[slotIndex] = posts;
    await _writeSlotSnapshot(path: path, rawJson: utf8.decode(bytes));
    _logTiming(
      'slot_parse_ready',
      metadata: <String, Object?>{
        'slotIndex': slotIndex,
        'count': posts.length,
        'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
      },
    );
    return posts;
  }

  String _slotPath(int slotIndex) {
    final index = _index;
    if (index == null) return '';
    final slotsRaw = index['slots'];
    if (slotsRaw is! List || slotIndex < 0 || slotIndex >= slotsRaw.length) {
      return '';
    }
    final slot = slotsRaw[slotIndex];
    if (slot is! Map) return '';
    return (slot['path'] ?? '').toString();
  }

  int _parseSlotItemCount(Object? raw) {
    if (raw is int && raw > 0) return raw;
    final parsed = int.tryParse('$raw') ?? 0;
    return parsed > 0 ? parsed : 240;
  }

  int _sumSlotItemCount(List<dynamic> slotsRaw) {
    var total = 0;
    for (final slot in slotsRaw) {
      if (slot is! Map) continue;
      total += _parseSlotItemCount(slot['itemCount']);
    }
    return total;
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??=
        await ensureLocalPreferenceRepository().sharedPreferences();
  }

  Future<Map<String, dynamic>?> _readIndexSnapshot({
    required String manifestId,
    required String indexPath,
  }) async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_localIndexPrefsKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final clearText = await _decodeManifestPrefsString(
      raw,
      prefsKey: _localIndexPrefsKey,
    );
    if (clearText == null || clearText.trim().isEmpty) {
      await prefs.remove(_localIndexPrefsKey);
      return null;
    }
    try {
      final decoded = jsonDecode(clearText);
      if (decoded is! Map) {
        await prefs.remove(_localIndexPrefsKey);
        return null;
      }
      final map = Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
      final storedManifestId = (map['manifestId'] ?? '').toString().trim();
      final storedIndexPath = (map['indexPath'] ?? '').toString().trim();
      if (storedManifestId != manifestId.trim() ||
          storedIndexPath != indexPath.trim()) {
        return null;
      }
      final index = map['index'];
      if (index is! Map) {
        await prefs.remove(_localIndexPrefsKey);
        return null;
      }
      await _rewritePlainManifestPrefsStringIfNeeded(
        raw,
        clearText,
        prefsKey: _localIndexPrefsKey,
      );
      return Map<String, dynamic>.from(index.cast<dynamic, dynamic>());
    } catch (_) {
      await prefs.remove(_localIndexPrefsKey);
      return null;
    }
  }

  Future<void> _writeIndexSnapshot({
    required String manifestId,
    required String indexPath,
    required Map<String, dynamic> index,
  }) async {
    final prefs = await _ensurePrefs();
    final payload = jsonEncode(<String, dynamic>{
      'manifestId': manifestId.trim(),
      'indexPath': indexPath.trim(),
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      'index': index,
    });
    await prefs.setString(
      _localIndexPrefsKey,
      await _encodeManifestPrefsString(payload, prefsKey: _localIndexPrefsKey),
    );
  }

  Future<List<PostsModel>?> _readSlotSnapshot({required String path}) async {
    final prefs = await _ensurePrefs();
    final prefsKey = _slotPrefsKey(path);
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final clearText = await _decodeManifestPrefsString(
      raw,
      prefsKey: prefsKey,
    );
    if (clearText == null || clearText.trim().isEmpty) {
      await prefs.remove(prefsKey);
      return null;
    }
    try {
      final posts = _parseSlotPosts(clearText);
      await _rewritePlainManifestPrefsStringIfNeeded(
        raw,
        clearText,
        prefsKey: prefsKey,
      );
      await _rememberCachedSlotPath(path);
      return posts;
    } catch (_) {
      await prefs.remove(prefsKey);
      await _removeCachedSlotPath(path);
      return null;
    }
  }

  Future<void> _writeSlotSnapshot({
    required String path,
    required String rawJson,
  }) async {
    final prefs = await _ensurePrefs();
    final prefsKey = _slotPrefsKey(path);
    await prefs.setString(
      prefsKey,
      await _encodeManifestPrefsString(rawJson, prefsKey: prefsKey),
    );
    await _rememberCachedSlotPath(path);
  }

  List<PostsModel> _parseSlotPosts(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) return const <PostsModel>[];
    final itemsRaw = decoded['items'];
    if (itemsRaw is! List) return const <PostsModel>[];
    final posts = <PostsModel>[];
    for (final raw in itemsRaw) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final docId = (map['docId'] ?? '').toString().trim();
      if (docId.isEmpty) continue;
      posts.add(PostsModel.fromMap(_manifestItemToPostMap(map), docId));
    }
    return posts;
  }

  Future<void> _rememberCachedSlotPath(String path) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) return;
    final prefs = await _ensurePrefs();
    final paths = await _readCachedSlotPaths();
    paths.remove(normalizedPath);
    paths.insert(0, normalizedPath);
    final overflow = paths.length > _maxCachedSlotPrefs
        ? paths.sublist(_maxCachedSlotPrefs)
        : const <String>[];
    final retained = paths.take(_maxCachedSlotPrefs).toList(growable: false);
    await prefs.setString(
      _localSlotListPrefsKey,
      await _encodeManifestPrefsString(
        jsonEncode(retained),
        prefsKey: _localSlotListPrefsKey,
      ),
    );
    for (final removedPath in overflow) {
      await prefs.remove(_slotPrefsKey(removedPath));
    }
  }

  Future<void> _removeCachedSlotPath(String path) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) return;
    final prefs = await _ensurePrefs();
    final paths = await _readCachedSlotPaths();
    if (!paths.remove(normalizedPath)) return;
    await prefs.setString(
      _localSlotListPrefsKey,
      await _encodeManifestPrefsString(
        jsonEncode(paths),
        prefsKey: _localSlotListPrefsKey,
      ),
    );
  }

  Future<List<String>> _readCachedSlotPaths() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_localSlotListPrefsKey);
    if (raw == null || raw.trim().isEmpty) return <String>[];
    final clearText = await _decodeManifestPrefsString(
      raw,
      prefsKey: _localSlotListPrefsKey,
    );
    if (clearText == null || clearText.trim().isEmpty) {
      await prefs.remove(_localSlotListPrefsKey);
      return <String>[];
    }
    try {
      final decoded = jsonDecode(clearText);
      if (decoded is! List) {
        await prefs.remove(_localSlotListPrefsKey);
        return <String>[];
      }
      await _rewritePlainManifestPrefsStringIfNeeded(
        raw,
        clearText,
        prefsKey: _localSlotListPrefsKey,
      );
      return decoded
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      await prefs.remove(_localSlotListPrefsKey);
      return <String>[];
    }
  }

  String _slotPrefsKey(String path) {
    final encoded = base64Url.encode(utf8.encode(path.trim()));
    return '$_localSlotPrefsPrefix:$encoded';
  }

  Future<String> _encodeManifestPrefsString(
    String raw, {
    required String prefsKey,
  }) {
    return ManifestDiskCipher.instance.encodeForDisk(
      raw,
      context: prefsKey,
    );
  }

  Future<String?> _decodeManifestPrefsString(
    String raw, {
    required String prefsKey,
  }) {
    return ManifestDiskCipher.instance.decodeFromDisk(
      raw,
      context: prefsKey,
    );
  }

  Future<void> _rewritePlainManifestPrefsStringIfNeeded(
    String stored,
    String clearText, {
    required String prefsKey,
  }) async {
    if (ManifestDiskCipher.instance.isEncryptedEnvelope(stored)) return;
    final prefs = await _ensurePrefs();
    await prefs.setString(
      prefsKey,
      await _encodeManifestPrefsString(clearText, prefsKey: prefsKey),
    );
  }

  Map<String, dynamic> _manifestItemToPostMap(Map<String, dynamic> item) {
    final stats = item['stats'] is Map
        ? Map<String, dynamic>.from(item['stats'] as Map)
        : const <String, dynamic>{};
    final flags = item['flags'] is Map
        ? Map<String, dynamic>.from(item['flags'] as Map)
        : const <String, dynamic>{};
    return <String, dynamic>{
      'userID': item['userID'],
      'authorNickname': item['authorNickname'],
      'authorDisplayName': item['authorDisplayName'],
      'authorAvatarUrl': item['authorAvatarUrl'],
      'rozet': item['rozet'],
      'metin': item['metin'],
      'thumbnail': item['thumbnail'],
      'img': const <String>[],
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
      'paylasGizliligi': flags['paylasGizliligi'] ?? 0,
      'isUploading': false,
    };
  }
}

ShortManifestRepository ensureShortManifestRepository() {
  if (Get.isRegistered<ShortManifestRepository>()) {
    return Get.find<ShortManifestRepository>();
  }
  return Get.put(ShortManifestRepository(), permanent: true);
}
