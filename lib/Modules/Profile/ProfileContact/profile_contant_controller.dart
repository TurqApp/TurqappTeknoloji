import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';

class ProfileContactController extends GetxController {
  var isEmailVisible = true.obs;
  var isCallVisible = true.obs;
  final user = Get.find<FirebaseMyStore>();

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      isEmailVisible.value = doc.get("mailIzin");
      isCallVisible.value = doc.get("aramaIzin");
    });
  }

  void toggleEmailVisibility() {
    isEmailVisible.value = !isEmailVisible.value;
    FirebaseFirestore.instance
        .collection("users")
        .doc(user.userID.value)
        .update({"mailIzin": isEmailVisible.value});
  }

  void toggleCallVisibility() {
    isCallVisible.value = !isCallVisible.value;
    FirebaseFirestore.instance
        .collection("users")
        .doc(user.userID.value)
        .update({"aramaIzin": isCallVisible.value});
  }
}
