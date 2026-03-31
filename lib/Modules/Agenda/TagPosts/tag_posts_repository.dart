import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class TagPostsRepository {
  static const int _typesenseTagResultLimit = 50;

  final FirebaseFirestore _db;
  final PostRepository _postRepository;
  final VisibilityPolicyService _visibilityPolicy;
  final UserRepository _userRepository;
  final List<FirebaseFunctions> _functionsTargets = <FirebaseFunctions>[
    FirebaseFunctions.instance,
    FirebaseFunctions.instanceFor(region: 'us-central1'),
    FirebaseFunctions.instanceFor(region: 'europe-west1'),
  ];

  TagPostsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        _postRepository = PostRepository.ensure(),
        _visibilityPolicy = VisibilityPolicyService.ensure(),
        _userRepository = UserRepository.ensure();

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  Future<List<PostsModel>> fetchByTag(String tag) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final normalizedTag = _normalizeTag(tag);

    var posts = await _queryPostsByTagTypesense(normalizedTag);
    posts = await _filterByPrivacy(posts);
    posts = _filterByTimestamp(posts, nowMs);
    if (posts.isNotEmpty) return posts;

    final queries = _buildQueries(tag);
    posts = await _queryPostsByTag(queries, nowMs);
    posts = await _filterByPrivacy(posts);

    if (posts.isNotEmpty) return posts;

    final capitalizedQueries = _buildQueries(_capitalizeAfterHash(tag));
    posts = await _queryPostsByTag(capitalizedQueries, nowMs);
    posts = await _filterByPrivacy(posts);
    if (posts.isNotEmpty) return posts;

    // Fallback: tags/{tag}/posts alt koleksiyonundan post ID topla
    posts = await _queryFromTagIndex(tag, nowMs);
    posts = await _filterByPrivacy(posts);
    if (posts.isNotEmpty) return posts;

    final capTag = _capitalizeAfterHash(tag);
    posts = await _queryFromTagIndex(capTag, nowMs);
    posts = await _filterByPrivacy(posts);
    return posts;
  }

  String _normalizeTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
  }

  List<String> _buildQueries(String tag) {
    final t = tag.trim();
    if (t.isEmpty) return const [];
    final set = <String>{t};
    if (!t.startsWith("#")) set.add("#$t");
    return set.toList();
  }

  Future<List<PostsModel>> _queryPostsByTag(
      List<String> queries, int nowMs) async {
    if (queries.isEmpty) return const [];
    final snap = await _db
        .collection("Posts")
        .where("tags", arrayContainsAny: queries)
        .limit(1000)
        .get();

    return snap.docs
        .map((doc) => PostsModel.fromMap(doc.data(), doc.id))
        .where((p) => p.deletedPost != true)
        .where((p) => p.arsiv != true)
        .where((p) => p.timeStamp <= nowMs)
        .toList();
  }

  Future<List<PostsModel>> _queryPostsByTagTypesense(String tag) async {
    final normalized = _normalizeTag(tag);
    final currentUid = _currentUid.trim();
    if (normalized.isEmpty || currentUid.isEmpty) return const [];

    Object? lastError;
    for (final fn in _functionsTargets) {
      try {
        final response = await fn.httpsCallable('f14_searchPostsCallable').call(
          <String, dynamic>{
            'q': '',
            'tag': normalized,
            'limit': _typesenseTagResultLimit,
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

  Future<List<PostsModel>> _queryFromTagIndex(String tag, int nowMs) async {
    final normalized = tag.replaceFirst('#', '').trim();
    if (normalized.isEmpty) return const [];

    try {
      final indexSnap = await _db
          .collection('tags')
          .doc(normalized)
          .collection('posts')
          .limit(300)
          .get();

      if (indexSnap.docs.isEmpty) return const [];

      final ids = <String>[];
      for (final d in indexSnap.docs) {
        final data = d.data();
        final postId = (data['postId'] ?? data['id'] ?? d.id).toString();
        if (postId.isNotEmpty) ids.add(postId);
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
      return results;
    } catch (_) {
      return const [];
    }
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
