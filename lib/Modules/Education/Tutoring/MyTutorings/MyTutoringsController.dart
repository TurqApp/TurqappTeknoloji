import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/TutoringModel.dart';
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
    setupRealTimeListeners();
    log("MyTutoringsController initialized");
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void setupRealTimeListeners() {
    final String? currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      errorMessage.value = "Kullanıcı kimliği bulunamadı.";
      log("No current user ID found");
      return;
    }
    log("Setting up real-time listeners for user: $currentUserId");

    FirebaseFirestore.instance
        .collection('OzelDersVerenler')
        .where('userID', isEqualTo: currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        log(
          "Real-time snapshot received, docs count: ${snapshot.docs.length}",
        );
        try {
          final tutorings = snapshot.docs.map((doc) {
            return TutoringModel.fromJson(doc.data(), doc.id);
          }).toList();
          myTutorings.assignAll(tutorings);

          updateTutoringsStatus();

          final userIds = tutorings.map((t) => t.userID).toSet();
          if (userIds.isNotEmpty) {
            fetchUsers(userIds);
          } else {
            log("No user IDs to fetch");
          }
        } catch (e) {
          errorMessage.value = "İlanlar yüklenirken hata oluştu: $e";
          log("Error fetching my tutorings: $e");
        }
      },
      onError: (e) {
        errorMessage.value = "İlanlar yüklenirken hata oluştu: $e";
        log("Snapshot error: $e");
      },
    );
  }

  Future<void> fetchInitialData(String currentUserId) async {
    log("Fetching initial data for user: $currentUserId");
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('OzelDersVerenler')
          .where('userID', isEqualTo: currentUserId)
          .get();

      final tutorings = querySnapshot.docs.map((doc) {
        return TutoringModel.fromJson(doc.data(), doc.id);
      }).toList();
      myTutorings.assignAll(tutorings);

      // Aktif ve süresi dolmuş ilanları ayır
      updateTutoringsStatus();

      final userIds = tutorings.map((t) => t.userID).toSet();
      if (userIds.isNotEmpty) {
        await fetchUsers(userIds);
      } else {
        log("No user IDs to fetch in initial data");
      }
    } catch (e) {
      errorMessage.value = "İlk veri yüklenirken hata oluştu: $e";
      log("Error fetching initial data: $e");
    }
  }

  void updateTutoringsStatus() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;
    activeTutorings.clear();
    expiredTutorings.clear();

    for (var tutoring in myTutorings) {
      if (now - tutoring.timeStamp <= thirtyDaysInMillis) {
        activeTutorings.add(tutoring);
      } else {
        expiredTutorings.add(tutoring);
      }
    }
  }

  Future<void> fetchUsers(Set<String> userIds) async {
    log("Fetching users for IDs: $userIds");
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(
            FieldPath.documentId,
            whereIn: userIds.toList().take(10).toList(),
          )
          .get();

      final Map<String, Map<String, dynamic>> userMap = {
        for (var doc in querySnapshot.docs) doc.id: doc.data(),
      };
      users.assignAll(userMap);
    } catch (e) {
      errorMessage.value = "Kullanıcı bilgileri yüklenirken hata oluştu: $e";
      log("Error fetching users: $e");
    }
  }

  String? getCurrentUserId() {
    try {
      return FirebaseAuth.instance.currentUser?.uid.isNotEmpty == true
          ? FirebaseAuth.instance.currentUser!.uid
          : null;
    } catch (e) {
      print("Error getting userID: $e");
      return null;
    }
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
