import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (!Get.isRegistered<PostContentController>(tag: tag)) return null;
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

  String get _currentUid {
    final serviceUid = userService.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

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

  void _bindFollowingState() {
    if (isCurrentUserId(model.userID)) {
      isFollowing.value = true;
      return;
    }

    void syncFromAgenda() {
      isFollowing.value = agendaController.followingIDs.contains(model.userID);
    }

    syncFromAgenda();
    _followingWorker?.dispose();
    _followingWorker = ever<Set<String>>(agendaController.followingIDs, (_) {
      syncFromAgenda();
    });
  }

  void _bindMembershipListeners() {
    _postState = _postRepository.attachPost(model);
    _syncSharedInteractionState();
    _interactionWorker?.dispose();
    _myResharesWorker?.dispose();
    if (_postState != null) {
      _interactionWorker = everAll([
        _postState!.liked,
        _postState!.saved,
        _postState!.reshared,
        _postState!.commented,
      ], (_) {
        _syncSharedInteractionState();
      });
    }
    _myResharesWorker =
        ever<Map<String, int>>(agendaController.myReshares, (_) {
      _syncSharedInteractionState();
    });
  }

  void _bindPostDocCounts() {
    _postDataWorker?.dispose();
    if (_postState == null) return;
    _postDataWorker =
        ever<Map<String, dynamic>?>(_postState!.latestPostData, (data) {
      if (data == null) return;
      final rawEditTime = data['editTime'];
      if (rawEditTime is num) {
        editTime.value = rawEditTime.toInt();
      } else if (rawEditTime is String) {
        editTime.value = int.tryParse(rawEditTime) ?? editTime.value;
      }

      final latestAuthorNickname = (data['authorNickname'] ??
              (data['author'] is Map
                  ? (data['author'] as Map)['nickname']
                  : null) ??
              '')
          .toString()
          .trim();
      final nicknameNeedsFallback = nickname.value.trim().isEmpty;
      if (latestAuthorNickname.isNotEmpty &&
          nicknameNeedsFallback &&
          latestAuthorNickname != nickname.value) {
        nickname.value = latestAuthorNickname;
        if (username.value.trim().isEmpty) {
          username.value = latestAuthorNickname;
        }
      }
      final latestAuthorAvatar = (data['authorAvatarUrl'] ??
              (data['author'] is Map
                  ? (data['author'] as Map)['avatarUrl']
                  : null) ??
              '')
          .toString()
          .trim();
      if (latestAuthorAvatar.isNotEmpty) {
        final resolved = resolveAvatarUrl({'avatarUrl': latestAuthorAvatar});
        if (resolved != avatarUrl.value) {
          avatarUrl.value = resolved;
        }
      }

      if (data['poll'] != null) {
        try {
          model.poll = Map<String, dynamic>.from(data['poll']);
          currentModel.value = model;
        } catch (_) {}
      }

      final rawStats = data['stats'];
      dynamic rawRetryCount;
      if (rawStats is Map) {
        rawRetryCount = rawStats['retryCount'];
      }
      rawRetryCount ??= data['retryCount'];
      if (rawRetryCount != null) {
        final parsedRetryCount = rawRetryCount is num
            ? rawRetryCount.toInt()
            : int.tryParse('$rawRetryCount');
        if (parsedRetryCount != null) {
          model.stats.retryCount = parsedRetryCount;
          final retryRx = countManager.getRetryCount(model.docID);
          if (retryRx.value != parsedRetryCount) {
            retryRx.value = parsedRetryCount;
          }
        }
      }
    });
  }

  void _syncSharedInteractionState() {
    final uid = _currentUid;
    if (_postState == null) return;
    final liked = _postState!.liked.value;
    if (uid.isNotEmpty) {
      if (liked) {
        if (!likes.contains(uid)) likes.add(uid);
      } else {
        likes.remove(uid);
      }
    }
    saved.value = _postState!.saved.value;
    yenidenPaylasildiMi.value = _postState!.reshared.value ||
        agendaController.myReshares.containsKey(reshareTargetPostId);
    if (uid.isNotEmpty) {
      if (_postState!.commented.value) {
        if (!comments.contains(uid)) comments.add(uid);
      } else {
        comments.remove(uid);
      }
    }
  }

  Future<void> votePoll(int optionIndex) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final postRef =
        FirebaseFirestore.instance.collection('Posts').doc(model.docID);

    final originalPoll = Map<String, dynamic>.from(model.poll);
    try {
      final localPoll = Map<String, dynamic>.from(model.poll);
      if (localPoll.isEmpty) return;
      final createdAt = (localPoll['createdDate'] ?? model.timeStamp) as num;
      final durationHours = (localPoll['durationHours'] ?? 24) as num;
      final expiresAt =
          createdAt.toInt() + (durationHours.toInt() * 3600 * 1000);
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) return;

      final options = (localPoll['options'] is List)
          ? List<Map<String, dynamic>>.from(
              (localPoll['options'] as List)
                  .map((o) => Map<String, dynamic>.from(o)),
            )
          : <Map<String, dynamic>>[];
      if (optionIndex < 0 || optionIndex >= options.length) return;

      final userVotes = localPoll['userVotes'] is Map
          ? Map<String, dynamic>.from(localPoll['userVotes'])
          : <String, dynamic>{};
      if (userVotes.containsKey(uid)) return;

      final opt = Map<String, dynamic>.from(options[optionIndex]);
      final currentVotes = (opt['votes'] ?? 0) as num;
      opt['votes'] = currentVotes.toInt() + 1;
      options[optionIndex] = opt;

      final totalVotes = (localPoll['totalVotes'] ?? 0) as num;
      localPoll['totalVotes'] = totalVotes.toInt() + 1;
      userVotes[uid] = optionIndex;
      localPoll['options'] = options;
      localPoll['userVotes'] = userVotes;

      // Optimistic UI update
      model.poll = localPoll;
      currentModel.value = model;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(postRef);
        final data = snap.data();
        if (data == null) return;
        final poll = Map<String, dynamic>.from(data['poll'] ?? {});
        if (poll.isEmpty) return;

        final createdAt =
            (poll['createdDate'] ?? data['timeStamp'] ?? 0) as num;
        final durationHours = (poll['durationHours'] ?? 24) as num;
        final expiresAt =
            createdAt.toInt() + (durationHours.toInt() * 3600 * 1000);
        if (DateTime.now().millisecondsSinceEpoch > expiresAt) return;

        final options = (poll['options'] is List)
            ? List<Map<String, dynamic>>.from(
                (poll['options'] as List)
                    .map((o) => Map<String, dynamic>.from(o)),
              )
            : <Map<String, dynamic>>[];
        if (optionIndex < 0 || optionIndex >= options.length) return;

        final userVotes = poll['userVotes'] is Map
            ? Map<String, dynamic>.from(poll['userVotes'])
            : <String, dynamic>{};
        if (userVotes.containsKey(uid)) return;

        final opt = Map<String, dynamic>.from(options[optionIndex]);
        final currentVotes = (opt['votes'] ?? 0) as num;
        opt['votes'] = currentVotes.toInt() + 1;
        options[optionIndex] = opt;

        final totalVotes = (poll['totalVotes'] ?? 0) as num;
        poll['totalVotes'] = totalVotes.toInt() + 1;
        userVotes[uid] = optionIndex;
        poll['options'] = options;
        poll['userVotes'] = userVotes;

        tx.update(postRef, {'poll': poll});
      });
    } catch (_) {
      model.poll = originalPoll;
      currentModel.value = model;
    }
  }

  void _initializeStats() {
    likeCount.value = model.stats.likeCount.toInt();
    commentCount.value = model.stats.commentCount.toInt();
    savedCount.value = model.stats.savedCount.toInt();
    retryCount.value = model.stats.retryCount.toInt();
    statsCount.value = model.stats.statsCount.toInt();
  }
}
