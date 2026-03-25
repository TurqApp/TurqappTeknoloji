part of 'post_interaction_service.dart';

extension PostInteractionServiceHelpersPart on PostInteractionService {
  DocumentReference<Map<String, dynamic>> _postRef(String postId) =>
      _firestore.collection('Posts').doc(postId);

  CollectionReference<Map<String, dynamic>> _userLikesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('liked_posts');

  CollectionReference<Map<String, dynamic>> _userSavedRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('saved_posts');

  CollectionReference<Map<String, dynamic>> _userCommentsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('commented_posts');

  CollectionReference<Map<String, dynamic>> _userResharedRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('reshared_posts');

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  PostStats _statsFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? const {};
    return PostStats.fromPostData(data);
  }

  String _resolveNotificationPreviewImage(Map<String, dynamic> data) {
    final thumbnail = (data['thumbnail'] ?? '').toString().trim();
    if (thumbnail.isNotEmpty) return thumbnail;

    final imageUrl =
        (data['imageUrl'] ?? data['imageURL'] ?? '').toString().trim();
    if (imageUrl.isNotEmpty) return imageUrl;

    final img = data['img'];
    if (img is Iterable) {
      for (final entry in img) {
        final next = entry.toString().trim();
        if (next.isNotEmpty) return next;
      }
    }

    return '';
  }

  Future<void> _toggleLikeArray(
    DocumentReference<Map<String, dynamic>> ref,
    String userId,
  ) async {
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final likes = List<String>.from(data['likes'] ?? const []);
      final bool alreadyLiked = likes.contains(userId);

      tx.update(
        ref,
        alreadyLiked
            ? {
                'likes': FieldValue.arrayRemove([userId])
              }
            : {
                'likes': FieldValue.arrayUnion([userId])
              },
      );
    });
  }

  String _cacheKey(String userId, String postId) => '$userId::$postId';

  Future<_ModerationConfigSnapshot> _loadModerationConfig() async {
    try {
      final snap = await _firestore
          .doc(PostInteractionService._moderationConfigPath)
          .get();
      final raw = snap.data() ?? const <String, dynamic>{};
      return _ModerationConfigSnapshot(
        enabled: _asBool(raw['enabled'], fallback: true),
        threshold: _asInt(raw['blackBadgeFlagThreshold'], fallback: 5),
        allowSingleFlagPerUser:
            _asBool(raw['allowSingleFlagPerUser'], fallback: true),
        enableShadowHide: _asBool(raw['enableShadowHide'], fallback: true),
      );
    } catch (_) {
      return const _ModerationConfigSnapshot(
        enabled: true,
        threshold: 5,
        allowSingleFlagPerUser: true,
        enableShadowHide: true,
      );
    }
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    return parseFlexibleBool(value, fallback: fallback);
  }

  void _updateInteractionCache(
    String postId, {
    bool? like,
    bool? saved,
    bool? reshared,
    bool? reported,
    bool? comment,
  }) {
    final userId = currentUserID;
    if (userId == null) return;
    final key = _cacheKey(userId, postId);
    final existing = _interactionStatusCache[key];
    if (existing == null) return;

    final updated = Map<String, bool>.from(existing.status);
    if (like != null) updated['liked'] = like;
    if (saved != null) updated['saved'] = saved;
    if (reshared != null) updated['reshared'] = reshared;
    if (reported != null) updated['reported'] = reported;
    _interactionStatusCache[key] =
        _InteractionCacheEntry(status: updated, fetchedAt: DateTime.now());
  }

  Future<bool> _isLikedFromLocal(String postId, String userId) async {
    try {
      final doc = await _postRef(postId)
          .collection('likes')
          .doc(userId)
          .get(const GetOptions(source: Source.cache));
      return doc.exists;
    } catch (_) {
      final key = _cacheKey(userId, postId);
      return _interactionStatusCache[key]?.status['liked'] ?? false;
    }
  }

  Future<bool> _isSavedFromLocal(String postId, String userId) async {
    try {
      final doc = await _postRef(postId)
          .collection('saveds')
          .doc(userId)
          .get(const GetOptions(source: Source.cache));
      return doc.exists;
    } catch (_) {
      final key = _cacheKey(userId, postId);
      return _interactionStatusCache[key]?.status['saved'] ?? false;
    }
  }
}
