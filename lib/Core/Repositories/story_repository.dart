import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Models/story_comment_model.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'story_repository_helpers_part.dart';

class DeletedStoryCachePayload {
  const DeletedStoryCachePayload({
    required this.stories,
    required this.deletedAtById,
    required this.deleteReasonById,
  });

  final List<StoryModel> stories;
  final Map<String, int> deletedAtById;
  final Map<String, String> deleteReasonById;
}

class StoryFetchResult {
  const StoryFetchResult({
    required this.users,
    required this.cacheHit,
  });

  final List<StoryUserModel> users;
  final bool cacheHit;
}

class StoryEngagementSnapshot {
  const StoryEngagementSnapshot({
    required this.likeCount,
    required this.isLiked,
    required this.reactionCounts,
    required this.myReaction,
  });

  final int likeCount;
  final bool isLiked;
  final Map<String, int> reactionCounts;
  final String myReaction;
}

class StoryRepository extends GetxService {
  static const Duration _storyRowCacheTtl = Duration(minutes: 15);
  static const Duration _deletedStoriesCacheTtl = Duration(hours: 12);
  static const int _deletedStoriesCacheLimit = 100;

  UserProfileCacheService get _userCache {
    if (Get.isRegistered<UserProfileCacheService>()) {
      return Get.find<UserProfileCacheService>();
    }
    return Get.put(UserProfileCacheService(), permanent: true);
  }
  final UserRepository _userRepository = UserRepository.ensure();

  String? _storyRowCacheDirectoryPath;
  SharedPreferences? _prefs;

  static DateTime get _storyExpiryCutoff =>
      DateTime.now().subtract(const Duration(hours: 24));

