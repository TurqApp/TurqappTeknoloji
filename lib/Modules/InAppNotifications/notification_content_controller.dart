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

part 'notification_content_controller_runtime_part.dart';

class NotificationContentController extends GetxController {
  static NotificationContentController ensure({
    required String userID,
    required NotificationModel notification,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      NotificationContentController(
        userID: userID,
        notification: notification,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static NotificationContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<NotificationContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<NotificationContentController>(tag: tag);
  }

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
    _NotificationContentControllerRuntimePart(this).handleOnInit();
  }

  Future<void> getPostData(String docID) =>
      _NotificationContentControllerRuntimePart(this).getPostData(docID);

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
}
