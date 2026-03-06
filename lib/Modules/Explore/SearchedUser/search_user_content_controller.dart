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
    if (userID.trim().isEmpty) return;
    isNavigated.value = true;
    try {
      // Sayfa kapandığında isNavigated sıfırlanır (finally)
      await Get.to(
        () => SocialProfile(userID: userID),
        preventDuplicates: false,
      );

      final currentUserID = FirebaseAuth.instance.currentUser!.uid;
      final userRef =
          FirebaseFirestore.instance.collection("users").doc(currentUserID);
      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        userRef.collection("lastSearches").doc(userID),
        {
          "userID": userID,
          "updatedDate": DateTime.now().millisecondsSinceEpoch,
        },
        SetOptions(merge: true),
      );
      await batch.commit();

      Get.find<FirebaseMyStore>().getUserData();
    } catch (_) {
    } finally {
      isNavigated.value = false;
    }
  }

  void removeFromLastSearch() {
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;
    final userRef =
        FirebaseFirestore.instance.collection("users").doc(currentUserID);
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(userRef.collection("lastSearches").doc(userID));
    batch.commit();
    Get.find<FirebaseMyStore>().lastSearchList.remove(userID);
  }
}
