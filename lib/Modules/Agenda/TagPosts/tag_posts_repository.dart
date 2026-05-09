import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/app_cloud_functions.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class TagPostsRepository {
  static const int _defaultTagResultLimit = 50;

  final FirebaseFirestore _db;
  final PostRepository _postRepository;
  final VisibilityPolicyService _visibilityPolicy;
  final UserRepository _userRepository;
  final List<FirebaseFunctions> _functionsTargets = <FirebaseFunctions>[
    AppCloudFunctions.instance,
    AppCloudFunctions.instanceFor(region: 'us-central1'),
    AppCloudFunctions.instanceFor(region: 'europe-west1'),
  ];

  TagPostsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? AppFirestore.instance,
        _postRepository = PostRepository.ensure(),
        _visibilityPolicy = VisibilityPolicyService.ensure(),
        _userRepository = UserRepository.ensure();

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  Future<List<PostsModel>> fetchByTag(
    String tag, {
    int limit = _defaultTagResultLimit,
    bool fastFirstPaint = false,
  }) async {
    final startedAt = DateTime.now();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final normalizedTag = _normalizeTag(tag);
    final safeLimit = limit.clamp(1, _defaultTagResultLimit);
    final queries = _buildQueries(tag);
    final Future<List<PostsModel>>? firstPaintPostsArrayFuture = fastFirstPaint
        ? _queryPostsByTag(queries, nowMs, limit: safeLimit)
        : null;

    var posts = await _queryFromTagIndex(tag, nowMs, limit: safeLimit);
    posts = await _filterByPrivacy(posts);
    posts = _sortAndLimit(posts, safeLimit);
    if (posts.isNotEmpty && (fastFirstPaint || posts.length >= safeLimit)) {
      _logFetchResult(
        tag: tag,
        source: 'tags_index',
        limit: safeLimit,
        count: posts.length,
        startedAt: startedAt,
      );
      return posts;
    }

    final merged = <String, PostsModel>{
      for (final post in posts)
        if (post.docID.trim().isNotEmpty) post.docID: post,
    };

    var fallbackPosts = firstPaintPostsArrayFuture != null
        ? await firstPaintPostsArrayFuture
        : await _queryPostsByTag(queries, nowMs, limit: safeLimit);
    fallbackPosts = await _filterByPrivacy(fallbackPosts);
    for (final post in fallbackPosts) {
      if (post.docID.trim().isNotEmpty) merged[post.docID] = post;
    }
    posts = _sortAndLimit(merged.values, safeLimit);
    if (posts.isNotEmpty && (fastFirstPaint || posts.length >= safeLimit)) {
      _logFetchResult(
        tag: tag,
        source: 'posts_array',
        limit: safeLimit,
        count: posts.length,
        startedAt: startedAt,
      );
      return posts;
    }
    if (fastFirstPaint) {
      _logFetchResult(
        tag: tag,
        source: 'firestore_first_empty',
        limit: safeLimit,
        count: posts.length,
        startedAt: startedAt,
      );
      return posts;
    }

    final capitalizedQueries = _buildQueries(_capitalizeAfterHash(tag));
    fallbackPosts = await _queryPostsByTag(
      capitalizedQueries,
      nowMs,
      limit: safeLimit,
    );
    fallbackPosts = await _filterByPrivacy(fallbackPosts);
    for (final post in fallbackPosts) {
      if (post.docID.trim().isNotEmpty) merged[post.docID] = post;
    }
    posts = _sortAndLimit(merged.values, safeLimit);
    if (posts.isNotEmpty && (fastFirstPaint || posts.length >= safeLimit)) {
      _logFetchResult(
        tag: tag,
        source: 'posts_array_capitalized',
        limit: safeLimit,
        count: posts.length,
        startedAt: startedAt,
      );
      return posts;
    }

    fallbackPosts = await _queryPostsByTagTypesense(
      normalizedTag,
      limit: safeLimit,
    );
    fallbackPosts = await _filterByPrivacy(fallbackPosts);
    fallbackPosts = _filterByTimestamp(fallbackPosts, nowMs);
    for (final post in fallbackPosts) {
      if (post.docID.trim().isNotEmpty) merged[post.docID] = post;
    }
    posts = _sortAndLimit(merged.values, safeLimit);
    _logFetchResult(
      tag: tag,
      source: 'typesense',
      limit: safeLimit,
      count: posts.length,
      startedAt: startedAt,
    );
    return posts;
  }

  void _logFetchResult({
    required String tag,
    required String source,
    required int limit,
    required int count,
    required DateTime startedAt,
  }) {
    debugPrint(
      '[TagPostsFetchSource] tag=$tag source=$source '
      'limit=$limit count=$count '
      'elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds}',
    );
  }

  String _normalizeTag(String tag) {
    final trimmed = _lowerTag(tag.trim());
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
  }

  String _lowerTag(String value) {
    return value.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase().trim();
  }

  List<String> _buildQueries(String tag) {
    final t = tag.trim();
    if (t.isEmpty) return const [];
    final set = <String>{t};
    final withoutHash = t.startsWith('#') ? t.substring(1) : t;
    final normalized = _lowerTag(withoutHash);
    final capitalized = _capitalizeAfterHash(withoutHash);
    set.add(withoutHash);
    set.add(normalized);
    set.add(capitalized);
    set.add('#$withoutHash');
    set.add('#$normalized');
    set.add('#$capitalized');
    return set.toList();
  }

  List<PostsModel> _sortAndLimit(Iterable<PostsModel> items, int limit) {
    final sorted = items.toList(growable: false)
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    if (sorted.length <= limit) return sorted;
    return sorted.sublist(0, limit);
  }

  Future<List<PostsModel>> _queryPostsByTag(
    List<String> queries,
    int nowMs, {
    required int limit,
  }) async {
    if (queries.isEmpty) return const [];
    final startedAt = DateTime.now();
    final safeLimit = limit.clamp(1, 300);
    final snap = await _db
        .collection("Posts")
        .where("tags", arrayContainsAny: queries)
        .limit(safeLimit)
        .get();

    final results = snap.docs
        .map((doc) => PostsModel.fromMap(doc.data(), doc.id))
        .where((p) => p.deletedPost != true)
        .where((p) => p.arsiv != true)
        .where((p) => p.timeStamp <= nowMs)
        .toList();
    debugPrint(
      '[TagPostsSource] source=posts_array raw=${snap.docs.length} '
      'visible=${results.length} limit=$safeLimit queries=${queries.join("|")} '
      'elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds}',
    );
    return results;
  }

  Future<List<PostsModel>> _queryPostsByTagTypesense(
    String tag, {
    required int limit,
  }) async {
    final normalized = _normalizeTag(tag);
    final currentUid = _currentUid.trim();
    if (normalized.isEmpty || currentUid.isEmpty) return const [];
    final safeLimit = limit.clamp(1, _defaultTagResultLimit);

    Object? lastError;
    for (final fn in _functionsTargets) {
      try {
        final response = await fn.httpsCallable('f14_searchPostsCallable').call(
          <String, dynamic>{
            'q': '',
            'tag': normalized,
            'limit': safeLimit,
            'page': 1,
            'includeNonPublic': true,
          },
        );
        final data = Map<String, dynamic>.from(response.data as Map? ?? {});
        final hits = (data['hits'] as List<dynamic>?) ?? const <dynamic>[];
        final orderedIds = <String>[];
        for (final raw in hits) {
          final map = raw is Map ? Map<String, dynamic>.from(raw) : null;
          final id = (map?['id'] ?? map?['docID'] ?? '').toString().trim();
          if (id.isEmpty || orderedIds.contains(id)) continue;
          orderedIds.add(id);
        }
        if (orderedIds.isEmpty) return const [];

        final byId = await _postRepository.fetchPostCardsByIds(
          orderedIds,
          preferCache: true,
          cacheOnly: false,
        );
        return orderedIds
            .map((id) => byId[id])
            .whereType<PostsModel>()
            .toList(growable: false);
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      return const [];
    }
    return const [];
  }

  List<PostsModel> _filterByTimestamp(List<PostsModel> items, int nowMs) {
    return items
        .where((p) => p.deletedPost != true)
        .where((p) => p.arsiv != true)
        .where((p) => p.timeStamp <= nowMs)
        .toList(growable: false);
  }

  Future<List<PostsModel>> _queryFromTagIndex(
    String tag,
    int nowMs, {
    required int limit,
  }) async {
    final tagKeys = _buildTagIndexKeys(tag);
    if (tagKeys.isEmpty) return const [];
    final safeLimit = limit.clamp(1, 300);

    try {
      final ids = <String>[];
      final createdAtById = <String, int>{};

      for (final tagKey in tagKeys) {
        final tagStartedAt = DateTime.now();
        final indexSnap = await _readTagIndexPosts(tagKey, safeLimit);
        debugPrint(
          '[TagPostsSource] source=tags_index tagKey=$tagKey '
          'raw=${indexSnap.docs.length} limit=$safeLimit '
          'elapsedMs=${DateTime.now().difference(tagStartedAt).inMilliseconds}',
        );
        if (indexSnap.docs.isEmpty) continue;

        for (final d in indexSnap.docs) {
          final data = d.data();
          final candidateIds = <String>{
            d.id,
            (data['postId'] ?? '').toString(),
            (data['id'] ?? '').toString(),
          };
          for (final rawPostId in candidateIds) {
            final postId = rawPostId.trim();
            if (postId.isEmpty || ids.contains(postId)) continue;
            ids.add(postId);
            createdAtById[postId] = _timestampMs(data['createdAt']);
            if (ids.length >= safeLimit) break;
          }
          if (ids.length >= safeLimit) break;
        }
        if (ids.length >= safeLimit) break;
      }
      if (ids.isEmpty) return const [];

      final results = <PostsModel>[];
      for (var i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        final postsSnap = await _db
            .collection('Posts')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in postsSnap.docs) {
          final p = PostsModel.fromMap(doc.data(), doc.id);
          if (p.deletedPost == true) continue;
          if (p.arsiv == true) continue;
          if (p.timeStamp > nowMs) continue;
          results.add(p);
        }
      }
      debugPrint(
        '[TagPostsSource] source=tags_index_hydrate '
        'candidateIds=${ids.length} hydrated=${results.length} '
        'limit=$safeLimit',
      );
      results.sort((a, b) {
        final bStamp = createdAtById[b.docID] ?? b.timeStamp;
        final aStamp = createdAtById[a.docID] ?? a.timeStamp;
        return bStamp.compareTo(aStamp);
      });
      return results;
    } catch (_) {
      return const [];
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _readTagIndexPosts(
    String tagKey,
    int limit,
  ) async {
    final ref = _db.collection('tags').doc(tagKey).collection('posts');
    try {
      return await ref
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
    } catch (_) {
      return ref.limit(limit).get();
    }
  }

  List<String> _buildTagIndexKeys(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return const [];
    final withoutHash =
        trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
    final normalized = _lowerTag(withoutHash);
    final capitalized = _capitalizeAfterHash('#$normalized');
    return <String>{
      trimmed,
      withoutHash,
      normalized,
      '#$withoutHash',
      '#$normalized',
      capitalized,
    }.where((value) => value.trim().isNotEmpty).toList(growable: false);
  }

  int _timestampMs(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  String _capitalizeAfterHash(String tag) {
    if (tag.startsWith('#') && tag.length > 1) {
      return '#${tag[1].toUpperCase()}${tag.substring(2)}';
    } else if (tag.isNotEmpty) {
      return tag[0].toUpperCase() + tag.substring(1);
    }
    return tag;
  }

  Future<List<PostsModel>> _filterByPrivacy(List<PostsModel> items) async {
    if (items.isEmpty) return items;
    final uid = _currentUid;
    if (uid.isEmpty) return items;

    final followingIDs = (await _visibilityPolicy.loadViewerFollowingIds(
      viewerUserId: uid,
    ))
        .toSet();
    final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();

    final Map<String, bool> userPrivacy = {};
    final users = await _userRepository.getUsers(uniqueUserIDs);
    for (final entry in users.entries) {
      userPrivacy[entry.key] = entry.value.isPrivate;
    }

    return items.where((post) {
      final isPrivate = userPrivacy[post.userID] ?? false;
      return _visibilityPolicy.canViewerSeeAuthorFromSummary(
        authorUserId: post.userID,
        followingIds: followingIDs,
        isPrivate: isPrivate,
        isDeleted: false,
      );
    }).toList();
  }
}
