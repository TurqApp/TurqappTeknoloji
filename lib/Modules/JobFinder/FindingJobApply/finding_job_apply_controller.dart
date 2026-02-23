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
    FirebaseFirestore.instance
        .collection("CV")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      cvVar.value = doc.exists;
      isFinding.value = doc.get("findingJob");
    });
  }
}
