import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:flutter/material.dart';

class MyTutoringsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  final RxList<TutoringModel> myTutorings = <TutoringModel>[].obs;
  final RxMap<String, Map<String, dynamic>> users =
      <String, Map<String, dynamic>>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TutoringModel> activeTutorings = <TutoringModel>[].obs;
  final RxList<TutoringModel> expiredTutorings = <TutoringModel>[].obs;
  final PageController pageController = PageController();
  final RxInt selection = 0.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    final uid = getCurrentUserId();
    if (uid != null) {
      unawaited(_bootstrapData(uid));
    } else {
      errorMessage.value = 'tutoring.user_id_missing'.tr;
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  Future<void> _bootstrapData(String currentUserId) async {
    final cached = await _tutoringRepository.fetchByOwner(
      currentUserId,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      myTutorings.assignAll(cached);
      updateTutoringsStatus();
      final userIds = cached.map((t) => t.userID).toSet();
      if (userIds.isNotEmpty) {
        await fetchUsers(userIds, cacheOnly: true);
      }
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tutoring:owner:$currentUserId',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(fetchMyTutorings(
          currentUserId,
          silent: true,
          forceRefresh: true,
        ));
      }
      return;
    }
    await fetchMyTutorings(currentUserId);
  }

  Future<void> fetchMyTutorings(
    String currentUserId, {
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || myTutorings.isEmpty) {
      isLoading.value = true;
    }
    try {
      final tutorings = await _tutoringRepository.fetchByOwner(
        currentUserId,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      await _archiveExpiredTutorings(tutorings);
      final refreshed = await _tutoringRepository.fetchByOwner(
        currentUserId,
        preferCache: false,
        forceRefresh: true,
      );
      myTutorings.assignAll(refreshed);

      updateTutoringsStatus();

      final userIds = refreshed.map((t) => t.userID).toSet();
      if (userIds.isNotEmpty) {
        await fetchUsers(userIds);
      }
      SilentRefreshGate.markRefreshed('tutoring:owner:$currentUserId');
    } catch (e) {
      errorMessage.value = 'tutoring.load_failed'.trParams({
        'error': e.toString(),
      });
    } finally {
      isLoading.value = false;
    }
  }

  void updateTutoringsStatus() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;
    activeTutorings.clear();
    expiredTutorings.clear();

    for (var tutoring in myTutorings) {
      if (tutoring.ended == true ||
          now - tutoring.timeStamp > thirtyDaysInMillis) {
        expiredTutorings.add(tutoring);
      } else {
        activeTutorings.add(tutoring);
      }
    }
  }

  Future<void> _archiveExpiredTutorings(List<TutoringModel> tutorings) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);
    final batch = FirebaseFirestore.instance.batch();
    var changed = false;

    for (final tutoring in tutorings) {
      if (tutoring.ended == true) continue;
      if (tutoring.timeStamp < thirtyDaysAgo) {
        batch.update(
          FirebaseFirestore.instance.collection('educators').doc(tutoring.docID),
          {'ended': true, 'endedAt': now},
        );
        changed = true;
      }
    }

    if (changed) {
      await batch.commit();
    }
  }

  Future<void> reactivateEndedTutoring(TutoringModel tutoring) async {
    final uid = getCurrentUserId();
    if (uid == null || tutoring.userID != uid || tutoring.ended != true) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await FirebaseFirestore.instance
        .collection('educators')
        .doc(tutoring.docID)
        .update({
      'ended': false,
      'endedAt': 0,
      'timeStamp': now,
    });

    await fetchMyTutorings(uid);
    AppSnackbar(
      'tutoring.reactivated_title'.tr,
      'tutoring.reactivated_body'.tr,
    );
  }

  Future<void> fetchUsers(
    Set<String> userIds, {
    bool cacheOnly = false,
  }) async {
    final toFetch = userIds.where((id) => !users.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      final rawUsers = await _userSummaryResolver.resolveMany(
        toFetch,
        preferCache: true,
        cacheOnly: cacheOnly,
      );
      for (final entry in rawUsers.entries) {
        users[entry.key] = entry.value.toMap();
      }
    } catch (e) {
      errorMessage.value = 'tutoring.user_load_failed'.trParams({
        'error': e.toString(),
      });
    }
  }

  String? getCurrentUserId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return (uid != null && uid.isNotEmpty) ? uid : null;
  }

  void goToPage(int index) {
    selection.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
