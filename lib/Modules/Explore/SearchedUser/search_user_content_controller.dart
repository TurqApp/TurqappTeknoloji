import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';

class SearchUserContentController extends GetxController {
  final String userID;
  var isNavigated = false.obs;
  SearchUserContentController({required this.userID});
  Future<void> goToProfile() async {
    if (isNavigated.value) return; // tekrar giriş engeli
    isNavigated.value = true;

    // Sayfa kapandığında isNavigated'ı sıfırla
    await Get.to(() => SocialProfile(userID: userID));

    isNavigated.value = false;

    try {
      final currentUserID = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserID)
          .update({
        "lastSearchList": FieldValue.arrayUnion([userID])
      });

      Get.find<FirebaseMyStore>().getUserData();
    } catch (e) {
      // Hata durumunda da sıfırla
      isNavigated.value = false;
    }
  }
  void removeFromLastSearch() {
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserID)
        .update({
      "lastSearchList": FieldValue.arrayRemove([userID])
    });
    Get.find<FirebaseMyStore>().lastSearchList.remove(userID);
  }
}
