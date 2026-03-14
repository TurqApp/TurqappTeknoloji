import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class RecommendedUserContentController extends GetxController {
  String userID;
  var isFollowing = false.obs;
  var followLoading = false.obs;
  final FollowRepository _followRepository = FollowRepository.ensure();

  RecommendedUserContentController({required this.userID});
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    // Başlangıçta anlık durumu merkezi follow cache hattından al
    getTakipStatus();
  }

  Future<void> getTakipStatus() async {
    isFollowing.value = await _followRepository.isFollowing(
      userID,
      currentUid: FirebaseAuth.instance.currentUser!.uid,
      preferCache: true,
    );
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
    } finally {
      followLoading.value = false;
    }
  }
}
