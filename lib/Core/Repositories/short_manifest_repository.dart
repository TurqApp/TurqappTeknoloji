import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';

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

class ShortManifestRepository extends GetxService {
  ShortManifestRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  String _manifestId = '';
  Map<String, dynamic>? _index;
  final Map<int, List<PostsModel>> _slots = <int, List<PostsModel>>{};
  int _cursorSlotIndex = 0;
  int _cursorItemIndex = 0;
  Future<void>? _loadFuture;

  Future<ShortManifestPageResult> takeNextPage({
    required int pageSize,
  }) async {
    final normalizedPageSize = pageSize <= 0 ? 1 : pageSize;
    await _ensureLoaded();

    final output = <PostsModel>[];
    while (output.length < normalizedPageSize) {
      final slot = await _ensureSlot(_cursorSlotIndex);
      if (slot.isEmpty) {
        break;
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

  Future<void> _loadManifest() async {
    final active =
        await _firestore.collection('shortManifest').doc('active').get();
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
      return;
    }

    final bytes = await _storage.ref(indexPath).getData(1024 * 1024);
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
    _cursorSlotIndex = 0;
    _cursorItemIndex = 0;
    await _ensureTwoSlotWindow();
  }

  void _reset() {
    _manifestId = '';
    _index = null;
    _slots.clear();
    _cursorSlotIndex = 0;
    _cursorItemIndex = 0;
  }

  Future<bool> _hasMore() async {
    final current = await _ensureSlot(_cursorSlotIndex);
    if (_cursorItemIndex < current.length) return true;
    return _slotPath(_cursorSlotIndex + 1).isNotEmpty;
  }

  Future<void> _ensureTwoSlotWindow() async {
    await _ensureSlot(_cursorSlotIndex);
    await _ensureSlot(_cursorSlotIndex + 1);
  }

  Future<List<PostsModel>> _ensureSlot(int slotIndex) async {
    if (slotIndex < 0) return const <PostsModel>[];
    final cached = _slots[slotIndex];
    if (cached != null) return cached;
    final path = _slotPath(slotIndex);
    if (path.isEmpty) return const <PostsModel>[];
    final bytes = await _storage.ref(path).getData(16 * 1024 * 1024);
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
