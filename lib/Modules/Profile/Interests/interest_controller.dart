import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class InterestsController extends GetxController {
  RxList selecteds = [].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      selecteds.value = List.from(doc.get("ilgialanlari"));
    });
  }

  Future<void> select(String selection) async {
    if (selecteds.contains(selection)) {
      selecteds.remove(selection);
    } else {
      selecteds.add(selection);
    }
  }

  Future<void> setData() async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({"ilgialanlari": selecteds});

    Get.back();
  }
}
