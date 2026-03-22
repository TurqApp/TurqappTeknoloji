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
import '../../../Core/Services/user_summary_resolver.dart';
import '../../../Core/Utils/current_user_utils.dart';
import '../../../Core/Utils/avatar_url.dart';
import '../../../Core/Repositories/admin_push_repository.dart';

/// Shared interaction/controller layer for both Modern and Classic agenda views.

part 'post_content_controller_actions_part.dart';
part 'post_content_controller_data_part.dart';

class PostContentController extends GetxController {
  static final Map<String, _UserProfileCacheEntry> _userProfileCache = {};
  static const Duration _userProfileCacheTtl = Duration(minutes: 20);
  static final Map<String, _ReshareUsersCacheEntry> _reshareUsersCache = {};
  static const Duration _reshareUsersCacheTtl = Duration(minutes: 2);

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

  static void invalidateUserProfileCache(String userId) {
    if (userId.trim().isEmpty) return;
    _userProfileCache.remove(userId);
  }

  static void clearUserProfileCache() {
    _userProfileCache.clear();
  }

  static void clearReshareUsersCache() {
    _reshareUsersCache.clear();
  }

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

  ShortController get shortsController => ShortController.ensure();

  bool _canSendAdminPush = AdminAccessService.isKnownAdminSync();

  bool get canSendAdminPush {
    return _canSendAdminPush || AdminAccessService.isKnownAdminSync();
  }

  ({String title, String body}) _buildPostPushCopy() {
    final senderName = fullName.value.trim().isNotEmpty
        ? fullName.value.trim()
        : nickname.value.trim();
    final safeSender = senderName.isNotEmpty ? senderName : 'app.name'.tr;
    final hasVideo = model.video.trim().isNotEmpty;
    final hasImage = model.img.isNotEmpty;
    final text = model.metin.trim();

    final preview =
        text.length > 90 ? '${text.substring(0, 90).trim()}...' : text;
    final title = '$safeSender yeni bir gonderi paylasti';
    final body = preview.isNotEmpty
        ? preview
        : hasVideo
            ? 'Yeni video gonderisi'
            : hasImage
                ? 'Yeni fotograf gonderisi'
                : 'Yeni gonderi paylasti';
    return (title: title, body: body);
  }

  String? _pushPreviewImageUrl() {
    if (model.img.isNotEmpty) {
      final firstImage = model.img.first.trim();
      if (firstImage.isNotEmpty) return firstImage;
    }
    final thumbnail = model.thumbnail.trim();
    if (thumbnail.isNotEmpty) return thumbnail;
    return null;
  }

  final likes = <String>[].obs;
  final unLikes = <String>[].obs;
  final saved = false.obs;
  final comments = <String>[].obs;
  final reSharedUsers = <String>[].obs;
  final userService = CurrentUserService.instance;
  final countManager = PostCountManager.instance;
  PostInteractionService get _interactionService =>
      PostInteractionService.ensure();

  // Reactive count variables using centralized manager
  RxInt get likeCount => countManager.getLikeCount(model.docID);
  RxInt get commentCount => countManager.getCommentCount(model.docID);
  RxInt get savedCount => countManager.getSavedCount(model.docID);
  RxInt get retryCount => countManager.getRetryCount(model.docID);
  RxInt get statsCount => countManager.getStatsCount(model.docID);
  final isFollowing = true.obs;
  final followLoading = false.obs;

  // user info
  final RxString nickname;
  final RxString username;
  final RxString avatarUrl;
  final RxString fullName;
  final token = "".obs;

  final reShareUserNickname = "".obs;
  final reShareUserUserID = "".obs;

  String get _currentUid => userService.effectiveUserId;

  final arsiv = false.obs;
  final gizlendi = false.obs;
  final sikayetEdildi = false.obs;
  final silindi = false.obs;
  final silindiOpacity = 1.0.obs;
  final RxInt editTime;

  final Rx<PostsModel?> currentModel;

  final yenidenPaylasildiMi = false.obs;

  AgendaController _resolveAgendaController() {
    return AgendaController.ensure();
  }

  late final AgendaController agendaController = _resolveAgendaController();
  late final PostRepository _postRepository;
  late final AdminPushRepository _adminPushRepository;
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

  String get reshareTargetPostId {
    final originalPostId = model.originalPostID.trim();
    if (originalPostId.isNotEmpty && model.quotedPost != true) {
      return originalPostId;
    }
    return model.docID;
  }

  @protected
  void onPostInitialized() {}

  @protected
  void onPostFrameBound() {}

  @protected
  Future<void> onReshareAdded(String? uid, {String? targetPostId}) async {
    if (!scrollFeedToTopOnReshare) return;
    try {
      final controller = agendaController.scrollController;
      if (controller.hasClients) {
        await controller.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    } catch (_) {}
  }

  @protected
  Future<void> onReshareRemoved(String? uid, {String? targetPostId}) async {}

  @override
  void onInit() {
    super.onInit();
    _postRepository = PostRepository.ensure();
    _adminPushRepository = AdminPushRepository.ensure();
    unawaited(_hydrateAdminPushPermission());
    // Delay reactive counter hydration until after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      countManager.initializeCounts(
        model.docID,
        likeCount: model.stats.likeCount.toInt(),
        commentCount: model.stats.commentCount.toInt(),
        savedCount: model.stats.savedCount.toInt(),
        retryCount: model.stats.retryCount.toInt(),
        statsCount: model.stats.statsCount.toInt(),
      );
      _initializeStats();
    });

    getGizleArsivSikayetEdildi();
    getUserData(model.userID);
    getReSharedUsers(model.docID);
    // Real-time listeners handle likes/saved/comments membership and counts.
    saveSeeing();
    followCheck();
    _bindFollowingState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindMembershipListeners();
      _bindPostDocCounts();
      onPostFrameBound();
    });

    onPostInitialized();
  }

  Future<void> _hydrateAdminPushPermission() async {
    final allowed = await AdminAccessService.canAccessTask('admin_push');
    if (_canSendAdminPush == allowed) return;
    _canSendAdminPush = allowed;
    update();
  }

  @override
  void onClose() {
    _interactionWorker?.dispose();
    _postDataWorker?.dispose();
    _postRepository.releasePost(model.docID);
    _userSub?.cancel();
    _likeDocSub?.cancel();
    _savedDocSub?.cancel();
    _reshareDocSub?.cancel();
    _postDocSub?.cancel();
    _currentUserStreamSub?.cancel();
    _followingWorker?.dispose();
    _myResharesWorker?.dispose();
    super.onClose();
  }
}
