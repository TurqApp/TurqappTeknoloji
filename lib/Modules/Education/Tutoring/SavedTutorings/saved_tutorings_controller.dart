import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SavedTutoringsController extends GetxController {
  var savedTutoringIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedTutorings();
  }

  Future<void> loadSavedTutorings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('educators')
          .where('favorites', arrayContains: uid)
          .get();
      savedTutoringIds.value = snap.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print("Error loading saved tutorings: $e");
    }
  }

  void addSavedTutoring(String docId) {
    if (!savedTutoringIds.contains(docId)) {
      savedTutoringIds.add(docId);
    }
  }

  void removeSavedTutoring(String docId) {
    if (savedTutoringIds.contains(docId)) {
      savedTutoringIds.remove(docId);
    }
  }
}
