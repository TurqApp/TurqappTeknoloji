import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';

import '../Models/posts_model.dart';
import '../Models/user_post_reference.dart';

/// Kullanıcı-post ilişkilerini yöneten yardımcı servis.
class UserPostLinkService {
  static UserPostLinkService? maybeFind() {
    final isRegistered = Get.isRegistered<UserPostLinkService>();
    if (!isRegistered) return null;
    return Get.find<UserPostLinkService>();
  }

  static UserPostLinkService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UserPostLinkService(), permanent: true);
  }

  UserPostLinkService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _userSubcollectionRepository = ensureUserSubcollectionRepository(),
        _postRepository = PostRepository.ensure();

  final FirebaseFirestore _firestore;
  final UserSubcollectionRepository _userSubcollectionRepository;
  final PostRepository _postRepository;
  static const int _maxRefsPerFetch =
      ReadBudgetRegistry.savedPostRefsInitialLimit;

  Stream<List<UserPostReference>> listenLikedPosts(String userId) =>
      _listenUserRefs(userId, 'liked_posts');

  Stream<List<UserPostReference>> listenSavedPosts(String userId) =>
      _listenUserRefs(userId, 'saved_posts');

  Stream<List<UserPostReference>> listenCommentedPosts(String userId) =>
      _listenUserRefs(userId, 'commented_posts');

  Stream<List<UserPostReference>> listenResharedPosts(String userId) =>
      _listenUserRefs(userId, 'reshared_posts');

  Stream<List<UserPostReference>> listenSharedAsPosts(String userId) =>
      _listenUserRefs(userId, 'shared_as_posts');

  Stream<List<UserPostReference>> _listenUserRefs(
      String userId, String collection) {
    return (() async* {
      final cached = await _userSubcollectionRepository.getEntries(
        userId,
        subcollection: collection,
        orderByField: 'timeStamp',
        limit: _maxRefsPerFetch,
        descending: true,
        preferCache: true,
      );
      if (cached.isNotEmpty) {
        yield cached
            .map(
              (entry) => UserPostReference.fromMap(entry.data, entry.id),
            )
            .toList(growable: false);
      }

      yield* _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .orderBy('timeStamp', descending: true)
          .limit(_maxRefsPerFetch)
          .snapshots()
          .asyncMap((snap) async {
        final entries = snap.docs
            .map(
              (doc) => UserSubcollectionEntry(
                id: doc.id,
                data: Map<String, dynamic>.from(doc.data()),
              ),
            )
            .toList(growable: false);
        await _userSubcollectionRepository.setEntries(
          userId,
          subcollection: collection,
          items: entries,
        );
        return snap.docs.map(UserPostReference.fromDoc).toList(growable: false);
      });
    })();
  }

  /// Verilen referanslar için Posts koleksiyonundan modelleri getirir.
  Future<List<PostsModel>> fetchPostsByRefs(
    String userId,
    String collection,
    List<UserPostReference> refs, {
    bool removeMissing = true,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (refs.isEmpty) return const [];

    final normalizedRefs = _dedupeRefsByPostId(refs);
    final limitedRefs = normalizedRefs.length > _maxRefsPerFetch
        ? normalizedRefs.sublist(0, _maxRefsPerFetch)
        : normalizedRefs;
    final referenceTimes = {
      for (final ref in limitedRefs) ref.postId: ref.timeStamp
    };
    final List<PostsModel> result = [];
    final List<String> missingIds = [];

    for (var i = 0; i < limitedRefs.length; i += 10) {
      final chunk = limitedRefs.sublist(
        i,
        i + 10 > limitedRefs.length ? limitedRefs.length : i + 10,
      );
      final ids = chunk.map((e) => e.postId).toSet().toList();
      final query = await _postRepository.fetchPostCardsByIds(
        ids,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

      final foundIds = <String>{};
      for (final entry in query.entries) {
        foundIds.add(entry.key);
        result.add(entry.value);
      }

      for (final ref in chunk) {
        if (!foundIds.contains(ref.postId)) {
          missingIds.add(ref.docId);
        }
      }
    }

    if (!cacheOnly && removeMissing && missingIds.isNotEmpty) {
      await _removeMissingRefs(userId, collection, missingIds.toSet());
    }

    // Gönderileri zaman damgasına göre sıralı dön.
    result.sort((a, b) {
      final timeB = referenceTimes[b.docID] ?? b.timeStamp;
      final timeA = referenceTimes[a.docID] ?? a.timeStamp;
      return timeB.compareTo(timeA);
    });
    return result;
  }

  List<UserPostReference> _dedupeRefsByPostId(List<UserPostReference> refs) {
    final seen = <String>{};
    final out = <UserPostReference>[];
    for (final ref in refs) {
      if (ref.postId.isEmpty) continue;
      if (!seen.add(ref.postId)) continue;
      out.add(ref);
    }
    return out;
  }

  Future<void> _removeMissingRefs(
      String userId, String collection, Set<String> missingIds) async {
    if (missingIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final docId in missingIds) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .doc(docId);
      batch.delete(docRef);
    }
    await batch.commit();
    await _userSubcollectionRepository.invalidate(
      userId,
      subcollection: collection,
    );
  }

  Future<List<PostsModel>> fetchLikedPosts(
    String userId,
    List<UserPostReference> refs, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      fetchPostsByRefs(
        userId,
        'liked_posts',
        refs,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<PostsModel>> fetchSavedPosts(
    String userId,
    List<UserPostReference> refs, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      fetchPostsByRefs(
        userId,
        'saved_posts',
        refs,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<PostsModel>> fetchResharedPosts(
    String userId,
    List<UserPostReference> refs, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      fetchPostsByRefs(
        userId,
        'reshared_posts',
        refs,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<PostsModel>> fetchSharedAsPosts(
    String userId,
    List<UserPostReference> refs, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      fetchPostsByRefs(
        userId,
        'shared_as_posts',
        refs,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
}
