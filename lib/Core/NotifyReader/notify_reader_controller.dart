import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';

import '../../Modules/Agenda/FloodListing/flood_listing.dart';
import '../../Modules/Agenda/SinglePost/single_post.dart';
import '../../Modules/Chat/chat.dart';
import '../../Modules/SocialProfile/social_profile.dart';
import '../../Models/notification_model.dart';

part 'notify_reader_controller_navigation_part.dart';
part 'notify_reader_controller_runtime_part.dart';

class NotifyReaderController extends GetxController {
  static NotifyReaderController ensure({String? tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(NotifyReaderController(), tag: tag);
  }

  static NotifyReaderController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<NotifyReaderController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<NotifyReaderController>(tag: tag);
  }

  final NotifyLookupRepository _lookupRepository =
      NotifyLookupRepository.ensure();
  final RxString lastOpenedNotificationId = ''.obs;
  final RxString lastOpenedNotificationType = ''.obs;
  final RxString lastOpenedRouteKind = ''.obs;
  final RxString lastOpenedTargetId = ''.obs;
  static const _commentType = kNotificationPostTypeCommentLower;
  static const _profileTypes = {'follow', 'user'};
  static const _tutoringTypes = {'tutoring_application', 'tutoring_status'};
  static const _chatTypes = {'message', 'chat'};
  static const _marketTypes = {'market_offer', 'market_offer_status'};

  Future<void> openNotification(
    NotificationModel model, {
    bool returnToNavbarOnClose = true,
  }) =>
      _NotifyReaderControllerRuntimeX(this).openNotification(
        model,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
}
