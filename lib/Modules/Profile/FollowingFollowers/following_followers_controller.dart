import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

part 'following_followers_controller_cache_part.dart';
part 'following_followers_controller_fields_part.dart';
part 'following_followers_controller_models_part.dart';
part 'following_followers_controller_search_part.dart';
part 'following_followers_controller_mutation_part.dart';
part 'following_followers_controller_runtime_part.dart';

class FollowingFollowersController extends GetxController {
  final _state = _FollowingFollowersControllerState();

  @override
  void onClose() {
    _FollowingFollowersControllerRuntimePart.onClose(this);
    super.onClose();
  }

  final String userId;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();

  static FollowingFollowersController ensure({
    required String userId,
    required int initialPage,
    String? tag,
    bool permanent = false,
  }) =>
      maybeFind(tag: tag) ??
      Get.put(
        FollowingFollowersController(
          userId: userId,
          initialPage: initialPage,
        ),
        tag: tag,
        permanent: permanent,
      );

  static FollowingFollowersController? maybeFind({String? tag}) =>
      Get.isRegistered<FollowingFollowersController>(tag: tag)
          ? Get.find<FollowingFollowersController>(tag: tag)
          : null;

  FollowingFollowersController({
    required String userId,
    required int initialPage,
  }) : userId = userId.trim() {
    selection.value = initialPage;
  }

  @override
  void onInit() {
    super.onInit();
    _FollowingFollowersControllerRuntimePart.onInit(this);
  }

  static void applyFollowMutationToCaches({
    required String currentUid,
    required String otherUserID,
    required bool nowFollowing,
  }) =>
      _applyFollowMutationToCachesImpl(
        currentUid: currentUid,
        otherUserID: otherUserID,
        nowFollowing: nowFollowing,
      );
}
