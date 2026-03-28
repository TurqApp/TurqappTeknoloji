import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Services/feed_playback_selection_policy.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Repositories/social_media_links_repository.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/social_media_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Models/posts_model.dart';
import '../../Models/user_post_reference.dart';
import '../../Services/user_post_link_service.dart';
import '../../Services/user_analytics_service.dart';
import 'package:turqappv2/Core/notification_service.dart';
import '../Agenda/AgendaContent/agenda_content_controller.dart';
import '../Profile/SocialMediaLinks/social_media_links_controller.dart';
import '../Story/StoryRow/story_user_model.dart';

part 'social_profile_controller_profile_part.dart';
part 'social_profile_controller_actions_part.dart';
part 'social_profile_controller_feed_part.dart';
part 'social_profile_controller_feed_selection_part.dart';
part 'social_profile_controller_runtime_part.dart';
part 'social_profile_controller_models_part.dart';
part 'social_profile_controller_shell_part.dart';
part 'social_profile_controller_shell_content_part.dart';
part 'social_profile_controller_support_part.dart';
part 'social_profile_controller_fields_part.dart';

abstract class _SocialProfileControllerBase extends GetxController {
  _SocialProfileControllerBase({required String userID})
      : _shellState = _SocialProfileShellState(userID: userID);

  final _SocialProfileShellState _shellState;

  @override
  void onInit() {
    super.onInit();
    (this as SocialProfileController)._handleLifecycleInit();
  }

  @override
  void onClose() {
    (this as SocialProfileController)._handleLifecycleClose();
    super.onClose();
  }
}

class SocialProfileController extends _SocialProfileControllerBase {
  SocialProfileController({required super.userID});
}

SocialProfileController ensureSocialProfileController({
  required String userID,
  String? tag,
  bool permanent = false,
}) =>
    maybeFindSocialProfileController(tag: tag) ??
    _ensureSocialProfileController(
        userID: userID, tag: tag, permanent: permanent);

SocialProfileController? maybeFindSocialProfileController({String? tag}) =>
    _maybeFindSocialProfileController(tag: tag);
