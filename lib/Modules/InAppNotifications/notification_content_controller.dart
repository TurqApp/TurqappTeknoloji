import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Models/posts_model.dart';

class NotificationContentController extends GetxController {
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
    final normalizedType = _normalizedType(notification.type, notification.postType);
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

    if (_isPostType(normalizedType)) {
      await getPostData(postId);
      if (targetHint.value.isEmpty) {
        targetHint.value = _fallbackHint(normalizedType);
      }
      return;
    }

    if (normalizedType == "job_application") {
      final lookup = await _notifyLookupRepository.getJobLookup(postId);
      final label = lookup.model?.ilanBasligi.trim().isNotEmpty == true
          ? lookup.model!.ilanBasligi.trim()
          : lookup.model?.brand.trim() ?? "";
      targetHint.value = label.isNotEmpty
          ? "notification.hint.listing_named".trParams({'label': label})
          : "notification.hint.listing".tr;
      return;
    }

    if (normalizedType == "tutoring_application" ||
        normalizedType == "tutoring_status") {
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
        _normalizedType(notification.type, notification.postType);
    final rawTitle = notification.title.trim();
    final preview = rawTitle.isNotEmpty
        ? rawTitle
        : post.metin.trim().isNotEmpty
            ? post.metin.trim()
            : post.konum.trim();
    final normalizedPreview = preview.replaceAll(RegExp(r'\s+'), ' ').trim();
    final prefix = normalizedType == "comment"
        ? "notification.hint.comments".tr
        : "notification.hint.post".tr;
    if (normalizedPreview.isEmpty) return prefix;
    return "$prefix: $normalizedPreview";
  }

  bool _isPostType(String normalizedType) {
    return normalizedType == "posts" ||
        normalizedType == "like" ||
        normalizedType == "comment" ||
        normalizedType == "reshared_posts" ||
        normalizedType == "shared_as_posts" ||
        normalizedType == "reshare";
  }

  String _normalizedType(String type, String postType) {
    final normalizedType = type.trim().toLowerCase();
    if (normalizedType.isNotEmpty) return normalizedType;
    return postType.trim().toLowerCase();
  }

  String _fallbackHint(String normalizedType) {
    switch (normalizedType) {
      case "comment":
        return "notification.hint.comments".tr;
      case "job_application":
        return "notification.hint.listing".tr;
      case "tutoring_application":
      case "tutoring_status":
        return "notification.hint.tutoring".tr;
      case "message":
      case "chat":
        return "notification.hint.chat".tr;
      case "follow":
      case "user":
        return "notification.hint.profile".tr;
      default:
        return "notification.hint.post".tr;
    }
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
      nickname.value = "TurqApp";
      return;
    }
    avatarUrl.value = user.avatarUrl;
    nickname.value = user.nickname.isNotEmpty ? user.nickname : user.preferredName;
  }

  Future<void> _loadFollowingState() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty) return;
    following.value = await _followRepository.isFollowing(
      userID,
      currentUid: currentUid,
      preferCache: true,
    );
  }
}
