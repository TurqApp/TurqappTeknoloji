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

part 'notification_content_controller_fields_part.dart';
part 'notification_content_controller_actions_part.dart';
part 'notification_content_controller_facade_part.dart';
part 'notification_content_controller_runtime_part.dart';

class NotificationContentController extends GetxController {
  static NotificationContentController ensure({
    required String userID,
    required NotificationModel notification,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureNotificationContentController(
        userID: userID,
        notification: notification,
        tag: tag,
        permanent: permanent,
      );

  static NotificationContentController? maybeFind({String? tag}) =>
      _maybeFindNotificationContentController(tag: tag);

  static const String _userType = kNotificationPostTypeUserLower;
  static const String _commentType = kNotificationPostTypeCommentLower;
  static const String _chatType = kNotificationPostTypeChatLower;
  static const String _jobApplicationType =
      kNotificationPostTypeJobApplicationLower;
  static const String _tutoringApplicationType =
      kNotificationPostTypeTutoringApplicationLower;

  String userID;
  final NotificationModel notification;
  final _state = _NotificationContentControllerState();

  NotificationContentController({
    required this.userID,
    required this.notification,
  });
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  final NotifyLookupRepository _notifyLookupRepository =
      NotifyLookupRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _handleNotificationContentInit(this);
  }

  Future<void> getPostData(String docID) =>
      _loadNotificationContentPostData(this, docID);

  Future<void> toggleFollowStatus(String userID) =>
      _toggleNotificationContentFollowStatus(this, userID);
}
