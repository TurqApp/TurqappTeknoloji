import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:flutter/material.dart';

class MyTutoringsController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
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
      errorMessage.value = "Kullanıcı kimliği bulunamadı.";
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
      await fetchMyTutorings(
        currentUserId,
        silent: true,
        forceRefresh: true,
      );
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
    } catch (e) {
      errorMessage.value = "İlanlar yüklenirken hata oluştu: $e";
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
    AppSnackbar("İlan Yenilendi", "İlan tekrar yayına alındı.");
  }

  Future<void> fetchUsers(
    Set<String> userIds, {
    bool cacheOnly = false,
  }) async {
    final toFetch = userIds.where((id) => !users.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      final rawUsers = await _userRepository.getUsersRaw(
        toFetch,
        preferCache: true,
        cacheOnly: cacheOnly,
      );
      for (final entry in rawUsers.entries) {
        users[entry.key] = entry.value;
      }
    } catch (e) {
      errorMessage.value = "Kullanıcı bilgileri yüklenirken hata oluştu: $e";
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
