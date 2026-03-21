import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class NotificationContentController extends GetxController {
  static const String _userType = kNotificationPostTypeUserLower;
  static const String _commentType = kNotificationPostTypeCommentLower;
  static const String _chatType = kNotificationPostTypeChatLower;
  static const String _jobApplicationType =
      kNotificationPostTypeJobApplicationLower;
  static const String _tutoringApplicationType =
      kNotificationPostTypeTutoringApplicationLower;

  String userID;
  final NotificationModel notification;

  NotificationContentController({
    required this.userID,
    required this.notification,
  });
  var avatarUrl = "".obs;
  var nickname = "".obs;
  var following = false.obs;
  var followLoading = false.obs;
  var model = PostsModel.empty().obs;
  var targetHint = "".obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  final NotifyLookupRepository _notifyLookupRepository =
      NotifyLookupRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _loadFollowingState();
    _loadTargetHint();
  }

  Future<void> getPostData(String docID) async {
    final lookup = await _notifyLookupRepository.getPostLookup(docID);
    final m = lookup.model;
    if (m == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isVisibleNow = m.timeStamp <= nowMs;
    if (isVisibleNow && m.deletedPost != true) {
      model.value = m;
      targetHint.value = _buildPostHint(m);
    } else {
      model.value = PostsModel.empty();
    }
  }

  Future<void> _loadTargetHint() async {
    final normalizedType =
        normalizeNotificationType(notification.type, notification.postType);
    final postId = notification.postID.trim();

    if (normalizedType == "follow" || normalizedType == "user") {
      targetHint.value = "notification.hint.profile".tr;
      return;
    }

    if (normalizedType == "message" || normalizedType == "chat") {
      targetHint.value = "notification.hint.chat".tr;
      return;
    }

    if (postId.isEmpty) {
      targetHint.value = _fallbackHint(normalizedType);
      return;
    }

    if (isNotificationPostType(normalizedType)) {
      await getPostData(postId);
      if (targetHint.value.isEmpty) {
        targetHint.value = _fallbackHint(normalizedType);
      }
      return;
    }

    if (isJobNotificationType(normalizedType)) {
      final lookup = await _notifyLookupRepository.getJobLookup(postId);
      final label = lookup.model?.ilanBasligi.trim().isNotEmpty == true
          ? lookup.model!.ilanBasligi.trim()
          : lookup.model?.brand.trim() ?? "";
      targetHint.value = label.isNotEmpty
          ? "notification.hint.listing_named".trParams({'label': label})
          : "notification.hint.listing".tr;
      return;
    }

    if (isTutoringNotificationType(normalizedType)) {
      final lookup = await _notifyLookupRepository.getTutoringLookup(postId);
      final label = lookup.model?.baslik.trim() ?? "";
      targetHint.value = label.isNotEmpty
          ? "notification.hint.listing_named".trParams({'label': label})
          : "notification.hint.tutoring".tr;
      return;
    }

    targetHint.value = _fallbackHint(normalizedType);
  }

  String _buildPostHint(PostsModel post) {
    final normalizedType =
        normalizeNotificationType(notification.type, notification.postType);
    final rawTitle = notification.title.trim();
    final preview = rawTitle.isNotEmpty
        ? rawTitle
        : post.metin.trim().isNotEmpty
            ? post.metin.trim()
            : post.konum.trim();
    final normalizedPreview = preview.replaceAll(RegExp(r'\s+'), ' ').trim();
    final prefix = normalizedType == _commentType
        ? "notification.hint.comments".tr
        : "notification.hint.post".tr;
    if (normalizedPreview.isEmpty) return prefix;
    return "$prefix: $normalizedPreview";
  }

  String _fallbackHint(String normalizedType) {
    if (normalizedType == _commentType) {
      return "notification.hint.comments".tr;
    }
    if (isJobNotificationType(normalizedType) ||
        normalizedType == _jobApplicationType) {
      return "notification.hint.listing".tr;
    }
    if (isTutoringNotificationType(normalizedType) ||
        normalizedType == _tutoringApplicationType) {
      return "notification.hint.tutoring".tr;
    }
    if (normalizedType == "message" || normalizedType == _chatType) {
      return "notification.hint.chat".tr;
    }
    if (normalizedType == "follow" || normalizedType == _userType) {
      return "notification.hint.profile".tr;
    }
    return "notification.hint.post".tr;
  }

  Future<void> toggleFollowStatus(String userID) async {
    if (followLoading.value) return;
    final wasFollowing = following.value;
    following.value = !wasFollowing; // optimistic
    followLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      following.value = outcome.nowFollowing; // reconcile
      if (outcome.limitReached) {
        AppSnackbar(
          'following.limit_title'.tr,
          'following.limit_body'.tr,
        );
      }
    } catch (e) {
      following.value = wasFollowing; // revert
    } finally {
      followLoading.value = false;
    }
  }

  Future<void> _loadUser() async {
    final user = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (user == null) {
      avatarUrl.value = "";
      nickname.value = 'app.name'.tr;
      return;
    }
    avatarUrl.value = user.avatarUrl;
    nickname.value = user.nickname.isNotEmpty ? user.nickname : user.preferredName;
  }

  Future<void> _loadFollowingState() async {
    final currentUid = CurrentUserService.instance.userId.trim();
    if (currentUid.isEmpty) return;
    following.value = await _followRepository.isFollowing(
      userID,
      currentUid: currentUid,
      preferCache: true,
    );
  }
}
