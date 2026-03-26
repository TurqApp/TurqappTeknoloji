part of 'in_app_notifications_controller.dart';

InAppNotificationsController _ensureInAppNotificationsController({
  String? tag,
}) =>
    _maybeFindInAppNotificationsController(tag: tag) ??
    Get.put(InAppNotificationsController(), tag: tag);

InAppNotificationsController? _maybeFindInAppNotificationsController({
  String? tag,
}) =>
    Get.isRegistered<InAppNotificationsController>(tag: tag)
        ? Get.find<InAppNotificationsController>(tag: tag)
        : null;

void _handleInAppNotificationsInit(InAppNotificationsController controller) {
  controller._bindPreferences();
  controller.getData();
}

void _goToInAppNotificationsPage(
  InAppNotificationsController controller,
  int index,
) {
  controller.pageController.animateToPage(
    index,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}

int _readInAppNotificationsUnreadCount(
  InAppNotificationsController controller,
) =>
    controller.unreadTotal.value;

void _handleInAppNotificationsClose(InAppNotificationsController controller) {
  controller._notificationSub?.cancel();
  controller._newNotificationHeadSub?.cancel();
  controller._settingsSub?.cancel();
  controller.pageController.dispose();
}
