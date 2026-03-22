import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/current_user_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

enum RestrictedAction {
  follow,
  comment,
  savePost,
  publishPost,
  publishStory,
  sendMessage,
  saveMarket,
  publishMarket,
  saveJob,
  reviewJob,
  saveTutoring,
  publishTutoring,
  externalShare,
}

class UserModerationGuard {
  UserModerationGuard._();

  static CurrentUserModel? get _currentUser =>
      CurrentUserService.instance.currentUser;

  static bool get isPermanentlyBanned =>
      _currentUser?.isPermanentAppBan ?? false;

  static bool get isInteractionRestricted =>
      _currentUser?.hasActiveInteractionRestriction ?? false;

  static bool allow(RestrictedAction action) {
    final _ = action;
    if (isPermanentlyBanned) return false;
    return !isInteractionRestricted;
  }

  static bool ensureAllowed(
    RestrictedAction action, {
    bool showMessage = true,
  }) {
    if (allow(action)) return true;
    if (!showMessage) return false;

    if (isPermanentlyBanned) {
      AppSnackbar(
        'moderation_guard.banned_title'.tr,
        'moderation_guard.banned_body'.tr,
      );
      return false;
    }

    final user = _currentUser;
    final untilMs = user?.moderationRestrictedUntil ?? 0;
    final localeTag = Get.locale?.toLanguageTag().replaceAll('-', '_') ?? 'tr_TR';
    final untilText = untilMs > 0
        ? DateFormat('dd.MM.yyyy HH:mm', localeTag)
            .format(DateTime.fromMillisecondsSinceEpoch(untilMs))
        : 'moderation_guard.until_notice'.tr;

    AppSnackbar(
      'moderation_guard.restricted_title'.tr,
      'moderation_guard.restricted_body'.trParams({'until': untilText}),
    );
    return false;
  }
}
