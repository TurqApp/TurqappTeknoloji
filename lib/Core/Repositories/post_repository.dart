import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';

import '../../Models/posts_model.dart';
import '../../Models/post_sharers_model.dart';
import '../../Services/post_count_manager.dart';
import '../../Services/post_interaction_service.dart';

part 'post_repository_sharing_part.dart';

class PostRepositoryState {
  PostRepositoryState(this.postId);

  final String postId;
  final RxBool liked = false.obs;
  final RxBool saved = false.obs;
  final RxBool reshared = false.obs;
  final RxBool reported = false.obs;
  final RxBool commented = false.obs;
  final Rxn<Map<String, dynamic>> latestPostData = Rxn<Map<String, dynamic>>();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? postSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? commentsSub;
  DateTime? interactionFetchedAt;
  bool interactionLoading = false;
  int retainCount = 0;
}

class PostSubcollectionPage {
  const PostSubcollectionPage({
    required this.userIds,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<String> userIds;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class PostSharersPage {
  const PostSharersPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<PostSharersModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class PostReshareEntry {
  const PostReshareEntry({
    required this.userId,
    required this.timeStamp,
    required this.quotedPost,
  });

  final String userId;
  final int timeStamp;
  final bool quotedPost;
}

class PostQueryPage {
  const PostQueryPage({
    required this.items,
    required this.lastDoc,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
}

class UserFeedReference {
  const UserFeedReference({
    required this.postId,
    required this.authorId,
    required this.timeStamp,
    required this.isCelebrity,
    required this.expiresAt,
  });

  final String postId;
  final String authorId;
  final int timeStamp;
  final bool isCelebrity;
  final int expiresAt;
}

class UserFeedReferencePage {
  const UserFeedReferencePage({
    required this.items,
    required this.lastDoc,
  });

  final List<UserFeedReference> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
}

class PostRepository extends GetxService {
  PostRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PostInteractionService? interactionService,
    PostCountManager? countManager,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _interactionService =
            interactionService ?? PostInteractionService.ensure(),
        _countManager = countManager ?? PostCountManager.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PostInteractionService _interactionService;
  final PostCountManager _countManager;
  final TypesensePostService _typesensePostService =
      TypesensePostService.instance;

  static const Duration _interactionTtl = Duration(seconds: 30);
  static const Duration _stuckUploadingRepairAge = Duration(seconds: 10);
  static final Set<String> _uploadRepairInFlight = <String>{};
  final Map<String, PostRepositoryState> _states =
      <String, PostRepositoryState>{};
  final Map<String, List<PostSharersModel>> _postSharersMemory =
      <String, List<PostSharersModel>>{};
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  static PostRepository? maybeFind() {
    final isRegistered = Get.isRegistered<PostRepository>();
    if (!isRegistered) return null;
    return Get.find<PostRepository>();
  }

  static PostRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PostRepository(), permanent: true);
  }

  PostRepositoryState attachPost(
    PostsModel model, {
    bool loadInteraction = true,
    bool loadCommentMembership = true,
  }) {
    final state = _states.putIfAbsent(
        model.docID, () => PostRepositoryState(model.docID));
    state.retainCount++;
    _seedCounts(state, model);
    _startPostStream(state);
    if (loadInteraction) {
      unawaited(_ensureInteraction(state));
    }
    if (loadCommentMembership) {
      _startCommentsMembershipStream(state);
    }
    return state;
  }

  void releasePost(String postId) {
    final state = _states[postId];
    if (state == null) return;
    state.retainCount--;
    if (state.retainCount > 0) return;
    state.postSub?.cancel();
    state.postSub = null;
    state.commentsSub?.cancel();
    state.commentsSub = null;
  }

  Future<bool> toggleLike(PostsModel model) async {
    final state = attachPost(model);
    final wasLiked = state.liked.value;
    final target = !wasLiked;
    state.liked.value = target;
    _applyCountDelta(
      postId: model.docID,
      from: wasLiked,
      to: target,
      countRx: _countManager.getLikeCount(model.docID),
      readStat: () => model.stats.likeCount,
      writeStat: (value) => model.stats.likeCount = value,
    );

    try {
      final actual = await _interactionService.toggleLike(model.docID);
      if (actual != target) {
        state.liked.value = actual;
        _applyCountDelta(
          postId: model.docID,
          from: target,
          to: actual,
          countRx: _countManager.getLikeCount(model.docID),
          readStat: () => model.stats.likeCount,
          writeStat: (value) => model.stats.likeCount = value,
        );
      }
      return actual;
    } catch (_) {
      state.liked.value = wasLiked;
      _applyCountDelta(
        postId: model.docID,
        from: target,
        to: wasLiked,
        countRx: _countManager.getLikeCount(model.docID),
        readStat: () => model.stats.likeCount,
        writeStat: (value) => model.stats.likeCount = value,
      );
      rethrow;
    }
  }

  Future<bool> toggleSave(PostsModel model) async {
    final state = attachPost(model);
    final wasSaved = state.saved.value;
    final target = !wasSaved;
    state.saved.value = target;
    _applyCountDelta(
      postId: model.docID,
      from: wasSaved,
      to: target,
      countRx: _countManager.getSavedCount(model.docID),
      readStat: () => model.stats.savedCount,
      writeStat: (value) => model.stats.savedCount = value,
    );

    try {
      final actual = await _interactionService.toggleSave(model.docID);
      if (actual != target) {
        state.saved.value = actual;
        _applyCountDelta(
          postId: model.docID,
          from: target,
          to: actual,
          countRx: _countManager.getSavedCount(model.docID),
          readStat: () => model.stats.savedCount,
          writeStat: (value) => model.stats.savedCount = value,
        );
      }
      return actual;
    } catch (_) {
      state.saved.value = wasSaved;
      _applyCountDelta(
        postId: model.docID,
        from: target,
        to: wasSaved,
        countRx: _countManager.getSavedCount(model.docID),
        readStat: () => model.stats.savedCount,
        writeStat: (value) => model.stats.savedCount = value,
      );
      rethrow;
    }
  }

  Future<bool> toggleReshare(PostsModel model) async {
    final state = attachPost(model);
    final wasReshared = state.reshared.value;
    final target = !wasReshared;
    state.reshared.value = target;
    _applyCountDelta(
      postId: model.docID,
      from: wasReshared,
      to: target,
      countRx: _countManager.getRetryCount(model.docID),
      readStat: () => model.stats.retryCount,
      writeStat: (value) => model.stats.retryCount = value,
    );

    try {
      final actual = await _interactionService.toggleReshare(model.docID);
      if (actual != target) {
        state.reshared.value = actual;
        _applyCountDelta(
          postId: model.docID,
          from: target,
          to: actual,
          countRx: _countManager.getRetryCount(model.docID),
          readStat: () => model.stats.retryCount,
          writeStat: (value) => model.stats.retryCount = value,
        );
      }
      return actual;
    } catch (_) {
      state.reshared.value = wasReshared;
      _applyCountDelta(
        postId: model.docID,
        from: target,
        to: wasReshared,
        countRx: _countManager.getRetryCount(model.docID),
        readStat: () => model.stats.retryCount,
        writeStat: (value) => model.stats.retryCount = value,
      );
      rethrow;
    }
  }

  Future<void> refreshInteraction(String postId) async {
    final state = _states[postId];
    if (state == null) return;
    state.interactionFetchedAt = null;
    await _ensureInteraction(state, forceRefresh: true);
  }

  Future<void> setArchived(
    PostsModel model,
    bool archived,
  ) async {
    await _firestore.collection('Posts').doc(model.docID).update({
      'arsiv': archived,
    });

    final me = _auth.currentUser?.uid;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isVisible = (model.timeStamp <= nowMs) && !model.flood;
    if (me != null && model.userID == me && isVisible) {
      await UserRepository.ensure().updateUserFields(
        me,
        {
          'counterOfPosts': FieldValue.increment(archived ? -1 : 1),
        },
        mergeIntoCache: false,
      );
    }

    final state = _states[model.docID];
    final latest = state?.latestPostData.value;
    if (latest != null) {
      state!.latestPostData.value = {
        ...latest,
        'arsiv': archived,
      };
    }
  }

  Future<Map<String, PostsModel>> fetchPostsByIds(
    List<String> postIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final cleaned = postIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <String, PostsModel>{};

    final result = <String, PostsModel>{};
    final missing = <String>[];

    for (final id in cleaned) {
      final state = _states[id];
      final cached = preferCache ? state?.latestPostData.value : null;
      if (cached != null) {
        result[id] = PostsModel.fromMap(cached, id);
      } else {
        missing.add(id);
      }
    }

    for (int i = 0; i < missing.length; i += 10) {
      final chunk = missing.sublist(
        i,
        i + 10 > missing.length ? missing.length : i + 10,
      );
      final query = _firestore
          .collection('Posts')
          .where(FieldPath.documentId, whereIn: chunk);
      final snap = await _getQueryWithSource(
        query,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      for (final doc in snap.docs) {
        final data = doc.data();
        final model = _normalizeLikelyCompletedOwnPost(
          PostsModel.fromMap(data, doc.id),
        );
        result[doc.id] = model;
        final state =
            _states.putIfAbsent(doc.id, () => PostRepositoryState(doc.id));
        state.latestPostData.value = model.toMap();
        _seedCounts(state, model);
      }
    }

    return result;
  }

  Future<Map<String, PostsModel>> fetchPostCardsByIds(
    List<String> postIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final cleaned = postIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <String, PostsModel>{};

    final result = <String, PostsModel>{};
    final missing = <String>[];

    for (final id in cleaned) {
      final state = _states[id];
      final cached = preferCache ? state?.latestPostData.value : null;
      if (cached != null) {
        result[id] = _normalizeLikelyCompletedOwnPost(
          PostsModel.fromMap(cached, id),
        );
      } else {
        missing.add(id);
      }
    }

    if (missing.isEmpty || cacheOnly) {
      return result;
    }

    Map<String, Map<String, dynamic>> typesenseDocs =
        <String, Map<String, dynamic>>{};
    try {
      typesenseDocs = await _typesensePostService.getPostCardsByIds(missing);
    } catch (_) {
      typesenseDocs = const <String, Map<String, dynamic>>{};
    }
    final fallbackIds = <String>[];

    for (final id in missing) {
      final doc = typesenseDocs[id];
      if (doc == null) {
        fallbackIds.add(id);
        continue;
      }

      final raw = _typesenseDocToPostMap(doc, id);
      final model = _normalizeLikelyCompletedOwnPost(
        PostsModel.fromMap(raw, id),
      );
      result[id] = model;
      final state = _states.putIfAbsent(id, () => PostRepositoryState(id));
      state.latestPostData.value = model.toMap();
      _countManager.initializeCounts(
        model.docID,
        likeCount: model.stats.likeCount.toInt(),
        commentCount: model.stats.commentCount.toInt(),
        savedCount: model.stats.savedCount.toInt(),
        retryCount: model.stats.retryCount.toInt(),
        statsCount: model.stats.statsCount.toInt(),
      );
    }

    if (fallbackIds.isNotEmpty) {
      final firestoreModels = await fetchPostsByIds(
        fallbackIds,
        preferCache: preferCache,
        cacheOnly: false,
      );
      for (final entry in firestoreModels.entries) {
        if (_isRenderableCard(entry.value)) {
          result[entry.key] = entry.value;
        }
      }
    }

    return result;
  }

  Future<PostQueryPage> fetchAgendaWindowPage({
    required int cutoffMs,
    required int nowMs,
    required int limit,
    DocumentSnapshot? startAfter,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
        .orderBy('timeStamp', descending: true)
        .limit(limit * 3);
    if (startAfter != null) {
      query = query.startAfterDocument(
        startAfter as DocumentSnapshot<Map<String, dynamic>>,
      );
    }
    final snap = await _getQueryWithSource(
      query,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final items = snap.docs
        .map((doc) => PostsModel.fromMap(doc.data(), doc.id))
        .where((post) => !post.shouldHideWhileUploading)
        .where((post) => _isRenderableCard(post))
        .take(limit)
        .toList(growable: false);
    return PostQueryPage(
      items: items,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<UserFeedReferencePage> fetchUserFeedReferences({
    required String uid,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return const UserFeedReferencePage(
          items: <UserFeedReference>[], lastDoc: null);
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('userFeeds')
        .doc(normalizedUid)
        .collection('items')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await _getQueryWithSource(
      query,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final items = snap.docs
        .map((doc) {
          final data = doc.data();
          return UserFeedReference(
            postId: (data['postId'] ?? doc.id).toString().trim(),
            authorId: (data['authorId'] ?? '').toString().trim(),
            timeStamp: (data['timeStamp'] as num?)?.toInt() ?? 0,
            isCelebrity: data['isCelebrity'] == true,
            expiresAt: (data['expiresAt'] as num?)?.toInt() ?? 0,
          );
        })
        .where((item) => item.postId.isNotEmpty)
        .toList(growable: false);

    if (kDebugMode) {
      debugPrint(
        '[FeedRefs] uid=$normalizedUid count=${items.length} '
        'startAfter=${startAfter?.id ?? ''} '
        'sample=${items.take(5).map((item) => item.postId).join(',')}',
      );
    }

    return UserFeedReferencePage(
      items: items,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<List<String>> fetchCelebrityAuthorIds(
    List<String> authorIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final cleaned = authorIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <String>[];

    final celebIds = <String>{};
    for (int i = 0; i < cleaned.length; i += 10) {
      final chunk = cleaned.sublist(
        i,
        i + 10 > cleaned.length ? cleaned.length : i + 10,
      );
      final snap = await _getQueryWithSource(
        _firestore
            .collection('celebAccounts')
            .where(FieldPath.documentId, whereIn: chunk),
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      celebIds.addAll(snap.docs.map((doc) => doc.id));
    }
    return celebIds.toList(growable: false);
  }

  Future<List<PostsModel>> fetchRecentPostsForAuthors(
    List<String> authorIds, {
    required int nowMs,
    required int cutoffMs,
    int perAuthorLimit = 3,
    int maxConcurrent = 12,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final cleaned = authorIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <PostsModel>[];

    final nested = <List<PostsModel>>[];
    final concurrency = maxConcurrent < 1 ? 1 : maxConcurrent;
    for (int i = 0; i < cleaned.length; i += concurrency) {
      final chunk = cleaned.sublist(
        i,
        i + concurrency > cleaned.length ? cleaned.length : i + concurrency,
      );
      final futures = chunk.map((authorId) async {
        final snap = await _getQueryWithSource(
          _firestore
              .collection('Posts')
              .where('userID', isEqualTo: authorId)
              .where('arsiv', isEqualTo: false)
              .where('deletedPost', isEqualTo: false)
              .orderBy('timeStamp', descending: true)
              .limit(perAuthorLimit),
          preferCache: preferCache,
          cacheOnly: cacheOnly,
        );
        return snap.docs
            .map((doc) => PostsModel.fromMap(doc.data(), doc.id))
            .where((post) =>
                !post.shouldHideWhileUploading &&
                post.timeStamp >= cutoffMs &&
                (post.timeStamp <= nowMs || post.scheduledAt.toInt() > 0))
            .toList(growable: false);
      });
      nested.addAll(await Future.wait(futures));
    }

    final merged = <String, PostsModel>{};
    for (final posts in nested) {
      for (final post in posts) {
        merged.putIfAbsent(post.docID, () => post);
      }
    }
    final sorted = merged.values.toList()
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return sorted;
  }

  Future<List<PostsModel>> fetchPublicScheduledIzBirakPosts({
    required int nowMs,
    required int cutoffMs,
    int limit = 40,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final snap = await _getQueryWithSource(
      _firestore
          .collection('Posts')
          .where('arsiv', isEqualTo: false)
          .where('deletedPost', isEqualTo: false)
          .where('flood', isEqualTo: false)
          .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
          .orderBy('timeStamp', descending: true)
          .limit(limit * 3),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );

    final merged = <String, PostsModel>{};
    for (final doc in snap.docs) {
      final model = PostsModel.fromMap(doc.data(), doc.id);
      if (model.shouldHideWhileUploading) continue;
      final ts = model.timeStamp.toInt();
      final publishAt = model.izBirakYayinTarihi.toInt();
      final scheduledAt = model.scheduledAt.toInt();
      final effectivePublishAt = publishAt > 0 ? publishAt : scheduledAt;
      if (ts < cutoffMs) continue;
      if (effectivePublishAt <= 0) continue;
      if (effectivePublishAt <= nowMs) continue;
      merged[model.docID] = model;
      if (merged.length >= limit) break;
    }

    final sorted = merged.values.toList()
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return sorted;
  }

  Future<PostsModel?> fetchPostById(
    String postId, {
    bool preferCache = true,
  }) async {
    final normalized = postId.trim();
    if (normalized.isEmpty) return null;
    final items = await fetchPostsByIds(
      <String>[normalized],
      preferCache: preferCache,
    );
    return items[normalized];
  }

  void mergeCachedPostData(String postId, Map<String, dynamic> patch) {
    final normalized = postId.trim();
    if (normalized.isEmpty || patch.isEmpty) return;
    final state =
        _states.putIfAbsent(normalized, () => PostRepositoryState(normalized));
    final current = Map<String, dynamic>.from(state.latestPostData.value ?? {});
    current.addAll(patch);
    state.latestPostData.value = current;
  }

  Future<Map<String, dynamic>?> fetchPostRawById(
    String postId, {
    bool preferCache = true,
  }) async {
    final normalized = postId.trim();
    if (normalized.isEmpty) return null;
    final state = _states[normalized];
    final cached = preferCache ? state?.latestPostData.value : null;
    if (cached != null) {
      return Map<String, dynamic>.from(cached);
    }

    final doc = await _firestore.collection('Posts').doc(normalized).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final nextState =
        _states.putIfAbsent(normalized, () => PostRepositoryState(normalized));
    nextState.latestPostData.value = Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(data);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getQueryWithSource(
    Query<Map<String, dynamic>> query, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    if (preferCache) {
      try {
        return await query.get(const GetOptions(source: Source.cache));
      } catch (_) {
        if (cacheOnly) rethrow;
        return query.get(const GetOptions(source: Source.server));
      }
    }
    if (cacheOnly) {
      return query.get(const GetOptions(source: Source.cache));
    }
    return query.get(const GetOptions(source: Source.server));
  }

  Future<String?> resolveDocumentIdByLegacyId(
    String legacyId, {
    bool preferCache = true,
  }) async {
    final normalized = legacyId.trim();
    if (normalized.isEmpty) return null;
    if (_states.containsKey(normalized)) {
      return normalized;
    }
    final byDocId = await fetchPostRawById(
      normalized,
      preferCache: preferCache,
    );
    if (byDocId != null) {
      return normalized;
    }
    final snap = await _firestore
        .collection('Posts')
        .where('id', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final state =
        _states.putIfAbsent(doc.id, () => PostRepositoryState(doc.id));
    state.latestPostData.value = Map<String, dynamic>.from(doc.data());
    return doc.id;
  }

  void _seedCounts(PostRepositoryState state, PostsModel model) {
    if (state.latestPostData.value != null) return;
    _countManager.initializeCounts(
      model.docID,
      likeCount: model.stats.likeCount.toInt(),
      commentCount: model.stats.commentCount.toInt(),
      savedCount: model.stats.savedCount.toInt(),
      retryCount: model.stats.retryCount.toInt(),
      statsCount: model.stats.statsCount.toInt(),
    );
  }

  bool _isRenderableCard(PostsModel model) {
    if (model.deletedPost || model.gizlendi || model.isUploading) {
      return false;
    }
    final hasVisual = model.thumbnail.trim().isNotEmpty || model.img.isNotEmpty;
    if (model.hasVideoSignal) {
      return model.hasRenderableVideoCard && hasVisual;
    }
    return model.metin.trim().isNotEmpty || hasVisual || model.floodCount > 1;
  }

  PostsModel _normalizeLikelyCompletedOwnPost(PostsModel model) {
    if (!_shouldRepairStuckUploading(model)) {
      return model;
    }
    model.isUploading = false;
    unawaited(_repairStuckUploadingPost(model));
    return model;
  }

  bool _shouldRepairStuckUploading(PostsModel model) {
    if (!model.isUploading) return false;
    final currentUser = _auth.currentUser;
    final currentUid = currentUser == null ? '' : currentUser.uid.trim();
    if (currentUid.isEmpty || model.userID.trim() != currentUid) return false;
    if (model.deletedPost || model.arsiv || model.gizlendi) return false;
    final ageMs =
        DateTime.now().millisecondsSinceEpoch - model.timeStamp.toInt();
    if (ageMs < _stuckUploadingRepairAge.inMilliseconds) return false;
    final hasCompletedMedia = model.img.isNotEmpty ||
        model.thumbnail.trim().isNotEmpty ||
        model.hasHls ||
        model.video.trim().isNotEmpty;
    return hasCompletedMedia || model.metin.trim().isNotEmpty;
  }

  Future<void> _repairStuckUploadingPost(PostsModel model) async {
    final docId = model.docID.trim();
    if (docId.isEmpty) return;
    if (_uploadRepairInFlight.contains(docId)) return;
    _uploadRepairInFlight.add(docId);
    try {
      await _firestore.collection('Posts').doc(docId).set(<String, dynamic>{
        'isUploading': false,
      }, SetOptions(merge: true));
      final state =
          _states.putIfAbsent(docId, () => PostRepositoryState(docId));
      state.latestPostData.value = model.toMap()..['isUploading'] = false;
      if (kDebugMode) {
        debugPrint('[PostRepository] repairedStuckUploading postId=$docId');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[PostRepository] repairStuckUploadingFailed postId=$docId error=$error',
        );
      }
    } finally {
      _uploadRepairInFlight.remove(docId);
    }
  }

  Map<String, dynamic> _typesenseDocToPostMap(
    Map<String, dynamic> doc,
    String docId,
  ) {
    List<String> asStringList(dynamic value) {
      if (value is! List) return const <String>[];
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    num asNum(dynamic value, [num fallback = 0]) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? fallback;
      return fallback;
    }

    bool asBool(dynamic value) => value == true;

    final imageUrls = asStringList(doc['img']);
    final thumbnail = (doc['thumbnail'] ?? '').toString();
    final video = (doc['video'] ?? '').toString();
    final hlsMasterUrl = (doc['hlsMasterUrl'] ?? '').toString();

    return <String, dynamic>{
      'metin': (doc['metin'] ?? '').toString(),
      'img': imageUrls,
      'thumbnail': thumbnail,
      'video': video,
      'hlsMasterUrl': hlsMasterUrl,
      'hlsStatus': (doc['hlsStatus'] ?? 'none').toString(),
      'hlsUpdatedAt': 0,
      'timeStamp': asNum(doc['timeStamp']),
      'editTime': asNum(doc['editTime']),
      'authorNickname': (doc['authorNickname'] ?? '').toString(),
      'authorDisplayName': (doc['authorDisplayName'] ?? '').toString(),
      'authorAvatarUrl': (doc['authorAvatarUrl'] ?? '').toString(),
      'rozet': (doc['rozet'] ?? '').toString(),
      'userID': (doc['userID'] ?? '').toString(),
      'paylasGizliligi': asNum(doc['paylasGizliligi'], 0),
      'arsiv': asBool(doc['arsiv']),
      'deletedPost': asBool(doc['deletedPost']),
      'gizlendi': asBool(doc['gizlendi']),
      'isUploading': asBool(doc['isUploading']),
      'aspectRatio': asNum(doc['aspectRatio'], 1.77),
      'flood': asBool(doc['flood']),
      'floodCount': asNum(doc['floodCount'], 1),
      'mainFlood': (doc['mainFlood'] ?? '').toString(),
      'locationCity': (doc['locationCity'] ?? '').toString(),
      'originalPostID': (doc['originalPostID'] ?? '').toString(),
      'originalUserID': (doc['originalUserID'] ?? '').toString(),
      'quotedPost': asBool(doc['quotedPost']),
      'tags': asStringList(doc['hashtags']),
      'yorum': true,
      'yorumMap': const <String, dynamic>{},
      'reshareMap': const <String, dynamic>{},
      'poll': const <String, dynamic>{},
      'ad': false,
      'isAd': false,
      'debugMode': false,
      'deletedPostTime': 0,
      'izBirakYayinTarihi': 0,
      'konum': (doc['locationCity'] ?? '').toString(),
      'scheduledAt': 0,
      'sikayetEdildi': false,
      'stabilized': true,
      'videoLook': const <String, dynamic>{
        'preset': 'original',
        'version': 1,
        'intensity': 1.0,
      },
      'stats': <String, dynamic>{
        'likeCount': asNum(doc['likeCount']),
        'commentCount': asNum(doc['commentCount']),
        'savedCount': asNum(doc['savedCount']),
        'retryCount': asNum(doc['retryCount']),
        'statsCount': asNum(doc['statsCount']),
        'reportedCount': 0,
      },
      'docID': docId,
    };
  }

  void _startPostStream(PostRepositoryState state) {
    if (state.postSub != null) return;
    state.postSub = _firestore
        .collection('Posts')
        .doc(state.postId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return;
      final stats =
          data['stats'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      _countManager.getLikeCount(state.postId).value =
          ((stats['likeCount'] ?? data['likeCount'] ?? 0) as num).toInt();
      _countManager.getCommentCount(state.postId).value =
          ((stats['commentCount'] ?? data['commentCount'] ?? 0) as num).toInt();
      _countManager.getSavedCount(state.postId).value =
          ((stats['savedCount'] ?? data['savedCount'] ?? 0) as num).toInt();
      _countManager.getRetryCount(state.postId).value =
          ((stats['retryCount'] ?? data['retryCount'] ?? 0) as num).toInt();
      _countManager.getStatsCount(state.postId).value =
          ((stats['statsCount'] ?? data['statsCount'] ?? 0) as num).toInt();
      state.latestPostData.value = Map<String, dynamic>.from(data);
    });
  }

  void _startCommentsMembershipStream(PostRepositoryState state) {
    if (state.commentsSub != null) return;
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.trim().isEmpty) {
      state.commented.value = false;
      return;
    }
    state.commentsSub = _firestore
        .collection('Posts')
        .doc(state.postId)
        .collection('comments')
        .where('deleted', isEqualTo: false)
        .where('userID', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .listen((snap) {
      state.commented.value = snap.docs.isNotEmpty;
    });
  }

  Future<void> _ensureInteraction(
    PostRepositoryState state, {
    bool forceRefresh = false,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      state.liked.value = false;
      state.saved.value = false;
      state.reshared.value = false;
      state.reported.value = false;
      return;
    }
    if (state.interactionLoading) return;
    if (!forceRefresh &&
        state.interactionFetchedAt != null &&
        DateTime.now().difference(state.interactionFetchedAt!) <
            _interactionTtl) {
      return;
    }
    state.interactionLoading = true;
    try {
      final status =
          await _interactionService.getUserInteractionStatus(state.postId);
      state.liked.value = status['liked'] ?? false;
      state.saved.value = status['saved'] ?? false;
      state.reshared.value = status['reshared'] ?? false;
      state.reported.value = status['reported'] ?? false;
      state.interactionFetchedAt = DateTime.now();
    } finally {
      state.interactionLoading = false;
    }
  }

  void _applyCountDelta({
    required String postId,
    required bool from,
    required bool to,
    required RxInt countRx,
    required num Function() readStat,
    required void Function(num value) writeStat,
  }) {
    final delta = (to ? 1 : 0) - (from ? 1 : 0);
    if (delta == 0) return;
    final nextCount = countRx.value + delta;
    countRx.value = nextCount < 0 ? 0 : nextCount;
    final statNext = readStat() + delta;
    writeStat(statNext < 0 ? 0 : statNext);
  }
}
