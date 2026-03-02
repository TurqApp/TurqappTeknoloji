import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';

class MyTutoringApplicationsController extends GetxController {
  RxList<TutoringApplicationModel> applications =
      <TutoringApplicationModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadApplications();
  }

  Future<void> loadApplications() async {
    isLoading.value = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('myTutoringApplications')
          .orderBy('timeStamp', descending: true)
          .get();

      applications.value = snapshot.docs
          .map((doc) =>
              TutoringApplicationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Özel ders başvuruları yüklenirken hata: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelApplication(String tutoringDocID) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final batch = FirebaseFirestore.instance.batch();

      batch.delete(FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('myTutoringApplications')
          .doc(tutoringDocID));

      batch.delete(FirebaseFirestore.instance
          .collection('educators')
          .doc(tutoringDocID)
          .collection('Applications')
          .doc(uid));

      batch.update(
          FirebaseFirestore.instance
              .collection('educators')
              .doc(tutoringDocID),
          {'applicationCount': FieldValue.increment(-1)});

      await batch.commit();

      // Prevent negative count
      final docSnap = await FirebaseFirestore.instance
          .collection('educators')
          .doc(tutoringDocID)
          .get();
      if (docSnap.exists) {
        final count =
            (docSnap.data()?['applicationCount'] ?? 0) as num;
        if (count < 0) {
          await FirebaseFirestore.instance
              .collection('educators')
              .doc(tutoringDocID)
              .update({'applicationCount': 0});
        }
      }

      applications.removeWhere((a) => a.tutoringDocID == tutoringDocID);
    } catch (e) {
      print("Özel ders başvuru iptal hatası: $e");
    }
  }
}
