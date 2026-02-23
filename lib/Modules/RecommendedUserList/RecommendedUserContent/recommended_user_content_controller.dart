import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class RecommendedUserContentController extends GetxController {
  String userID;
  var isFollowing = false.obs;
  var followLoading = false.obs;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _followSub;

  RecommendedUserContentController({required this.userID});
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    // Başlangıçta anlık durumu al ve ardından canlı dinlemeyi başlat
    getTakipStatus();
    listenTakipStatus();
  }

  @override
  void onClose() {
    _followSub?.cancel();
    super.onClose();
  }

  Future<void> getTakipStatus() async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("TakipEdilenler")
        .doc(userID)
        .get()
        .then((DocumentSnapshot doc) {
      isFollowing.value = doc.exists;
    });
  }

  void listenTakipStatus() {
    _followSub?.cancel();
    _followSub = FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("TakipEdilenler")
        .doc(userID)
        .snapshots()
        .listen((doc) {
      isFollowing.value = doc.exists;
    });
  }

  Future<void> follow() async {
    if (followLoading.value) return;
    final wasFollowing = isFollowing.value;
    isFollowing.value = !wasFollowing; // optimistic
    followLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      isFollowing.value = outcome.nowFollowing; // reconcile
      if (outcome.limitReached) {
        AppSnackbar('Takip Limiti', 'Günlük daha fazla kişi takip edilemiyor.');
      }
    } catch (e) {
      isFollowing.value = wasFollowing; // revert
      print("Bir hata oluştu: $e");
    } finally {
      followLoading.value = false;
    }
  }
}
