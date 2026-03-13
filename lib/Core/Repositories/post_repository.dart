import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';

import '../../Models/posts_model.dart';
import '../../Models/post_sharers_model.dart';
import '../../Services/post_count_manager.dart';
import '../../Services/post_interaction_service.dart';

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

class PostReshareEntry {
  const PostReshareEntry({
    required this.userId,
    required this.timeStamp,
  });

  final String userId;
  final int timeStamp;
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
            interactionService ?? Get.put(PostInteractionService()),
        _countManager = countManager ?? PostCountManager.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PostInteractionService _interactionService;
  final PostCountManager _countManager;

  static const Duration _interactionTtl = Duration(seconds: 30);
  final Map<String, PostRepositoryState> _states =
      <String, PostRepositoryState>{};
  final Map<String, List<PostSharersModel>> _postSharersMemory =
      <String, List<PostSharersModel>>{};
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  static PostRepository ensure() {
    if (Get.isRegistered<PostRepository>()) {
      return Get.find<PostRepository>();
    }
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
      await _firestore.collection('users').doc(me).update({
        'counterOfPosts': FieldValue.increment(archived ? -1 : 1),
      });
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
        final model = PostsModel.fromMap(data, doc.id);
        result[doc.id] = model;
        final state =
            _states.putIfAbsent(doc.id, () => PostRepositoryState(doc.id));
        state.latestPostData.value = Map<String, dynamic>.from(data);
        _seedCounts(state, model);
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
        .where('timeStamp', isLessThanOrEqualTo: nowMs)
        .orderBy('timeStamp', descending: true)
        .limit(limit);
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
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final cleaned = authorIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <PostsModel>[];

    final futures = cleaned.map((authorId) async {
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
          .where(
              (post) => post.timeStamp >= cutoffMs && post.timeStamp <= nowMs)
          .toList(growable: false);
    });

    final nested = await Future.wait(futures);
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

  Future<List<PostReshareEntry>> fetchAllReshareEntries(
    String postId, {
    int limit = 200,
  }) async {
    if (postId.trim().isEmpty) return const <PostReshareEntry>[];
    final snap = await _firestore
        .collection('Posts')
        .doc(postId.trim())
        .collection('reshares')
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => PostReshareEntry(
              userId: (doc.data()['userID'] ?? doc.id).toString().trim(),
              timeStamp: ((doc.data()['timeStamp'] ?? 0) as num).toInt(),
            ))
        .where((entry) => entry.userId.isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<String, int>> fetchUserResharedPosts(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
    int limit = 200,
  }) async {
    if (uid.trim().isEmpty) return const <String, int>{};
    final entries = await _userSubcollectionRepository.getEntries(
      uid.trim(),
      subcollection: 'reshared_posts',
      orderByField: 'timeStamp',
      descending: true,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
    final map = <String, int>{};
    for (final entry in entries.take(limit)) {
      final data = entry.data;
      final postId = (data['post_docID'] ?? entry.id).toString().trim();
      if (postId.isEmpty) continue;
      final ts = (data['timeStamp'] as num?)?.toInt() ??
          int.tryParse('${data['timeStamp']}') ??
          0;
      map[postId] = ts;
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> fetchCollectionGroupReshares({
    int limit = 500,
  }) async {
    final snap =
        await _firestore.collectionGroup('reshares').limit(limit).get();
    return snap.docs
        .map((doc) {
          final postRef = doc.reference.parent.parent;
          final postId = postRef?.id ?? '';
          final data = doc.data();
          return <String, dynamic>{
            'postID': postId,
            'userID': doc.id,
            'timeStamp': ((data['timeStamp'] ?? 0) as num).toInt(),
            'originalUserID': (data['originalUserID'] ?? '').toString(),
            'originalPostID': (data['originalPostID'] ?? '').toString(),
            'type': 'reshare',
          };
        })
        .where((entry) => (entry['postID'] as String).isNotEmpty)
        .toList(growable: false);
  }

  Future<void> restoreDeletedPostsForUser(String uid) async {
    if (uid.trim().isEmpty) return;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('userID', isEqualTo: uid.trim())
        .where('deletedPost', isEqualTo: true)
        .limit(400);

    while (true) {
      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      final batch = _firestore.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'deletedPost': false,
          'deletedPostTime': 0,
          'updatedDate': now,
        });
        final state =
            _states.putIfAbsent(doc.id, () => PostRepositoryState(doc.id));
        final cached = Map<String, dynamic>.from(
          state.latestPostData.value ?? doc.data(),
        )
          ..['deletedPost'] = false
          ..['deletedPostTime'] = 0
          ..['updatedDate'] = now;
        state.latestPostData.value = cached;
      }
      await batch.commit();

      if (snap.docs.length < 400) break;
      query = _firestore
          .collection('Posts')
          .where('userID', isEqualTo: uid.trim())
          .where('deletedPost', isEqualTo: true)
          .startAfterDocument(snap.docs.last)
          .limit(400);
    }
  }

  Future<void> markAllPostsDeletedForUser(
    String uid, {
    int? nowMs,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;
    final timestamp = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('userID', isEqualTo: normalizedUid)
        .limit(200);

    while (true) {
      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'deletedPost': true,
          'deletedPostTime': timestamp,
          'updatedDate': timestamp,
        });
        final state =
            _states.putIfAbsent(doc.id, () => PostRepositoryState(doc.id));
        final cached = Map<String, dynamic>.from(
          state.latestPostData.value ?? doc.data(),
        )
          ..['isDeleted'] = true
          ..['deletedPost'] = true
          ..['deletedPostTime'] = timestamp
          ..['updatedDate'] = timestamp;
        state.latestPostData.value = cached;
      }
      await batch.commit();

      if (snap.docs.length < 200) break;
      query = _firestore
          .collection('Posts')
          .where('userID', isEqualTo: normalizedUid)
          .startAfterDocument(snap.docs.last)
          .limit(200);
    }
  }

  Future<List<PostSharersModel>> fetchPostSharers(
    String postId, {
    bool preferCache = true,
  }) async {
    if (postId.trim().isEmpty) return const <PostSharersModel>[];
    final normalizedPostId = postId.trim();
    final cached = _postSharersMemory[normalizedPostId];
    if (preferCache && cached != null) {
      return List<PostSharersModel>.from(cached);
    }

    final snapshot = await _firestore
        .collection('Posts')
        .doc(normalizedPostId)
        .collection('postSharers')
        .orderBy('timestamp', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));

    final sharers = snapshot.docs
        .map((doc) => PostSharersModel.fromMap(doc.data()))
        .toList(growable: false);
    _postSharersMemory[normalizedPostId] = List<PostSharersModel>.from(sharers);
    return sharers;
  }

  Future<PostSubcollectionPage> fetchLikeUserIdsPage(
    String postId, {
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    int limit = 20,
  }) async {
    if (postId.trim().isEmpty) {
      return const PostSubcollectionPage(
        userIds: <String>[],
        lastDoc: null,
        hasMore: false,
      );
    }
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .doc(postId.trim())
        .collection('likes')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    final snap = await query.get();
    return PostSubcollectionPage(
      userIds: snap.docs.map((doc) => doc.id).toList(growable: false),
      lastDoc: snap.docs.isEmpty ? lastDoc : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<PostSubcollectionPage> fetchReshareUserIdsPage(
    String postId, {
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    int limit = 20,
  }) async {
    if (postId.trim().isEmpty) {
      return const PostSubcollectionPage(
        userIds: <String>[],
        lastDoc: null,
        hasMore: false,
      );
    }
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .doc(postId.trim())
        .collection('reshares')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    final snap = await query.get();
    return PostSubcollectionPage(
      userIds: snap.docs
          .map((doc) => (doc.data()['userID'] ?? doc.id).toString())
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false),
      lastDoc: snap.docs.isEmpty ? lastDoc : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<PostSubcollectionPage> fetchQuoteUserIdsPage(
    String postId, {
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    int limit = 20,
  }) async {
    if (postId.trim().isEmpty) {
      return const PostSubcollectionPage(
        userIds: <String>[],
        lastDoc: null,
        hasMore: false,
      );
    }

    final collected = <String>[];
    final seen = <String>{};
    var cursor = lastDoc;
    var hasMore = true;

    while (collected.length < limit && hasMore) {
      Query<Map<String, dynamic>> query = _firestore
          .collection('Posts')
          .doc(postId.trim())
          .collection('postSharers')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) {
        hasMore = false;
        break;
      }

      cursor = snap.docs.last;
      if (snap.docs.length < limit) {
        hasMore = false;
      }

      final deferredSharedPostIds = <String>[];
      final deferredUserByPost = <String, String>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final userId = (data['userID'] ?? doc.id).toString().trim();
        if (userId.isEmpty || seen.contains(userId)) continue;

        final isQuoted = data['quotedPost'] == true;
        if (isQuoted) {
          seen.add(userId);
          collected.add(userId);
          if (collected.length >= limit) break;
          continue;
        }

        final sharedPostId = (data['sharedPostID'] ?? '').toString().trim();
        if (sharedPostId.isEmpty) continue;
        deferredSharedPostIds.add(sharedPostId);
        deferredUserByPost[sharedPostId] = userId;
      }

      if (collected.length >= limit || deferredSharedPostIds.isEmpty) {
        continue;
      }

      final sharedPosts = await fetchPostsByIds(
        deferredSharedPostIds,
        preferCache: true,
      );
      for (final entry in deferredUserByPost.entries) {
        final userId = entry.value;
        if (seen.contains(userId)) continue;
        final sharedPost = sharedPosts[entry.key];
        if (sharedPost == null) continue;
        if (sharedPost.quotedPost != true || sharedPost.deletedPost == true) {
          continue;
        }
        seen.add(userId);
        collected.add(userId);
        if (collected.length >= limit) break;
      }
    }

    return PostSubcollectionPage(
      userIds: collected,
      lastDoc: cursor,
      hasMore: hasMore,
    );
  }

  Future<List<String>> fetchDislikeUserIds(String postId) async {
    final normalized = postId.trim();
    if (normalized.isEmpty) return const <String>[];
    final snap = await _firestore
        .collection('Posts')
        .doc(normalized)
        .collection('Begenmemeler')
        .get();
    return snap.docs.map((doc) => doc.id).toList(growable: false);
  }

  Future<bool> ensureViewerSeen(
    String postId,
    String userId,
  ) async {
    final normalizedPostId = postId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedPostId.isEmpty || normalizedUserId.isEmpty) return false;

    final viewersRef = _firestore
        .collection('Posts')
        .doc(normalizedPostId)
        .collection('viewers');
    final existing = await viewersRef
        .where('userID', isEqualTo: normalizedUserId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return false;
    }
    await viewersRef.doc().set({
      'userID': normalizedUserId,
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
    });
    await _countManager.updateStatsCount(normalizedPostId, by: 1);
    return true;
  }

  Future<String?> fetchLegacyResharedPostId(
    String postId,
    String userId,
  ) async {
    final normalizedPostId = postId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedPostId.isEmpty || normalizedUserId.isEmpty) return null;
    final doc = await _firestore
        .collection('Posts')
        .doc(normalizedPostId)
        .collection('YenidenPaylas')
        .doc(normalizedUserId)
        .get();
    if (!doc.exists) return null;
    final resharedPostId = (doc.data()?['yeniPostID'] ?? '').toString().trim();
    return resharedPostId.isEmpty ? null : resharedPostId;
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
