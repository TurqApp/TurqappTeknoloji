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
    final currentUserID = CurrentUserService.instance.effectiveUserId;
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
    final agenda = maybeFindAgendaController();
    if (agenda != null) {
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

  static Future<FollowToggleOutcome> toggleFollowFromLocalState(
    String otherUserID, {
    required bool assumedFollowing,
  }) async {
    final currentUserID = CurrentUserService.instance.effectiveUserId;
    if (currentUserID.isEmpty || currentUserID == otherUserID) {
      return const FollowToggleOutcome(
        nowFollowing: false,
        limitReached: false,
      );
    }

    final actualFollowing = await FollowRepository.ensure().isFollowing(
      otherUserID,
      currentUid: currentUserID,
      preferCache: false,
    );
    if (actualFollowing != assumedFollowing) {
      await FollowRepository.ensure().applyToggle(
        currentUserID,
        otherUserID,
        nowFollowing: actualFollowing,
      );
      final agenda = maybeFindAgendaController();
      if (agenda != null) {
        if (actualFollowing) {
          agenda.followingIDs.add(otherUserID);
        } else {
          agenda.followingIDs.remove(otherUserID);
        }
      }
      return FollowToggleOutcome(
        nowFollowing: actualFollowing,
        limitReached: false,
      );
    }
    return toggleFollow(otherUserID);
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
    final currentUserID = CurrentUserService.instance.effectiveUserId;
    if (currentUserID.isEmpty || currentUserID == otherUserID) return false;

    final created = await FollowRepository.ensure().ensureRelation(
      currentUid: currentUserID,
      otherUid: otherUserID,
      bypassDailyLimit: bypassDailyLimit,
      dailyLimit: dailyLimit,
      todayKey: _todayKey(),
    );

    final agenda = maybeFindAgendaController();
    if (created && agenda != null) {
      agenda.followingIDs.add(otherUserID);
    }
    return created;
  }

  static Future<void> createRelationPair(
    String otherUserID, {
    String? currentUid,
    int? timestampMs,
    bool enforceModerationGuard = true,
  }) async {
    if (enforceModerationGuard &&
        !UserModerationGuard.ensureAllowed(
          RestrictedAction.follow,
          showMessage: false,
        )) {
      return;
    }
    final me =
        (currentUid ?? CurrentUserService.instance.effectiveUserId).trim();
    final other = otherUserID.trim();
    if (me.isEmpty || other.isEmpty || me == other) return;
    await FollowRepository.ensure().createRelationPair(
      currentUid: me,
      otherUid: other,
      timestampMs: timestampMs,
    );
    final agenda = maybeFindAgendaController();
    if (agenda != null && me == CurrentUserService.instance.effectiveUserId) {
      agenda.followingIDs.add(other);
    }
  }

  static Future<void> deleteRelationPair(
    String otherUserID, {
    String? currentUid,
  }) async {
    final me =
        (currentUid ?? CurrentUserService.instance.effectiveUserId).trim();
    final other = otherUserID.trim();
    if (me.isEmpty || other.isEmpty || me == other) return;
    await FollowRepository.ensure().deleteRelationPair(
      currentUid: me,
      otherUid: other,
    );
    final agenda = maybeFindAgendaController();
    if (agenda != null && me == CurrentUserService.instance.effectiveUserId) {
      agenda.followingIDs.remove(other);
    }
  }
}
