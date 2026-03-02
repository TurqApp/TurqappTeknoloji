import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:flutter/material.dart';

class MyTutoringsController extends GetxController {
  final RxList<TutoringModel> myTutorings = <TutoringModel>[].obs;
  final RxMap<String, Map<String, dynamic>> users =
      <String, Map<String, dynamic>>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TutoringModel> activeTutorings = <TutoringModel>[].obs;
  final RxList<TutoringModel> expiredTutorings = <TutoringModel>[].obs;
  final PageController pageController = PageController();
  final RxInt selection = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final uid = getCurrentUserId();
    if (uid != null) {
      fetchMyTutorings(uid);
    } else {
      errorMessage.value = "Kullanıcı kimliği bulunamadı.";
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  Future<void> fetchMyTutorings(String currentUserId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('educators')
          .where('userID', isEqualTo: currentUserId)
          .get();

      final tutorings = snapshot.docs.map((doc) {
        return TutoringModel.fromJson(doc.data(), doc.id);
      }).toList();
      myTutorings.assignAll(tutorings);

      updateTutoringsStatus();

      final userIds = tutorings.map((t) => t.userID).toSet();
      if (userIds.isNotEmpty) {
        await fetchUsers(userIds);
      }
    } catch (e) {
      errorMessage.value = "İlanlar yüklenirken hata oluştu: $e";
      log("Error fetching my tutorings: $e");
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

  Future<void> fetchUsers(Set<String> userIds) async {
    final toFetch = userIds.where((id) => !users.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      for (var i = 0; i < toFetch.length; i += 30) {
        final batch = toFetch.skip(i).take(30).toList();
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (var doc in snap.docs) {
          users[doc.id] = doc.data();
        }
      }
    } catch (e) {
      errorMessage.value = "Kullanıcı bilgileri yüklenirken hata oluştu: $e";
      log("Error fetching users: $e");
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
