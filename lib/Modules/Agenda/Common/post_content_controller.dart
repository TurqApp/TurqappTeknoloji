import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/Profile/Archives/archives_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Modules/ShareGrid/share_grid.dart';
import 'package:turqappv2/Services/reshare_helper.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Models/current_user_model.dart';
import '../../../Models/posts_model.dart';
import '../../Short/short_controller.dart';
import '../../Social/Comments/post_comments.dart';
import 'dart:async';
import '../../../Services/post_count_manager.dart';
import '../../../Services/post_delete_service.dart';
import '../../../Services/post_interaction_service.dart';
import '../../../Core/Services/admin_access_service.dart';
import '../../../Core/Repositories/post_repository.dart';
import '../../../Core/Services/read_budget_registry.dart';
import '../../../Core/Services/user_summary_resolver.dart';
import '../../../Core/Utils/current_user_utils.dart';
import '../../../Core/Utils/avatar_url.dart';
import '../../../Core/Repositories/admin_push_repository.dart';

/// Shared interaction/controller layer for both Modern and Classic agenda views.

part 'post_content_controller_actions_part.dart';
part 'post_content_controller_data_part.dart';
part 'post_content_controller_profile_part.dart';
part 'post_content_controller_runtime_part.dart';
part 'post_content_controller_shell_part.dart';
part 'post_content_controller_support_part.dart';
part 'post_content_controller_fields_part.dart';

class PostContentController extends GetxController {
  static PostContentController ensure({
    required String tag,
    required PostContentController Function() create,
  }) =>
      maybeFind(tag: tag) ?? Get.put(create(), tag: tag);

  static PostContentController? maybeFind({required String tag}) =>
      Get.isRegistered<PostContentController>(tag: tag)
          ? Get.find<PostContentController>(tag: tag)
          : null;

  static void invalidateUserProfileCache(String userId) =>
      _invalidatePostContentUserProfileCache(userId);
  static void clearUserProfileCache() => _clearPostContentUserProfileCache();
  static void clearReshareUsersCache() => _clearPostContentReshareUsersCache();

  PostContentController({
    required PostsModel model,
    bool enableLegacyCommentSync = false,
    bool scrollFeedToTopOnReshare = false,
  }) : _shellState = _PostContentShellState(
          model: model,
          enableLegacyCommentSync: enableLegacyCommentSync,
          scrollFeedToTopOnReshare: scrollFeedToTopOnReshare,
        );

  final _PostContentShellState _shellState;

  @protected
  void onPostInitialized() {}

  @protected
  void onPostFrameBound() {}

  @protected
  Future<void> onReshareAdded(String? uid, {String? targetPostId}) async =>
      _performOnReshareAdded(uid, targetPostId: targetPostId);

  @protected
  Future<void> onReshareRemoved(String? uid, {String? targetPostId}) async {}

  @override
  void onInit() {
    super.onInit();
    _handlePostContentInit();
  }

  @override
  void onClose() {
    _handlePostContentClose();
    super.onClose();
  }
}
