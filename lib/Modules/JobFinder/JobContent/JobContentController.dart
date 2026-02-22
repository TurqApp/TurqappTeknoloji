import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class JobContentController extends GetxController {
  var saved = false.obs;

  Future<void> checkSaved(String docId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final ref = FirebaseFirestore.instance
        .collection("IsBul")
        .doc(docId)
        .collection("Saved")
        .doc(uid);

    try {
      final doc = await ref.get();
      saved.value = doc.exists;
    } catch (e) {
      print("checkSaved hatası: $e");
      saved.value = false;
    }
  }

  Future<void> toggleSave(String docId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final ref = FirebaseFirestore.instance
        .collection("IsBul")
        .doc(docId)
        .collection("Saved")
        .doc(uid);

    try {
      final doc = await ref.get();

      if (doc.exists) {
        await ref.delete();
        saved.value = false;
        print("Kaydedilen ilan kaldırıldı");
        FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).collection("SavedIsBul").doc(docId).delete();
      } else {
        FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).collection("SavedIsBul").doc(docId).set(
            {
              "timeStamp" : DateTime.now()
            });
        await ref.set({
          "timeStamp": FieldValue.serverTimestamp(),
        });
        saved.value = true;
        print("İlan kaydedildi");
      }
    } catch (e) {
      print("toggleSave hatası: $e");
    }
  }

}