import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';

class SavedTutoringsController extends GetxController {
  var savedTutoringIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedTutorings();
  }

  Future<void> loadSavedTutorings() async {
    final String? userId = getCurrentUserId();
    if (userId != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('OzelDersVerenler')
                .where('favorites', arrayContains: userId)
                .get();
        final ids = doc.docs.map((doc) => doc.id).toList();
        savedTutoringIds.value = ids;
      } catch (e) {
        print("Error loading saved tutorings: $e");
      }
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
