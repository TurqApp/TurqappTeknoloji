import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/FollowService.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';

class FollowerController extends GetxController {
  var pfImage = "".obs;
  var nickname = "".obs;
  var fullname = "".obs;
  var isLoaded = false.obs;
  var isFollowed = false.obs;
  var followLoading = false.obs;

  Future<void> getData(String userID) async {
    if (isLoaded.value) return;

    final userDoc = await FirebaseFirestore.instance.collection("users").doc(userID).get();
    final data = userDoc.data();
    if (data != null) {
      pfImage.value = data['pfImage'] ?? '';
      nickname.value = data['nickname'] ?? '';
      fullname.value = "${data['firstName']} ${data['lastName']}";
    }

    isLoaded.value = true;
  }
  
  Future<void> followControl(String userID) async {
    FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser?.uid)
        .collection("TakipEdilenler").doc(userID).get()
        .then((doc){
          isFollowed.value = doc.exists;
    });
  }

  Future<void> follow(String otherUserID) async {
    if (followLoading.value) return;
    final wasFollowed = isFollowed.value;
    isFollowed.value = !wasFollowed; // optimistic
    followLoading.value = true;
    final outcome = await FollowService.toggleFollow(otherUserID);
    isFollowed.value = outcome.nowFollowing; // reconcile
    if (outcome.limitReached) {
      AppSnackbar('Takip Limiti', 'Günlük daha fazla kişi takip edilemiyor.');
    }
    followLoading.value = false;
  }
}
