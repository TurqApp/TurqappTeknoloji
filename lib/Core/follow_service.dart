import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

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
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserID == null || currentUserID == otherUserID) {
      return const FollowToggleOutcome(
          nowFollowing: false, limitReached: false);
    }

    final firestore = FirebaseFirestore.instance;

    final myFollowingRef = firestore
        .collection('users')
        .doc(currentUserID)
        .collection('followings')
        .doc(otherUserID);

    final otherFollowersRef = firestore
        .collection('users')
        .doc(otherUserID)
        .collection('followers')
        .doc(currentUserID);

    final counterRef = firestore
        .collection('users')
        .doc(currentUserID)
        .collection('Stats')
        .doc('FollowDaily');

    final result = await firestore
        .runTransaction<FollowToggleOutcome>((transaction) async {
      final myFollowSnap = await transaction.get(myFollowingRef);

      // If already following -> unfollow (no limit check)
      if (myFollowSnap.exists) {
        transaction.delete(myFollowingRef);
        transaction.delete(otherFollowersRef);

        return const FollowToggleOutcome(
            nowFollowing: false, limitReached: false);
      }

      // Not following: enforce daily limit and follow
      final today = _todayKey();
      int currentCount = 0;
      String storedDay = today;

      final counterSnap = await transaction.get(counterRef);
      if (counterSnap.exists) {
        final data = counterSnap.data();
        storedDay = (data?['date'] as String?) ?? today;
        if (storedDay == today) {
          final dynamic raw = data?['count'];
          if (raw is int) currentCount = raw;
        } else {
          currentCount = 0;
        }
      }

      if (currentCount >= dailyLimit) {
        // Do not perform follow, indicate limit reached
        return const FollowToggleOutcome(
            nowFollowing: false, limitReached: true);
      }

      // Proceed to follow and increment counter atomically
      transaction
          .set(myFollowingRef, {'timeStamp': DateTime.now().millisecondsSinceEpoch});
      transaction
          .set(otherFollowersRef, {'timeStamp': DateTime.now().millisecondsSinceEpoch});
      transaction.set(counterRef, {'date': today, 'count': currentCount + 1},
          SetOptions(merge: true));

      return const FollowToggleOutcome(nowFollowing: true, limitReached: false);
    });

    // Agenda'nın followingIDs listesini lokal olarak güncelle (SWR)
    if (Get.isRegistered<AgendaController>()) {
      final agenda = Get.find<AgendaController>();
      if (result.nowFollowing) {
        agenda.followingIDs.add(otherUserID);
      } else {
        agenda.followingIDs.remove(otherUserID);
      }
    }

    return result;
  }

  /// Ensure current user follows [otherUserID].
  /// Returns true when a new follow relation is created, false when already following
  /// or when operation is not possible.
  static Future<bool> ensureFollowing(
    String otherUserID, {
    bool bypassDailyLimit = true,
  }) async {
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserID == null || currentUserID == otherUserID) return false;

    final firestore = FirebaseFirestore.instance;
    final myFollowingRef = firestore
        .collection('users')
        .doc(currentUserID)
        .collection('followings')
        .doc(otherUserID);
    final otherFollowersRef = firestore
        .collection('users')
        .doc(otherUserID)
        .collection('followers')
        .doc(currentUserID);
    final counterRef = firestore
        .collection('users')
        .doc(currentUserID)
        .collection('Stats')
        .doc('FollowDaily');

    final created = await firestore.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(myFollowingRef);
      if (existing.exists) return false;

      if (!bypassDailyLimit) {
        final today = _todayKey();
        int currentCount = 0;
        String storedDay = today;

        final counterSnap = await transaction.get(counterRef);
        if (counterSnap.exists) {
          final data = counterSnap.data();
          storedDay = (data?['date'] as String?) ?? today;
          if (storedDay == today) {
            final dynamic raw = data?['count'];
            if (raw is int) currentCount = raw;
          } else {
            currentCount = 0;
          }
        }

        if (currentCount >= dailyLimit) {
          return false;
        }
        transaction.set(counterRef, {'date': today, 'count': currentCount + 1},
            SetOptions(merge: true));
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.set(myFollowingRef, {'timeStamp': now}, SetOptions(merge: true));
      transaction.set(otherFollowersRef, {'timeStamp': now}, SetOptions(merge: true));
      return true;
    });

    if (created && Get.isRegistered<AgendaController>()) {
      final agenda = Get.find<AgendaController>();
      agenda.followingIDs.add(otherUserID);
    }

    return created;
  }
}
