import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class FollowToggleOutcome {
  final bool nowFollowing;
  final bool limitReached;
  const FollowToggleOutcome(
      {required this.nowFollowing, required this.limitReached});
}

class FollowService {
  static const int dailyLimit = 15;

  static String _todayKey() {
    // yyyyMMdd format, local time
    return DateFormat('yyyyMMdd').format(DateTime.now());
  }

  static Future<FollowToggleOutcome> toggleFollow(String otherUserID) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.follow)) {
      return const FollowToggleOutcome(
        nowFollowing: false,
        limitReached: false,
      );
    }
    final currentUserID = CurrentUserService.instance.userId;
    if (currentUserID.isEmpty || currentUserID == otherUserID) {
      return const FollowToggleOutcome(
          nowFollowing: false, limitReached: false);
    }

    final result = await FollowRepository.ensure().toggleRelation(
      currentUid: currentUserID,
      otherUid: otherUserID,
      dailyLimit: dailyLimit,
      todayKey: _todayKey(),
    );

    // Agenda'nın followingIDs listesini lokal olarak güncelle (SWR)
    if (Get.isRegistered<AgendaController>()) {
      final agenda = Get.find<AgendaController>();
      if (result.nowFollowing) {
        agenda.followingIDs.add(otherUserID);
      } else {
        agenda.followingIDs.remove(otherUserID);
      }
    }
    return FollowToggleOutcome(
      nowFollowing: result.nowFollowing,
      limitReached: result.limitReached,
    );
  }

  /// Ensure current user follows [otherUserID].
  /// Returns true when a new follow relation is created, false when already following
  /// or when operation is not possible.
  static Future<bool> ensureFollowing(
    String otherUserID, {
    bool bypassDailyLimit = true,
  }) async {
    if (!UserModerationGuard.ensureAllowed(
      RestrictedAction.follow,
      showMessage: false,
    )) {
      return false;
    }
    final currentUserID = CurrentUserService.instance.userId;
    if (currentUserID.isEmpty || currentUserID == otherUserID) return false;

    final created = await FollowRepository.ensure().ensureRelation(
      currentUid: currentUserID,
      otherUid: otherUserID,
      bypassDailyLimit: bypassDailyLimit,
      dailyLimit: dailyLimit,
      todayKey: _todayKey(),
    );

    if (created && Get.isRegistered<AgendaController>()) {
      final agenda = Get.find<AgendaController>();
      agenda.followingIDs.add(otherUserID);
    }
    return created;
  }
}
