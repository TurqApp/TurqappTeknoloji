import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Services/app_firebase_storage.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
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

  String _manifestId = '';
  Map<String, dynamic>? _index;
  final Map<int, List<PostsModel>> _slots = <int, List<PostsModel>>{};
  final Map<int, Future<List<PostsModel>>> _slotLoads =
      <int, Future<List<PostsModel>>>{};
  int _cursorSlotIndex = 0;
  int _cursorItemIndex = 0;
  Future<void>? _loadFuture;

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
      final currentPath = _slotPath(_cursorSlotIndex);
      if (currentPath.isEmpty) {
        break;
      }
      final slot = await _ensureSlot(_cursorSlotIndex);
      if (slot.isEmpty) {
        _cursorSlotIndex++;
        _cursorItemIndex = 0;
        unawaited(_ensureTwoSlotWindow());
        continue;
      }
      while (_cursorItemIndex < slot.length &&
          output.length < normalizedPageSize) {
        output.add(slot[_cursorItemIndex]);
        _cursorItemIndex++;
      }
      if (_cursorItemIndex >= slot.length) {
        _cursorSlotIndex++;
        _cursorItemIndex = 0;
        unawaited(_ensureTwoSlotWindow());
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
      hasMore: _slotPath(_cursorSlotIndex).isNotEmpty || _slots.isNotEmpty,
    );
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
    await _ensureTwoSlotWindow();
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
      await _ensureTwoSlotWindow();
      _logTiming(
        'load_manifest_reuse',
        metadata: <String, Object?>{
          'manifestId': _manifestId,
          'elapsedMs': DateTime.now().difference(totalStartedAt).inMilliseconds,
        },
      );
      return;
    }

    final indexStartedAt = DateTime.now();
    final bytes = await _storage.ref(indexPath).getData(1024 * 1024);
    _logTiming(
      'index_download_ready',
      metadata: <String, Object?>{
        'path': indexPath,
        'elapsedMs': DateTime.now().difference(indexStartedAt).inMilliseconds,
        'bytes': bytes?.length ?? 0,
      },
    );
    if (bytes == null || bytes.isEmpty) {
      _reset();
      return;
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      _reset();
      return;
    }
    _manifestId = nextManifestId;
    _index = Map<String, dynamic>.from(decoded);
    _slots.clear();
    _slotLoads.clear();
    _cursorSlotIndex = 0;
    _cursorItemIndex = 0;
    await _restorePersistedCursorIfNeeded();
    await _ensureSlot(_cursorSlotIndex);
    unawaited(_primeUpcomingSlots());
    _logTiming(
      'load_manifest_complete',
      metadata: <String, Object?>{
        'manifestId': _manifestId,
        'slotCount': (_index?['slots'] as List?)?.length ?? 0,
        'elapsedMs': DateTime.now().difference(totalStartedAt).inMilliseconds,
      },
    );
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

  Future<void> _restorePersistedCursorIfNeeded() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty || _manifestId.isEmpty) return;
    final persisted = await ensureShortResumeStateStore().load(
      userId: userId,
    );
    if (persisted == null) return;
    if (persisted.manifestId != _manifestId) return;
    _cursorSlotIndex =
        persisted.cursorSlotIndex < 0 ? 0 : persisted.cursorSlotIndex;
    _cursorItemIndex =
        persisted.cursorItemIndex < 0 ? 0 : persisted.cursorItemIndex;
    _logTiming(
      'cursor_restore_ready',
      metadata: <String, Object?>{
        'manifestId': _manifestId,
        'slotIndex': _cursorSlotIndex,
        'itemIndex': _cursorItemIndex,
      },
    );
  }

  void _reset() {
    _manifestId = '';
    _index = null;
    _slots.clear();
    _slotLoads.clear();
    _cursorSlotIndex = 0;
    _cursorItemIndex = 0;
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

  Future<void> _ensureTwoSlotWindow() async {
    final startedAt = DateTime.now();
    final primarySlot = _cursorSlotIndex;
    final secondarySlot = _cursorSlotIndex + 1;
    await Future.wait<void>(<Future<void>>[
      _ensureSlot(primarySlot).then((_) {}),
      _ensureSlot(secondarySlot).then((_) {}),
    ]);
    _logTiming(
      'two_slot_window_ready',
      metadata: <String, Object?>{
        'primarySlot': primarySlot,
        'secondarySlot': secondarySlot,
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

  Future<void> _primeUpcomingSlots() async {
    final primarySlot = _cursorSlotIndex;
    final secondarySlot = _cursorSlotIndex + 1;
    await Future.wait<void>(<Future<void>>[
      _ensureSlot(primarySlot).then((_) {}),
      _ensureSlot(secondarySlot).then((_) {}),
    ]);
    _logTiming(
      'upcoming_slots_primed',
      metadata: <String, Object?>{
        'primarySlot': primarySlot,
        'secondarySlot': secondarySlot,
      },
    );
  }

  Future<List<PostsModel>> _loadSlot(int slotIndex) async {
    final path = _slotPath(slotIndex);
    if (path.isEmpty) return const <PostsModel>[];
    final startedAt = DateTime.now();
    final bytes = await _storage.ref(path).getData(16 * 1024 * 1024);
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
