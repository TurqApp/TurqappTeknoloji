import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';

class ViewChangerController extends GetxController {
  var selection = 0.obs;

  ViewChangerController({required RxInt selection}) {
    this.selection.value = selection.value;
  }

  void updateViewMode(int value) {
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      "viewSelection": value,
    }, SetOptions(merge: true));

    Get.find<FirebaseMyStore>().getUserData();
  }
}
