import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Models/posts_model.dart';

class TagPostsRepository {
  final FirebaseFirestore _db;

  TagPostsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<List<PostsModel>> fetchByTag(String tag) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final queries = _buildQueries(tag);

    var posts = await _queryPostsByTag(queries, nowMs);
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

  List<String> _buildQueries(String tag) {
    final t = tag.trim();
    if (t.isEmpty) return const [];
    final set = <String>{t};
    if (!t.startsWith("#")) set.add("#$t");
    return set.toList();
  }

  Future<List<PostsModel>> _queryPostsByTag(List<String> queries, int nowMs) async {
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return items;

    final followingSnap =
        await _db.collection('users').doc(uid).collection('TakipEdilenler').get();
    final followingIDs = followingSnap.docs.map((d) => d.id).toSet();
    final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();

    final Map<String, bool> userPrivacy = {};
    for (var i = 0; i < uniqueUserIDs.length; i += 10) {
      final chunk = uniqueUserIDs.sublist(
        i,
        i + 10 > uniqueUserIDs.length ? uniqueUserIDs.length : i + 10,
      );
      try {
        final usersSnap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final d in usersSnap.docs) {
          userPrivacy[d.id] = (d.data()['gizliHesap'] ?? false) == true;
        }
      } catch (_) {}
    }

    return items.where((post) {
      final isPrivate = userPrivacy[post.userID] ?? false;
      if (!isPrivate) return true;
      final isMine = post.userID == uid;
      final follows = followingIDs.contains(post.userID);
      return isMine || follows;
    }).toList();
  }
}
