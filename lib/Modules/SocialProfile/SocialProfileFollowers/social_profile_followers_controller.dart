import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';

part 'social_profile_followers_controller_runtime_part.dart';
part 'social_profile_followers_controller_models_part.dart';

class SocialProfileFollowersController extends GetxController {
  String userID;
  var selection = 0.obs;
  late PageController pageController;

  RxList<String> takipciler = <String>[].obs;
  RxList<String> takipEdilenler = <String>[].obs;

  final int limit = 50;
  bool isLoadingFollowers = false;
  bool isLoadingFollowing = false;
  bool hasMoreFollowers = true;
  bool hasMoreFollowing = true;
  static const Duration _relationCacheTtl = Duration(seconds: 30);
  static const Duration _relationCacheStaleRetention = Duration(minutes: 3);
  static const int _maxRelationCacheEntries = 400;
  static final Map<String, _RelationListCacheEntry> _relationCache =
      <String, _RelationListCacheEntry>{};
  final FollowRepository _followRepository = FollowRepository.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();

  static SocialProfileFollowersController ensure({
    required int initialPage,
    required String userID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SocialProfileFollowersController(
        initialPage: initialPage,
        userID: userID,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static SocialProfileFollowersController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<SocialProfileFollowersController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SocialProfileFollowersController>(tag: tag);
  }

  SocialProfileFollowersController(
      {required int initialPage, required this.userID}) {
    selection.value = initialPage;
    pageController = PageController(initialPage: initialPage);
  }

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
