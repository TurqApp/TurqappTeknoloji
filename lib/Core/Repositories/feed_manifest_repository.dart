import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
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
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  static const int _maxSlotBytes = 16 * 1024 * 1024;
  static const int _maxConcurrentSlotLoads = 4;
  static const Duration _activeRetryDelay = Duration(milliseconds: 700);
  static const Duration _authReadyTimeout = Duration(milliseconds: 1600);
  static const Duration _slotDownloadTimeout = Duration(milliseconds: 1800);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  String _manifestId = '';
  int _generatedAt = 0;
  bool _startupAuthPrimed = false;
  final Map<String, List<FeedManifestEntry>> _slotEntries =
      <String, List<FeedManifestEntry>>{};
  Future<FeedManifestPoolResult>? _loadFuture;

  Future<FeedManifestPoolResult> loadRollingPool({
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      final existing = _loadFuture;
      if (existing != null) return existing;
    }
    final future = _loadRollingPool(forceRefresh: forceRefresh);
    _loadFuture = future;
    return future.whenComplete(() {
      if (identical(_loadFuture, future)) {
        _loadFuture = null;
      }
    });
  }

  Future<FeedManifestPoolResult> _loadRollingPool({
    required bool forceRefresh,
  }) async {
    final active = await _loadActiveManifestDoc();
    final activeData = active.data() ?? const <String, dynamic>{};
    final nextManifestId = (activeData['manifestId'] ?? '').toString().trim();
    final generatedAt = int.tryParse('${activeData['generatedAt'] ?? 0}') ?? 0;
    final slotRefs = _parseSlotRefs(activeData['slots']);

    if (nextManifestId.isEmpty || slotRefs.isEmpty) {
      _reset();
      return const FeedManifestPoolResult(
        manifestId: '',
        entries: <FeedManifestEntry>[],
        slotCount: 0,
        loadedSlotCount: 0,
        generatedAt: 0,
      );
    }

    final manifestChanged = nextManifestId != _manifestId;
    if (manifestChanged) {
      _slotEntries.clear();
    }
    _manifestId = nextManifestId;
    _generatedAt = generatedAt;

    await _ensureSlotsLoaded(slotRefs, forceRefresh: forceRefresh);
    final entries = <FeedManifestEntry>[];
    var loadedSlotCount = 0;
    for (final slot in slotRefs) {
      final slotEntries = _slotEntries[slot.path];
      if (slotEntries == null) continue;
      loadedSlotCount++;
      entries.addAll(slotEntries);
    }

    return FeedManifestPoolResult(
      manifestId: _manifestId,
      entries: entries,
      slotCount: slotRefs.length,
      loadedSlotCount: loadedSlotCount,
      generatedAt: _generatedAt,
    );
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
    final shouldForceRefresh = forceTokenRefresh || !_startupAuthPrimed;
    await CurrentUserService.instance.ensureAuthReady(
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
      await Future.wait(batch.map(_loadSlot));
    }
  }

  Future<void> _loadSlot(_FeedManifestSlotRef slot) async {
    try {
      final bytes = await _storage
          .ref(slot.path)
          .getData(_maxSlotBytes)
          .timeout(_slotDownloadTimeout);
      if (bytes == null || bytes.isEmpty) {
        _slotEntries[slot.path] = const <FeedManifestEntry>[];
        return;
      }
      _slotEntries[slot.path] = parseSlotEntries(
        utf8.decode(bytes),
        fallbackSlotId: slot.slotId,
        slotPath: slot.path,
      );
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
    _slotEntries.clear();
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
      'img': posters,
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
}

FeedManifestRepository ensureFeedManifestRepository() {
  if (Get.isRegistered<FeedManifestRepository>()) {
    return Get.find<FeedManifestRepository>();
  }
  return Get.put(FeedManifestRepository(), permanent: true);
}
