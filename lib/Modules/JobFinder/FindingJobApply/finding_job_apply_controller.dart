import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class FindingJobApplyController extends GetxController {
  var cvVar = false.obs;
  var isFinding = false.obs;
  @override
  void onInit() {
    super.onInit();
    cvCheck();
  }

  Future<void> cvCheck() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection("CV").doc(uid).get();
      cvVar.value = doc.exists;
      if (doc.exists) {
        final data = doc.data() ?? {};
        isFinding.value = data["findingJob"] ?? false;
      }
    } catch (e) {
      print('CV kontrol hatası: $e');
    }
  }
}