  int _asEpochMillis(dynamic value, {int fallback = 0}) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is num) return value.toInt();
    if (value is String) {
      final numeric = int.tryParse(value);
      if (numeric != null) return numeric;
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
    return fallback;
  }

  List<Map<String, dynamic>> _normalizeStoryElements(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.map<Map<String, dynamic>>((item) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item.cast<dynamic, dynamic>());
        final positionRaw = map['position'];
        if (positionRaw is Map) {
          map['position'] = Map<String, dynamic>.from(
            positionRaw.cast<dynamic, dynamic>(),
          );
        }
        return map;
      }
      return const <String, dynamic>{};
    }).toList(growable: false);
  }

  static StoryRepository ensure() {
    if (Get.isRegistered<StoryRepository>()) {
      return Get.find<StoryRepository>();
    }
    return Get.put(StoryRepository(), permanent: true);
  }

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_storyRowCacheDirectoryPath != null) return;
    final dir = await getApplicationSupportDirectory();
    final storyDir = Directory('${dir.path}/story_mini_cache');
    if (!await storyDir.exists()) {
      await storyDir.create(recursive: true);
    }
    _storyRowCacheDirectoryPath = storyDir.path;
  }

  String? _storyRowCachePathForOwner(String ownerUid) {
    final dir = _storyRowCacheDirectoryPath;
    final normalizedUid = ownerUid.trim();
    if (dir == null || normalizedUid.isEmpty) return null;
    return '$dir/story_row_v2_$normalizedUid.json';
  }

  Future<StoryFetchResult> fetchStoryUsers({
    required int limit,
    required bool cacheFirst,
    required String currentUid,
    required List<String> blockedUserIds,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snap;
    var cacheHit = false;

    if (cacheFirst) {
      snap = await PerformanceService.traceOperation(
        'story_load_cache_first',
        () => FirebaseFirestore.instance
            .collection('stories')
            .orderBy('createdDate', descending: true)
            .limit(limit)
            .get(const GetOptions(source: Source.cache)),
      );
      cacheHit = snap.docs.isNotEmpty;

      if (snap.docs.isEmpty) {
        snap = await PerformanceService.traceOperation(
          'story_load_network_fallback',
          () => FirebaseFirestore.instance
              .collection('stories')
              .orderBy('createdDate', descending: true)
              .limit(limit)
              .get(),
        );
      }
    } else {
      snap = await PerformanceService.traceOperation(
        'story_load_network',
        () => FirebaseFirestore.instance
            .collection('stories')
            .orderBy('createdDate', descending: true)
            .limit(limit)
            .get(),
      );
    }

    final userStories = <String, List<StoryModel>>{};
    final storyEmbeddedUserMeta = <String, Map<String, dynamic>>{};
    final expiry = DateTime.now().subtract(const Duration(hours: 24));

    for (final doc in snap.docs) {
      try {
        final data = doc.data();
        if ((data['deleted'] ?? false) == true) continue;
        final story = StoryModel.fromDoc(doc);
        if (story.createdAt.isBefore(expiry)) continue;
        userStories.putIfAbsent(story.userId, () => <StoryModel>[]);
        userStories[story.userId]!.add(story);

        final embeddedNickname = (data['nickname'] ?? '').toString().trim();
        final embeddedAvatar = (data['avatarUrl'] ?? '').toString().trim();
        final embeddedUsername = (data['username'] ?? '').toString().trim();
        if (embeddedNickname.isNotEmpty ||
            embeddedAvatar.isNotEmpty ||
            embeddedUsername.isNotEmpty) {
          storyEmbeddedUserMeta[story.userId] = <String, dynamic>{
            'nickname': embeddedNickname,
            'avatarUrl': embeddedAvatar,
            'username': embeddedUsername,
            'firstName': (data['firstName'] ?? '').toString(),
            'lastName': (data['lastName'] ?? '').toString(),
            'isPrivate': data['isPrivate'] == true,
          };
        }
      } catch (_) {}
    }

    final userIds = userStories.keys.toList(growable: false);
    final userDataMap = await _userCache.getProfiles(
      userIds,
      preferCache: true,
      cacheOnly: false,
    );
    final missingUserIds =
        userIds.where((id) => userDataMap[id] == null).toList(growable: false);
    if (missingUserIds.isNotEmpty) {
      userDataMap.addAll(await _loadMissingProfilesFromUsers(missingUserIds));
    }

    final followingIds = currentUid.isEmpty
        ? <String>{}
        : await FollowRepository.ensure()
            .getFollowingIds(currentUid, preferCache: true);
    final blockedSet = blockedUserIds.toSet();
    final current = CurrentUserService.instance;
    final users = <StoryUserModel>[];

    for (final entry in userStories.entries) {
      final userId = entry.key;
      if (blockedSet.contains(userId)) continue;

      final stories = [...entry.value]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final rawData = userDataMap[userId] ?? storyEmbeddedUserMeta[userId];
      final data = Map<String, dynamic>.from(
        rawData ?? _fallbackUserData(userId, current),
      );

      final isPrivate = (data['isPrivate'] ?? false) == true;
      final isMine = currentUid.isNotEmpty && userId == currentUid;
      final iFollow = followingIds.contains(userId);
      if (isPrivate && !isMine && !iFollow) continue;

      final resolvedNickname = _resolveStoryNickname(data).trim();
      users.add(
        StoryUserModel(
          nickname: resolvedNickname.isNotEmpty
              ? resolvedNickname
              : (data['nickname']?.toString().trim().isNotEmpty == true
                  ? data['nickname'].toString().trim()
                  : (isMine
                      ? (current.nickname.isNotEmpty ? current.nickname : 'sen')
                      : 'kullanici')),
          avatarUrl: _resolveAvatar(data),
          fullName: "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}",
          userID: userId,
          stories: stories,
        ),
      );
    }

    return StoryFetchResult(users: users, cacheHit: cacheHit);
  }

  Future<void> saveStoryRowCache(
    List<StoryUserModel> list, {
    required String ownerUid,
  }) async {
    if (list.isEmpty) return;
    await _ensureInitialized();
    final path = _storyRowCachePathForOwner(ownerUid);
    if (path == null) return;
    try {
      final payload = {
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'ownerUid': ownerUid,
        'users': list.map((u) => u.toCacheMap()).toList(),
      };
      final file = File(path);
      final tmp = File('$path.tmp');
      await tmp.writeAsString(jsonEncode(payload), flush: true);
      await tmp.rename(file.path);
    } catch (_) {}
  }

  Future<List<StoryUserModel>> restoreStoryRowCache({
    required String ownerUid,
    bool allowExpired = false,
  }) async {
    await _ensureInitialized();
    final path = _storyRowCachePathForOwner(ownerUid);
    if (path == null) return const <StoryUserModel>[];
    try {
      final file = File(path);
      if (!await file.exists()) return const <StoryUserModel>[];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const <StoryUserModel>[];
      final data = jsonDecode(raw);
      if (data is! Map) return const <StoryUserModel>[];
      final cacheOwnerUid = (data['ownerUid'] ?? '').toString();
      if (cacheOwnerUid.isNotEmpty && cacheOwnerUid != ownerUid) {
        return const <StoryUserModel>[];
      }
      final savedAt = (data['savedAt'] as num?)?.toInt() ?? 0;
      if (!allowExpired && savedAt > 0) {
        final age = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(savedAt),
        );
        if (age > _storyRowCacheTtl) return const <StoryUserModel>[];
      }
      final usersJson =
          (data['users'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final expiryCutoff = _storyExpiryCutoff;
      return usersJson
          .map(StoryUserModel.fromCacheMap)
          .map((user) {
            if (allowExpired) return user;
            final activeStories = user.stories
                .where((story) => story.createdAt.isAfter(expiryCutoff))
                .toList(growable: false)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return StoryUserModel(
              nickname: user.nickname,
              avatarUrl: user.avatarUrl,
              fullName: user.fullName,
              userID: user.userID,
              stories: activeStories,
            );
          })
          .where((u) => u.userID.isNotEmpty)
          .where((u) => u.stories.isNotEmpty || u.userID == ownerUid)
          .toList(growable: false);
    } catch (_) {
      return const <StoryUserModel>[];
    }
  }

  Future<void> clearStoryRowCacheForCurrentUser(String ownerUid) async {
    await _ensureInitialized();
    final path = _storyRowCachePathForOwner(ownerUid);
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<Map<String, StoryModel>> fetchStoriesByIds(
    List<String> storyIds,
  ) async {
    final ids = storyIds.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <String, StoryModel>{};
    final stories = <String, StoryModel>{};
    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize > ids.length) ? ids.length : i + chunkSize;
      final chunk = ids.sublist(i, end);
      final snap = await FirebaseFirestore.instance
          .collection('stories')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        try {
          final data = doc.data();
          if ((data['deleted'] ?? false) == true) continue;
          final story = StoryModel.fromDoc(doc);
          stories[story.id] = story;
        } catch (_) {}
      }
    }
    return stories;
  }

  Future<StoryModel?> fetchStoryById(
    String storyId, {
    bool preferCache = true,
  }) async {
    final raw = await getStoryRaw(storyId, preferCache: preferCache);
    if (raw == null || raw.isEmpty) return null;
    return StoryModel.fromCacheMap(<String, dynamic>{
      'id': storyId,
      ...raw,
    });
  }

  Future<List<StoryModel>> fetchActiveStoriesByMusicId(
    String musicId, {
    int limit = 60,
  }) async {
    final cleanId = musicId.trim();
    if (cleanId.isEmpty) return const <StoryModel>[];
    final snap = await FirebaseFirestore.instance
        .collection('stories')
        .where('musicId', isEqualTo: cleanId)
        .limit(limit)
        .get();
    final expiry = DateTime.now().subtract(const Duration(hours: 24));
    return snap.docs
        .map((doc) {
          try {
            final data = doc.data();
            if ((data['deleted'] ?? false) == true) {
              return null;
            }
            return StoryModel.fromDoc(doc);
          } catch (_) {
            return null;
          }
        })
        .whereType<StoryModel>()
        .where((story) => story.createdAt.isAfter(expiry))
        .toList(growable: false);
  }

  Future<void> markExpiredStoriesDeleted(String uid) async {
    try {
      final expiry = DateTime.now().subtract(const Duration(hours: 24));
      final expiredSnap = await FirebaseFirestore.instance
          .collection('stories')
          .where('userId', isEqualTo: uid)
          .get();
      var didMutate = false;

      for (final doc in expiredSnap.docs) {
        try {
          final model = StoryModel.fromDoc(doc);
          if (model.createdAt.isAfter(expiry)) continue;
          await FirebaseFirestore.instance
              .collection('stories')
              .doc(model.id)
              .update({
            'deleted': true,
            'deletedAt': DateTime.now().millisecondsSinceEpoch,
            'deleteReason': 'expired',
          });
          didMutate = true;
        } catch (_) {}
      }
      if (didMutate) {
        await clearDeletedStoriesCache(uid);
      }
    } catch (_) {}
  }

  Future<String> softDeleteStory(
    String storyId, {
    String reason = 'manual',
  }) async {
    if (storyId.isEmpty) return '';
    final raw = await getStoryRaw(storyId, preferCache: true) ?? const {};
    final musicId = (raw['musicId'] ?? '').toString().trim();
    final uid = (raw['userId'] ?? '').toString().trim();
    await FirebaseFirestore.instance.collection('stories').doc(storyId).update({
      'deleted': true,
      'deletedAt': DateTime.now().millisecondsSinceEpoch,
      'deleteReason': reason,
    });
    if (uid.isNotEmpty) {
      await clearDeletedStoriesCache(uid);
    }
    return musicId;
  }

  Future<void> restoreDeletedStory(String storyId) async {
    if (storyId.isEmpty) return;
    final raw = await getStoryRaw(storyId, preferCache: true) ?? const {};
    await FirebaseFirestore.instance.collection('stories').doc(storyId).update({
      'deleted': false,
      'deletedAt': 0,
      'deleteReason': FieldValue.delete(),
    });
    final uid = (raw['userId'] ?? '').toString().trim();
    if (uid.isNotEmpty) {
      await clearDeletedStoriesCache(uid);
    }
  }

  Future<String> repostDeletedStory(StoryModel story) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? story.userId;
    if (uid.trim().isEmpty) return '';

    final docRef = FirebaseFirestore.instance.collection('stories').doc();
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final storyId = docRef.id;

    final serialized = story.elements
        .map(
          (e) => <String, dynamic>{
            'type': e.type.toString().split('.').last,
            'content': e.content,
            'width': e.width,
            'height': e.height,
            'position': {'x': e.position.dx, 'y': e.position.dy},
            'rotation': e.rotation,
            'zIndex': e.zIndex,
            'isMuted': e.isMuted,
            'fontSize': e.fontSize,
            'aspectRatio': e.aspectRatio,
            'textColor': e.textColor,
            'textBgColor': e.textBgColor,
            'hasTextBg': e.hasTextBg,
            'textAlign': e.textAlign,
            'fontWeight': e.fontWeight,
            'italic': e.italic,
            'underline': e.underline,
            'shadowBlur': e.shadowBlur,
            'shadowOpacity': e.shadowOpacity,
            'fontFamily': e.fontFamily,
            'hasOutline': e.hasOutline,
            'outlineColor': e.outlineColor,
            'stickerType': e.stickerType,
            'stickerData': e.stickerData,
          },
        )
        .toList(growable: false);

    await docRef.set({
      'userId': uid,
      'createdDate': createdAt,
      'backgroundColor': story.backgroundColor.toARGB32(),
      'musicId': story.musicId,
      'musicUrl': story.musicUrl,
      'musicTitle': story.musicTitle,
      'musicArtist': story.musicArtist,
      'musicCoverUrl': story.musicCoverUrl,
      'elements': serialized,
      'deleted': false,
      'deletedAt': 0,
    });

    if (story.musicId.trim().isNotEmpty) {
      final track = await StoryMusicLibraryService.instance.fetchTrackById(
        story.musicId,
        preferCache: true,
      );
      if (track != null) {
        await StoryMusicLibraryService.instance.recordStoryUsage(
          track: track,
          storyId: storyId,
          userId: uid,
          createdAt: createdAt,
        );
      }
    }

    return storyId;
  }

  Future<DeletedStoryCachePayload?> restoreDeletedStoriesCache(
      String uid) async {
    await _ensureInitialized();
    try {
      final raw = _prefs?.getString(_deletedStoriesCacheKey(uid));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final savedAtMs = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAtMs <= 0) return null;
      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(savedAtMs),
      );
      if (cacheAge > _deletedStoriesCacheTtl) return null;
      final items = (decoded['items'] as List?) ?? const [];
      final restoredStories = <StoryModel>[];
      final restoredDeletedAt = <String, int>{};
      final restoredReasons = <String, String>{};
      for (final item in items) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item.cast<String, dynamic>());
        final storyMap = Map<String, dynamic>.from(
          (map['story'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
        if (storyMap.isEmpty) continue;
        final story = StoryModel.fromCacheMap(storyMap);
        restoredStories.add(story);
        restoredDeletedAt[story.id] = (map['deletedAt'] as num?)?.toInt() ?? 0;
        final reason = (map['deleteReason'] ?? '').toString();
        if (reason.isNotEmpty) restoredReasons[story.id] = reason;
      }
      if (restoredStories.isEmpty) return null;
      return DeletedStoryCachePayload(
        stories: restoredStories,
        deletedAtById: restoredDeletedAt,
        deleteReasonById: restoredReasons,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> persistDeletedStoriesCache({
    required String uid,
    required List<StoryModel> stories,
    required Map<String, int> deletedAtById,
    required Map<String, String> deleteReasonById,
  }) async {
    await _ensureInitialized();
    try {
      final items = stories
          .map((story) => <String, dynamic>{
                'story': story.toCacheMap(),
                'deletedAt': deletedAtById[story.id] ?? 0,
                'deleteReason': deleteReasonById[story.id] ?? '',
              })
          .toList();
      await _prefs?.setString(
        _deletedStoriesCacheKey(uid),
        jsonEncode({
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'items': items,
        }),
      );
    } catch (_) {}
  }

  Future<void> clearDeletedStoriesCache(String uid) async {
    if (uid.isEmpty) return;
    await _ensureInitialized();
    try {
      await _prefs?.remove(_deletedStoriesCacheKey(uid));
    } catch (_) {}
  }

  Future<DeletedStoryCachePayload> fetchDeletedStories(String uid) async {
    final items = <StoryModel>[];
    final deletedAtById = <String, int>{};
    final deleteReasonById = <String, String>{};
    final seenStoryIds = <String>{};
    var deletedDocCount = 0;
    var parseErrorCount = 0;

    try {
      final archiveSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('DeletedStories')
          .get();

      for (final d in archiveSnap.docs) {
        try {
          final data = d.data();
          final storyId = (data['storyId'] ?? d.id).toString().trim();
          if (storyId.isEmpty || !seenStoryIds.add(storyId)) continue;
          deletedDocCount++;

          final createdAtMs = _asEpochMillis(
            data['createdAtOriginal'] ?? data['createdDate'],
            fallback: DateTime.now().millisecondsSinceEpoch,
          );

          final model = StoryModel.fromCacheMap(<String, dynamic>{
            'id': storyId,
            'userId': (data['userId'] ?? uid).toString(),
            'createdDate': createdAtMs,
            'backgroundColor':
                _asEpochMillis(data['backgroundColor'], fallback: 0xFF000000),
            'musicId': (data['musicId'] ?? '').toString(),
            'musicUrl': (data['musicUrl'] ?? '').toString(),
            'musicTitle': (data['musicTitle'] ?? '').toString(),
            'musicArtist': (data['musicArtist'] ?? '').toString(),
            'musicCoverUrl': (data['musicCoverUrl'] ?? '').toString(),
            'elements': _normalizeStoryElements(data['elements']),
          });
          items.add(model);
          deletedAtById[model.id] = _asEpochMillis(data['deletedAt']);
          final reason =
              (data['reason'] ?? data['deleteReason'] ?? '').toString().trim();
          if (reason.isNotEmpty) deleteReasonById[model.id] = reason;
        } catch (e) {
          parseErrorCount++;
          debugPrint('Deleted archive parse skipped');
        }
      }
    } catch (e) {
      debugPrint('Deleted stories archive fetch error: $e');
    }

    final snap = await FirebaseFirestore.instance
        .collection('stories')
        .where('userId', isEqualTo: uid)
        .get();

    for (final d in snap.docs) {
      try {
        final data = d.data();
        if ((data['deleted'] ?? false) != true) continue;
        if (!seenStoryIds.add(d.id)) continue;
        deletedDocCount++;
        final model = StoryModel.fromCacheMap(<String, dynamic>{
          'id': d.id,
          ...data,
          'createdDate': _asEpochMillis(
            data['createdDate'],
            fallback: DateTime.now().millisecondsSinceEpoch,
          ),
          'backgroundColor':
              _asEpochMillis(data['backgroundColor'], fallback: 0xFF000000),
          'elements': _normalizeStoryElements(data['elements']),
        });
        items.add(model);
        final delAt = _asEpochMillis(data['deletedAt']);
        deletedAtById[model.id] = delAt;
        final reason = (data['deleteReason'] ?? '').toString();
        if (reason.isNotEmpty) deleteReasonById[model.id] = reason;
      } catch (e) {
        parseErrorCount++;
        debugPrint('Deleted story parse skipped');
      }
    }

    debugPrint(
      'Deleted stories fetch: liveDocs=${snap.docs.length} '
      'deletedDocs=$deletedDocCount parsed=${items.length} parseErrors=$parseErrorCount '
      'reasons=${deleteReasonById.length}',
    );

    items.sort((a, b) {
      final aDeletedAt = deletedAtById[a.id] ?? 0;
      final bDeletedAt = deletedAtById[b.id] ?? 0;
      return bDeletedAt.compareTo(aDeletedAt);
    });

    final trimmed =
        items.take(_deletedStoriesCacheLimit).toList(growable: false);
    final keptIds = trimmed.map((e) => e.id).toSet();
    deletedAtById.removeWhere((key, _) => !keptIds.contains(key));
    deleteReasonById.removeWhere((key, _) => !keptIds.contains(key));

    return DeletedStoryCachePayload(
      stories: trimmed,
      deletedAtById: deletedAtById,
      deleteReasonById: deleteReasonById,
    );
  }

  Future<Map<String, dynamic>?> getStoryRaw(
    String storyId, {
    bool preferCache = true,
  }) async {
    if (storyId.isEmpty) return null;
    if (preferCache) {
      try {
        final cached = await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .get(const GetOptions(source: Source.cache));
        if (cached.exists) {
          return Map<String, dynamic>.from(cached.data() ?? const {});
        }
      } catch (_) {}
    }
    final server = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .get();
    if (!server.exists) return null;
    return Map<String, dynamic>.from(server.data() ?? const {});
  }

  Future<List<StoryModel>> getStoriesForUser(
    String userId, {
    bool preferCache = true,
    bool includeDeleted = false,
  }) async {
    if (userId.isEmpty) return const <StoryModel>[];

    Future<QuerySnapshot<Map<String, dynamic>>> runQuery(GetOptions? options) {
      final query = FirebaseFirestore.instance
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .orderBy('createdDate', descending: true);
      if (options == null) return query.get();
      return query.get(options);
    }

    QuerySnapshot<Map<String, dynamic>> snap;
    if (preferCache) {
      try {
        snap = await runQuery(const GetOptions(source: Source.cache));
        if (snap.docs.isEmpty) {
          snap = await runQuery(null);
        }
      } catch (_) {
        snap = await runQuery(null);
      }
    } else {
      snap = await runQuery(null);
    }

    final expiryCutoff = _storyExpiryCutoff;
    final stories = snap.docs
        .where(
          (doc) => includeDeleted || (doc.data()['deleted'] ?? false) != true,
        )
        .map(StoryModel.fromDoc)
        .where(
            (story) => includeDeleted || story.createdAt.isAfter(expiryCutoff))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return stories;
  }

  Future<List<String>> fetchStoryViewerIds(
    String storyId, {
    int limit = 50,
  }) async {
    if (storyId.isEmpty) return const <String>[];
    final snap = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Viewers')
        .limit(limit)
        .get();
    return snap.docs.map((doc) => doc.id).toList(growable: false);
  }

  Future<int> fetchStoryViewerCount(String storyId) async {
    if (storyId.isEmpty) return 0;
    final counts = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Viewers')
        .count()
        .get();
    return counts.count ?? 0;
  }

  Future<List<StoryCommentModel>> fetchStoryComments(
    String storyId, {
    int limit = 50,
  }) async {
    if (storyId.isEmpty) return const <StoryCommentModel>[];
    final snap = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Yorumlar')
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => StoryCommentModel.fromMap(doc.data(), docID: doc.id))
        .toList(growable: false);
  }

  Future<int> fetchStoryCommentCount(String storyId) async {
    if (storyId.isEmpty) return 0;
    final counts = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Yorumlar')
        .count()
        .get();
    return counts.count ?? 0;
  }

  Future<StoryCommentModel?> fetchLatestStoryComment(String storyId) async {
    if (storyId.isEmpty) return null;
    final snap = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Yorumlar')
        .limit(1)
        .orderBy('timeStamp', descending: true)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return StoryCommentModel.fromMap(doc.data(), docID: doc.id);
  }

  Future<void> addStoryComment(
    String storyId, {
    required String userId,
    required String text,
    required String gif,
  }) async {
    if (storyId.isEmpty || userId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Yorumlar')
        .add({
      'userID': userId,
      'metin': text,
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'gif': gif,
    });
  }

  Future<void> deleteStoryComment(
    String storyId, {
    required String commentId,
  }) async {
    if (storyId.isEmpty || commentId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Yorumlar')
        .doc(commentId)
        .delete();
  }

  Future<void> addScreenshotEvent(
    String storyId, {
    required String userId,
  }) async {
    if (storyId.isEmpty || userId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('screenshots')
        .doc(userId)
        .set({
      'userId': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> markUserStoriesFullyViewed({
    required String currentUid,
    required String targetUserId,
    required int latestStoryTime,
  }) async {
    if (currentUid.isEmpty || targetUserId.isEmpty || latestStoryTime <= 0) {
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('readStories')
        .doc(targetUserId)
        .set({
      'storyId': targetUserId,
      'readDate': latestStoryTime,
      'lastSeenAt': latestStoryTime,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<List<String>> fetchStoryLikeIds(String storyId) async {
    if (storyId.isEmpty) return const <String>[];
    final snap = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('likes')
        .get();
    return snap.docs.map((doc) => doc.id).toList(growable: false);
  }

  Future<int> fetchStoryLikeCount(String storyId) async {
    if (storyId.isEmpty) return 0;
    final counts = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('likes')
        .count()
        .get();
    return counts.count ?? 0;
  }

  Future<StoryEngagementSnapshot> fetchStoryEngagement(
    String storyId, {
    required String currentUid,
  }) async {
    if (storyId.isEmpty) {
      return const StoryEngagementSnapshot(
        likeCount: 0,
        isLiked: false,
        reactionCounts: <String, int>{},
        myReaction: '',
      );
    }

    final likeCountFuture = fetchStoryLikeCount(storyId);
    final likeStatusFuture = currentUid.trim().isEmpty
        ? Future<bool>.value(false)
        : FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .collection('likes')
            .doc(currentUid)
            .get()
            .then((doc) => doc.exists)
            .catchError((_) => false);
    final storyRawFuture = getStoryRaw(storyId, preferCache: true);

    final results = await Future.wait<dynamic>([
      likeCountFuture,
      likeStatusFuture,
      storyRawFuture,
    ]);

    final likeCount = results[0] as int? ?? 0;
    final isLiked = results[1] as bool? ?? false;
    final data = results[2] as Map<String, dynamic>?;

    final reactionCounts = <String, int>{};
    var myReaction = '';
    if (data != null && data['reactions'] is Map) {
      final reactions = Map<String, dynamic>.from(data['reactions']);
      for (final entry in reactions.entries) {
        final users = List<String>.from(entry.value ?? const <String>[]);
        reactionCounts[entry.key] = users.length;
        if (currentUid.isNotEmpty && users.contains(currentUid)) {
          myReaction = entry.key;
        }
      }
    }

    return StoryEngagementSnapshot(
      likeCount: likeCount,
      isLiked: isLiked,
      reactionCounts: reactionCounts,
      myReaction: myReaction,
    );
  }

  Future<bool> toggleStoryLike(
    String storyId, {
    required String currentUid,
  }) async {
    if (storyId.isEmpty || currentUid.trim().isEmpty) return false;
    final docRef = FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('likes')
        .doc(currentUid);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
      return false;
    }
    await docRef.set({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
    });
    return true;
  }

  Future<String> toggleStoryReaction(
    String storyId, {
    required String currentUid,
    required String emoji,
    required String currentReaction,
  }) async {
    if (storyId.isEmpty || currentUid.trim().isEmpty || emoji.trim().isEmpty) {
      return currentReaction;
    }
    final docRef =
        FirebaseFirestore.instance.collection('stories').doc(storyId);

    if (currentReaction == emoji) {
      await docRef.update({
        'reactions.$emoji': FieldValue.arrayRemove([currentUid]),
      });
      return '';
    }

    if (currentReaction.isNotEmpty) {
      await docRef.update({
        'reactions.$currentReaction': FieldValue.arrayRemove([currentUid]),
      });
    }
    await docRef.update({
      'reactions.$emoji': FieldValue.arrayUnion([currentUid]),
    });
    return emoji;
  }

  Future<void> setStorySeen(
    String storyId, {
    required String currentUid,
  }) async {
    if (storyId.isEmpty || currentUid.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Viewers')
        .doc(currentUid)
        .set({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

}
