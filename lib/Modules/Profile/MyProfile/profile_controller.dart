import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/profile_posts_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Repositories/social_media_links_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/feed_playback_selection_policy.dart';
import 'package:turqappv2/Core/Services/profile_render_coordinator.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_links_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../Models/posts_model.dart';
import '../../../Models/user_post_reference.dart';
import '../../../Services/user_post_link_service.dart';
import '../../Agenda/AgendaContent/agenda_content_controller.dart';

part 'profile_controller_header_part.dart';
part 'profile_controller_primary_part.dart';
part 'profile_controller_cache_part.dart';
part 'profile_controller_lifecycle_part.dart';
part 'profile_controller_selection_part.dart';
part 'profile_controller_runtime_part.dart';
part 'profile_controller_support_part.dart';
part 'profile_controller_fields_part.dart';

class ProfileController extends GetxController {
  static ProfileController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileController());
  }

  static ProfileController? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileController>();
    if (!isRegistered) return null;
    return Get.find<ProfileController>();
  }

  final _lifecycleState = _ProfileLifecycleState();
  final _scrollState = _ProfileScrollState();
  final _headerState = _ProfileHeaderState();
  final _feedState = _ProfileFeedState();

  @override
  void onInit() {
    super.onInit();
    _performOnInit();
  }

  @override
  void onClose() {
    _performOnClose();
    super.onClose();
  }
}
