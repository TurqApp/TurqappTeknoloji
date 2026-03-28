import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';

part 'social_profile_followers_controller_fields_part.dart';
part 'social_profile_followers_controller_runtime_part.dart';
part 'social_profile_followers_controller_models_part.dart';
part 'social_profile_followers_controller_support_part.dart';

abstract class _SocialProfileFollowersControllerBase extends GetxController {
  _SocialProfileFollowersControllerBase({
    required int initialPage,
    required String userID,
  }) {
    _configureSocialProfileFollowersController(
      this as SocialProfileFollowersController,
      initialPage: initialPage,
      userID: userID,
    );
  }

  final _state = _SocialProfileFollowersControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleSocialProfileFollowersControllerOnInit(
      this as SocialProfileFollowersController,
    );
  }

  @override
  void onClose() {
    _handleSocialProfileFollowersControllerOnClose(
      this as SocialProfileFollowersController,
    );
    super.onClose();
  }
}

class SocialProfileFollowersController
    extends _SocialProfileFollowersControllerBase {
  SocialProfileFollowersController({
    required super.initialPage,
    required super.userID,
  });
}
