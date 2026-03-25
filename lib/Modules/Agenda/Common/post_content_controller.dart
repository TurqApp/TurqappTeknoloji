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
part 'post_content_controller_support_part.dart';

class PostContentController extends GetxController {
  static PostContentController ensure({
    required String tag,
    required PostContentController Function() create,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(create(), tag: tag);
  }

  static PostContentController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<PostContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostContentController>(tag: tag);
  }

  static void invalidateUserProfileCache(String userId) =>
      userId.trim().isEmpty ? null : _userProfileCache.remove(userId);

  static void clearUserProfileCache() => _userProfileCache.clear();

  static void clearReshareUsersCache() => _reshareUsersCache.clear();

  PostContentController({
    required this.model,
    this.enableLegacyCommentSync = false,
    this.scrollFeedToTopOnReshare = false,
  })  : nickname = model.authorNickname.trim().obs,
        username = (model.authorNickname.trim().isNotEmpty
                ? model.authorNickname.trim()
                : '')
            .obs,
        avatarUrl = (model.authorAvatarUrl.trim().isNotEmpty
                ? resolveAvatarUrl({'avatarUrl': model.authorAvatarUrl.trim()})
                : kDefaultAvatarUrl)
            .obs,
        fullName = model.authorDisplayName.trim().obs,
        editTime = (model.editTime?.toInt() ?? 0).obs,
        currentModel = Rx<PostsModel?>(model);

  final PostsModel model;
  final bool enableLegacyCommentSync;
  final bool scrollFeedToTopOnReshare;

  bool _canSendAdminPush = AdminAccessService.isKnownAdminSync();

  final likes = <String>[].obs;
  final unLikes = <String>[].obs;
  final saved = false.obs;
  final comments = <String>[].obs;
  final reSharedUsers = <String>[].obs;
  final isFollowing = true.obs;
  final followLoading = false.obs;
  final RxString nickname;
  final RxString username;
  final RxString avatarUrl;
  final RxString fullName;
  final token = "".obs;

  final reShareUserNickname = "".obs;
  final reShareUserUserID = "".obs;

  final arsiv = false.obs;
  final gizlendi = false.obs;
  final sikayetEdildi = false.obs;
  final silindi = false.obs;
  final silindiOpacity = 1.0.obs;
  final RxInt editTime;

  final Rx<PostsModel?> currentModel;

  final yenidenPaylasildiMi = false.obs;

  late final AgendaController agendaController = _resolveAgendaController();
  PostRepositoryState? _postState;
  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<DocumentSnapshot>? _likeDocSub;
  StreamSubscription<DocumentSnapshot>? _savedDocSub;
  StreamSubscription<DocumentSnapshot>? _reshareDocSub;
  StreamSubscription<DocumentSnapshot>? _postDocSub;
  StreamSubscription<CurrentUserModel?>? _currentUserStreamSub;
  Worker? _followingWorker;
  Worker? _interactionWorker;
  Worker? _postDataWorker;
  Worker? _myResharesWorker;

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
