import 'package:intl/intl.dart';
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
        'Hesap Engellendi',
        'Bu hesap uygulamaya erişimden kalıcı olarak uzaklaştırıldı.',
      );
      return false;
    }

    final user = _currentUser;
    final untilMs = user?.moderationRestrictedUntil ?? 0;
    final untilText = untilMs > 0
        ? DateFormat('dd.MM.yyyy HH:mm', 'tr_TR')
            .format(DateTime.fromMillisecondsSinceEpoch(untilMs))
        : 'bildirilen süre sonuna';

    AppSnackbar(
      'Geçici Kısıtlama',
      'Bu hesap $untilText tarihine kadar yalnızca gezebilir, beğeni bırakabilir ve yeniden paylaşım yapabilir.',
    );
    return false;
  }
}
