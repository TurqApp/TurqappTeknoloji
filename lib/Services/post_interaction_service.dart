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
part 'post_interaction_service_helpers_part.dart';
part 'post_interaction_service_moderation_part.dart';
part 'post_interaction_service_query_part.dart';
part 'post_interaction_service_models_part.dart';

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
      final postData = postDoc.data() ?? const <String, dynamic>{};
      final ownerId = postData['userID'] as String?;
      if (ownerId == null || ownerId == userId) return;

      final notification = NotificationModel(
        type: normalizeNotificationCreateType(type),
        fromUserID: userId,
        postID: postId,
        timeStamp: _nowMs(),
        read: false,
      ).toMap();
      final previewImage = _resolveNotificationPreviewImage(postData);
      if (previewImage.isNotEmpty) {
        notification['imageUrl'] = previewImage;
        notification['thumbnail'] = previewImage;
      }

      await NotificationsRepository.ensure().createInboxItem(
        ownerId,
        notification,
      );
    } catch (e) {
      print('Create notification error: $e');
    }
  }
}
