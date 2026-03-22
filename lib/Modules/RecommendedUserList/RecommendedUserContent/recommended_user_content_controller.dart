import 'dart:async';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class RecommendedUserContentController extends GetxController {
  static RecommendedUserContentController ensure({
    required String userID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      RecommendedUserContentController(userID: userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static RecommendedUserContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<RecommendedUserContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<RecommendedUserContentController>(tag: tag);
  }

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
      currentUid: CurrentUserService.instance.effectiveUserId,
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
        AppSnackbar('following.limit_title'.tr, 'following.limit_body'.tr);
      }
    } catch (e) {
      isFollowing.value = wasFollowing; // revert
    } finally {
      followLoading.value = false;
    }
  }
}
