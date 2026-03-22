import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/bool_utils.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';

import '../Models/post_interactions_models_new.dart';
import '../Models/posts_model.dart';
import '../Models/user_interactions_models.dart';
import 'current_user_service.dart';
import 'offline_mode_service.dart';
import 'post_moderation_utils.dart';

part 'post_interaction_service_actions_part.dart';
part 'post_interaction_service_moderation_part.dart';
part 'post_interaction_service_query_part.dart';

enum ModerationFlagStatus {
  accepted,
  alreadyFlagged,
  disabled,
  unauthorized,
  postNotFound,
}

class ModerationFlagResult {
  const ModerationFlagResult({
    required this.status,
    this.flagCount = 0,
    this.threshold = 0,
    this.shadowHidden = false,
  });

  final ModerationFlagStatus status;
  final int flagCount;
  final int threshold;
  final bool shadowHidden;

  bool get accepted => status == ModerationFlagStatus.accepted;
  bool get alreadyFlagged => status == ModerationFlagStatus.alreadyFlagged;
  bool get isOk => accepted || alreadyFlagged;
}

/// Post etkileşimlerini yöneten servis.
///
/// Uygulamanın yeni Firestore mimarisine göre tüm etkileşimleri (beğeni,
/// yorum, kaydetme, yeniden paylaşma, görüntüleme, şikayet) Posts alt
/// koleksiyonları ile users alt koleksiyonları arasında çift yönlü olarak
/// senkronize eder.
class PostInteractionService extends GetxController {
  PostInteractionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  static PostInteractionService? maybeFind() {
    final isRegistered = Get.isRegistered<PostInteractionService>();
    if (!isRegistered) return null;
    return Get.find<PostInteractionService>();
  }

  static PostInteractionService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PostInteractionService());
  }

  static const Duration _cacheTTL = Duration(seconds: 30);
  final Map<String, _InteractionCacheEntry> _interactionStatusCache = {};
  final Set<String> _reportedByMe = <String>{};
  bool _permissionDeniedLogged = false;
  static const String _moderationConfigPath = 'adminConfig/moderation';

  String? get currentUserID {
    final uid = CurrentUserService.instance.effectiveUserId;
    return uid.isEmpty ? null : uid;
  }

  bool get _isOffline =>
      !(OfflineModeService.maybeFind()?.isOnline.value ?? true);

  // ---------------------------------------------------------------------------
  // BEĞENİ
  // ---------------------------------------------------------------------------

  /// Post'u beğenir veya beğeniyi kaldırır. İşlem sonucunu döndürür.
  // ---------------------------------------------------------------------------
  // BİLDİRİMLER & SAYIMLAR
  // ---------------------------------------------------------------------------

  Future<void> _createNotification(String postId, String type) async {
    final userId = currentUserID;
    if (userId == null) return;

    try {
      final postDoc = await _postRef(postId).get();
      final ownerId = postDoc.data()?['userID'] as String?;
      if (ownerId == null || ownerId == userId) return;

      final notification = NotificationModel(
        type: normalizeNotificationCreateType(type),
        fromUserID: userId,
        postID: postId,
        timeStamp: _nowMs(),
        read: false,
      ).toMap();

      await NotificationsRepository.ensure().createInboxItem(
        ownerId,
        notification,
      );
    } catch (e) {
      print('Create notification error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // YARDIMCI METODLAR
  // ---------------------------------------------------------------------------

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

  Future<void> _toggleLikeArray(
      DocumentReference<Map<String, dynamic>> ref, String userId) async {
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
                });
    });
  }

  String _cacheKey(String userId, String postId) => '$userId::$postId';

  Future<_ModerationConfigSnapshot> _loadModerationConfig() async {
    try {
      final snap = await _firestore.doc(_moderationConfigPath).get();
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

class _ModerationConfigSnapshot {
  const _ModerationConfigSnapshot({
    required this.enabled,
    required this.threshold,
    required this.allowSingleFlagPerUser,
    required this.enableShadowHide,
  });

  final bool enabled;
  final int threshold;
  final bool allowSingleFlagPerUser;
  final bool enableShadowHide;
}

class _InteractionCacheEntry {
  _InteractionCacheEntry({required this.status, required this.fetchedAt});

  final Map<String, bool> status;
  final DateTime fetchedAt;

  bool isExpired(Duration ttl) => DateTime.now().difference(fetchedAt) > ttl;
}
