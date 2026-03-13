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
import '../../../Core/Repositories/user_repository.dart';
import '../../../Core/Utils/avatar_url.dart';
import '../../../Core/Repositories/admin_push_repository.dart';

/// Shared interaction/controller layer for both Modern and Classic agenda views.
class PostContentController extends GetxController {
  static final Map<String, _UserProfileCacheEntry> _userProfileCache = {};
  static const Duration _userProfileCacheTtl = Duration(minutes: 20);
  static final Map<String, _ReshareUsersCacheEntry> _reshareUsersCache = {};
  static const Duration _reshareUsersCacheTtl = Duration(minutes: 2);

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
  });

  final PostsModel model;
  final bool enableLegacyCommentSync;
  final bool scrollFeedToTopOnReshare;

  ShortController get shortsController => Get.isRegistered<ShortController>()
      ? Get.find<ShortController>()
      : Get.put(ShortController());

  bool get canSendAdminPush {
    return AdminAccessService.isKnownAdminSync();
  }

  ({String title, String body}) _buildPostPushCopy() {
    final senderName = fullName.value.trim().isNotEmpty
        ? fullName.value.trim()
        : nickname.value.trim();
    final safeSender = senderName.isNotEmpty ? senderName : 'TurqApp';
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
  late final PostInteractionService _interactionService;

  // Reactive count variables using centralized manager
  RxInt get likeCount => countManager.getLikeCount(model.docID);
  RxInt get commentCount => countManager.getCommentCount(model.docID);
  RxInt get savedCount => countManager.getSavedCount(model.docID);
  RxInt get retryCount => countManager.getRetryCount(model.docID);
  RxInt get statsCount => countManager.getStatsCount(model.docID);
  final isFollowing = true.obs;
  final followLoading = false.obs;

  // user info
  final nickname = "".obs;
  final username = "".obs;
  final avatarUrl = "".obs;
  final fullName = "".obs;
  final token = "".obs;

  final reShareUserNickname = "".obs;
  final reShareUserUserID = "".obs;

  final arsiv = false.obs;
  final gizlendi = false.obs;
  final sikayetEdildi = false.obs;
  final silindi = false.obs;
  final silindiOpacity = 1.0.obs;
  final editTime = 0.obs;

  final Rx<PostsModel?> currentModel = Rx<PostsModel?>(null);

  final yenidenPaylasildiMi = false.obs;

  final AgendaController agendaController = Get.find<AgendaController>();
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

  @override
  void onInit() {
    super.onInit();
    _interactionService = Get.put(PostInteractionService());
    _postRepository = PostRepository.ensure();
    _adminPushRepository = AdminPushRepository.ensure();
    currentModel.value = model;
    final denormAvatar = model.authorAvatarUrl.trim();
    avatarUrl.value = denormAvatar.isNotEmpty
        ? resolveAvatarUrl({'avatarUrl': denormAvatar})
        : kDefaultAvatarUrl;
    final denormNick = model.authorNickname.trim();
    if (denormNick.isNotEmpty) {
      nickname.value = denormNick;
      if (username.value.trim().isEmpty) {
        username.value = denormNick;
      }
    }
    // Initialize counts after current build to avoid Obx update during build
    Future.microtask(() {
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
    editTime.value = model.editTime?.toInt() ?? 0;
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
    super.onClose();
  }

  void _bindFollowingState() {
    if (model.userID == FirebaseAuth.instance.currentUser?.uid) {
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
    });
  }

  void _syncSharedInteractionState() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_postState == null) return;
    final liked = _postState!.liked.value;
    if (uid != null) {
      if (liked) {
        if (!likes.contains(uid)) likes.add(uid);
      } else {
        likes.remove(uid);
      }
    }
    saved.value = _postState!.saved.value;
    yenidenPaylasildiMi.value = _postState!.reshared.value;
    if (uid != null) {
      if (_postState!.commented.value) {
        if (!comments.contains(uid)) comments.add(uid);
      } else {
        comments.remove(uid);
      }
    }
  }

  Future<void> votePoll(int optionIndex) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
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

  Future<void> getGizleArsivSikayetEdildi() async {
    gizlendi.value = model.gizlendi;
    arsiv.value = model.arsiv;
    silindi.value = model.deletedPost;
  }

  Future<void> gizle() async {
    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].gizlendi = true;

    final exploreController = Get.find<ExploreController>();

    final index3 = exploreController.explorePosts.indexOf(model);
    if (index3 >= 0) exploreController.explorePosts[index3].gizlendi = true;

    final index4 = exploreController.explorePhotos.indexOf(model);
    if (index4 >= 0) exploreController.explorePhotos[index4].gizlendi = true;

    final index5 = exploreController.exploreVideos.indexOf(model);
    if (index5 >= 0) exploreController.exploreVideos[index5].gizlendi = true;

    final store8 = Get.find<AgendaController>();
    final index8 = store8.agendaList.indexOf(model);
    if (index8 >= 0) store8.agendaList[index8].gizlendi = true;

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].gizlendi = true;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.allPosts.indexOf(model);
    if (index10 >= 0) store10.allPosts[index10].gizlendi = true;

    gizlendi.value = true;
  }

  Future<void> gizlemeyiGeriAl() async {
    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].gizlendi = false;

    final exploreController = Get.find<ExploreController>();

    final index3 = exploreController.explorePosts.indexOf(model);
    if (index3 >= 0) exploreController.explorePosts[index3].gizlendi = false;

    final index4 = exploreController.explorePhotos.indexOf(model);
    if (index4 >= 0) exploreController.explorePhotos[index4].gizlendi = false;

    final index5 = exploreController.exploreVideos.indexOf(model);
    if (index5 >= 0) exploreController.exploreVideos[index5].gizlendi = false;

    final store8 = Get.find<AgendaController>();
    final index8 = store8.agendaList.indexOf(model);
    if (index8 >= 0) store8.agendaList[index8].gizlendi = false;

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].gizlendi = false;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.allPosts.indexOf(model);
    if (index10 >= 0) store10.allPosts[index10].gizlendi = false;

    gizlendi.value = false;
  }

  Future<void> arsivle() async {
    // Firestore güncelle
    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .update({
      "arsiv": true,
    });

    // Sayaç: görünür bir kök post ise ve sahibi isek counterOfPosts -=1
    try {
      final me = FirebaseAuth.instance.currentUser?.uid;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final isVisible = (model.timeStamp <= nowMs) && !model.flood;
      if (me != null && model.userID == me && isVisible) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(me)
            .update({'counterOfPosts': FieldValue.increment(-1)});
      }
    } catch (_) {}

    // Tüm ilgili store ve listeleri güncelle
    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].arsiv = true;
    final exploreController = Get.find<ExploreController>();

    final index3 = exploreController.explorePosts.indexOf(model);
    if (index3 >= 0) exploreController.explorePosts[index3].arsiv = true;

    final index4 = exploreController.explorePhotos.indexOf(model);
    if (index4 >= 0) exploreController.explorePhotos[index4].arsiv = true;

    final index5 = exploreController.exploreVideos.indexOf(model);
    if (index5 >= 0) exploreController.exploreVideos[index5].arsiv = true;

    final store8 = Get.find<AgendaController>();
    final index8 = store8.agendaList.indexOf(model);
    if (index8 >= 0) store8.agendaList[index8].arsiv = true;

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = false;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.allPosts.indexOf(model);
    if (index10 >= 0) store10.allPosts[index10].arsiv = false;

    arsiv.value = true;
  }

  Future<void> arsivdenCikart() async {
    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .update({
      "arsiv": false,
    });

    // Sayaç: görünür bir kök post ise ve sahibi isek counterOfPosts +=1
    try {
      final me = FirebaseAuth.instance.currentUser?.uid;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final isVisible = (model.timeStamp <= nowMs) && !model.flood;
      if (me != null && model.userID == me && isVisible) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(me)
            .update({'counterOfPosts': FieldValue.increment(1)});
      }
    } catch (_) {}

    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].arsiv = false;

    final exploreController = Get.find<ExploreController>();
    final index3 = exploreController.explorePosts.indexOf(model);
    if (index3 >= 0) exploreController.explorePosts[index3].arsiv = false;

    final index4 = exploreController.explorePhotos.indexOf(model);
    if (index4 >= 0) exploreController.explorePhotos[index4].arsiv = false;

    final index5 = exploreController.exploreVideos.indexOf(model);
    if (index5 >= 0) exploreController.exploreVideos[index5].arsiv = false;

    final store8 = Get.find<AgendaController>();
    final index8 = store8.agendaList.indexOf(model);
    if (index8 >= 0) store8.agendaList[index8].arsiv = false;

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = false;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.allPosts.indexOf(model);
    if (index10 >= 0) store10.allPosts[index10].arsiv = false;

    if (Get.isRegistered<ArchiveController>()) {
      final store11 = Get.find<ArchiveController>();
      final index11 = store11.list.indexOf(model);
      if (index11 >= 0) store11.list.removeAt(index11);
    }

    arsiv.value = false;
  }

  Future<void> sil() async {
    await PostDeleteService.instance.softDelete(model);
    silindi.value = true; // UI overlay

    // Yumuşak fade-out
    Future.delayed(const Duration(milliseconds: 2600), () {
      silindiOpacity.value = 0.0;
    });

    // 3 sn sonra overlay'i kaldır ve ana listeden çıkar
    Future.delayed(const Duration(seconds: 3), () {
      if (Get.isRegistered<AgendaController>()) {
        final agenda = Get.find<AgendaController>();
        final idx = agenda.agendaList.indexWhere((e) => e.docID == model.docID);
        if (idx != -1) {
          agenda.agendaList.removeAt(idx);
          agenda.agendaList.refresh();
        }
      }
    });
  }

  Future<void> reshare() async {
    final bool wasReshared = yenidenPaylasildiMi.value;

    try {
      final status = await _postRepository.toggleReshare(model);

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (status) {
        if (uid != null && !reSharedUsers.contains(uid)) {
          reSharedUsers.add(uid);
          reShareUserUserID.value = uid;
          reShareUserNickname.value = 'Sen';
        }
        try {
          Get.find<ProfileController>().getResharesSingle();
        } catch (_) {}
        await onReshareAdded(uid);
      } else {
        if (uid != null) {
          reSharedUsers.remove(uid);
        }
        reShareUserUserID.value = '';
        reShareUserNickname.value = '';
        try {
          Get.find<ProfileController>().removeReshare(model.docID);
        } catch (_) {}
        await onReshareRemoved(uid);
      }
    } catch (e) {
      yenidenPaylasildiMi.value = wasReshared;
      AppSnackbar('Hata', 'Yeniden paylaşma işlemi başarısız: $e');
    }
  }

  Future<void> followCheck() async {
    if (model.userID != FirebaseAuth.instance.currentUser!.uid) {
      if (agendaController.followingIDs.contains(model.userID)) {
        isFollowing.value = true;
        return;
      }
      final docExists = await FollowRepository.ensure().isFollowing(
        model.userID,
        currentUid: FirebaseAuth.instance.currentUser!.uid,
        preferCache: true,
      );
      isFollowing.value = docExists;
      if (docExists) {
        agendaController.followingIDs.add(model.userID);
      }
    }
  }

  Future<void> getUserData(String userID) async {
    final postLevelAvatarFallback = model.authorAvatarUrl.trim();

    void applyProfile({
      required String nick,
      required String uname,
      required String image,
      required String pushToken,
      required String name,
    }) {
      final rawImage = image.toString().trim();
      final shouldUsePostFallback = postLevelAvatarFallback.isNotEmpty &&
          (rawImage.isEmpty || rawImage == kDefaultAvatarUrl);
      final normalizedImage = shouldUsePostFallback
          ? postLevelAvatarFallback
          : (rawImage.isEmpty ? kDefaultAvatarUrl : rawImage);
      nickname.value = nick;
      username.value = uname;
      avatarUrl.value = normalizedImage;
      token.value = pushToken;
      fullName.value = name;
    }

    void cacheProfile({
      required String uid,
      required String nick,
      required String uname,
      required String image,
      required String pushToken,
      required String name,
    }) {
      _userProfileCache[uid] = _UserProfileCacheEntry(
        nickname: nick,
        username: uname,
        avatarUrl: image,
        token: pushToken,
        fullName: name,
        updatedAt: DateTime.now(),
      );
    }

    void bindCurrentUserStream() {
      _currentUserStreamSub?.cancel();
      _currentUserStreamSub = userService.userStream.listen((user) {
        if (user == null || user.userID != userID) return;
        final currentUserDisplayName =
            user.fullName.trim().isNotEmpty ? user.fullName : user.nickname;
        final image = userService.avatarUrl;
        applyProfile(
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
        cacheProfile(
          uid: userID,
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
      });
    }

    // Current user posts should stay bound to current-user stream so avatar/
    // nickname changes are reflected immediately in feed cards.
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == userID) {
      if (userService.currentUser != null) {
        final user = userService.currentUser!;
        final currentUserDisplayName =
            user.fullName.trim().isNotEmpty ? user.fullName : user.nickname;
        final image = userService.avatarUrl;
        applyProfile(
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
        cacheProfile(
          uid: userID,
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
        bindCurrentUserStream();
        return;
      }
      bindCurrentUserStream();
    }
    if (currentUserId != userID) {
      _currentUserStreamSub?.cancel();
      _currentUserStreamSub = null;
    }

    // 0) Aynı kullanıcı için hafızadaki cache tazeyse, ağa gitmeden çık.
    final cachedProfile = _userProfileCache[userID];
    if (cachedProfile != null &&
        DateTime.now().difference(cachedProfile.updatedAt) <
            _userProfileCacheTtl) {
      applyProfile(
        nick: cachedProfile.nickname,
        uname: cachedProfile.username,
        image: cachedProfile.avatarUrl,
        pushToken: cachedProfile.token,
        name: cachedProfile.fullName,
      );
      return;
    }

    final userRepository = UserRepository.ensure();
    final warmProfile = userRepository.peekUser(userID, allowStale: true);
    if (warmProfile != null) {
      applyProfile(
        nick: warmProfile.nickname,
        uname: warmProfile.username.isNotEmpty
            ? warmProfile.username
            : warmProfile.nickname,
        image: warmProfile.avatarUrl,
        pushToken: warmProfile.token,
        name: warmProfile.preferredName,
      );
      cacheProfile(
        uid: userID,
        nick: warmProfile.nickname,
        uname: warmProfile.username.isNotEmpty
            ? warmProfile.username
            : warmProfile.nickname,
        image: warmProfile.avatarUrl,
        pushToken: warmProfile.token,
        name: warmProfile.preferredName,
      );
      return;
    }

    try {
      final summary = await userRepository.getUser(
        userID,
        preferCache: true,
        cacheOnly: false,
      );
      if (summary != null) {
        applyProfile(
          nick: summary.nickname,
          uname:
              summary.username.isNotEmpty ? summary.username : summary.nickname,
          image: summary.avatarUrl,
          pushToken: summary.token,
          name: summary.preferredName,
        );
        cacheProfile(
          uid: userID,
          nick: summary.nickname,
          uname:
              summary.username.isNotEmpty ? summary.username : summary.nickname,
          image: summary.avatarUrl,
          pushToken: summary.token,
          name: summary.preferredName,
        );
      }
    } catch (_) {}
  }

  Future<void> goToPreview() async {
    //flood listing
  }

  Future<void> saveSeeing() async {
    try {
      await _interactionService.recordView(model.docID);
    } catch (_) {}
  }

  Future<void> getReSharedUsers(String docID) async {
    final cached = _reshareUsersCache[docID];
    if (cached != null &&
        DateTime.now().difference(cached.updatedAt) < _reshareUsersCacheTtl) {
      reSharedUsers.value = cached.userIds;
      reShareUserUserID.value = cached.displayUserId;
      reShareUserNickname.value = cached.displayNickname;
      return;
    }

    final reshareEntries = await _postRepository.fetchAllReshareEntries(
      docID,
      limit: 200,
    );
    final entries =
        reshareEntries.map((e) => MapEntry(e.userId, e.timeStamp)).toList();
      // ID listesi
      final list = entries.map((e) => e.key).toList();
      reSharedUsers.value = list;

      // Kimi göstereceğiz? Önce ben, sonra takip ettiklerimden en günceli
      final me = FirebaseAuth.instance.currentUser?.uid;
      if (me != null && list.contains(me)) {
        reShareUserUserID.value = me;
        reShareUserNickname.value = 'Sen';
        _reshareUsersCache[docID] = _ReshareUsersCacheEntry(
          updatedAt: DateTime.now(),
          userIds: List<String>.from(list),
          displayUserId: me,
          displayNickname: 'Sen',
        );
        return;
      }

      // Takip ettiklerimden biri var mı?
      try {
        final following = agendaController.followingIDs;
        // Takip edilenler içinden en yeni timeStamp’e sahip olanı seç
        final candidates = entries
            .where((e) => following.contains(e.key))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (candidates.isNotEmpty) {
          final match = candidates.first.key;
          reShareUserUserID.value = match;
          final cached = ReshareHelper.getCachedNickname(match);
          if (cached != null) {
            reShareUserNickname.value = cached;
          } else {
            final nick = await ReshareHelper.getUserNickname(match);
            reShareUserNickname.value = nick;
          }
          _reshareUsersCache[docID] = _ReshareUsersCacheEntry(
            updatedAt: DateTime.now(),
            userIds: List<String>.from(list),
            displayUserId: match,
            displayNickname: reShareUserNickname.value,
          );
          return;
        }
      } catch (_) {}

      // Kimse yoksa temizle
      reShareUserUserID.value = '';
      reShareUserNickname.value = '';
      _reshareUsersCache[docID] = _ReshareUsersCacheEntry(
        updatedAt: DateTime.now(),
        userIds: List<String>.from(list),
        displayUserId: '',
        displayNickname: '',
      );
  }

  Future<void> like() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final bool wasLiked = uid != null && likes.contains(uid);

    try {
      await _postRepository.toggleLike(model);
    } catch (e) {
      if (uid != null) {
        if (wasLiked) {
          if (!likes.contains(uid)) likes.add(uid);
        } else {
          likes.remove(uid);
        }
      }
      AppSnackbar('Hata', 'Beğeni işlemi başarısız: $e');
    }
  }

  Future<void> save() async {
    final bool wasSaved = saved.value;

    try {
      await _postRepository.toggleSave(model);
    } catch (e) {
      saved.value = wasSaved;
      AppSnackbar('Hata', 'Kaydetme işlemi başarısız: $e');
    }
  }

  Future<void> showPostCommentsBottomSheet({VoidCallback? onClosed}) async {
    await Get.bottomSheet(
      SizedBox(
        height: Get.height * 0.55, // Ekranın %95'i kadar yükseklik
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: PostComments(
            postID: model.docID,
            userID: model.userID,
            collection: 'Posts',
            onCommentCountChange: (increment) async {
              await updateCommentCount(increment: increment);
            },
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true, // Sürükleyerek kapatma için
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white, // Alt barda arka plan rengi
      barrierColor: Colors.black54, // Gri karartma rengi
    ).then((v) {
      if (onClosed != null) onClosed();
    });
  }

  Future<void> followUser() async {
    if (model.userID == FirebaseAuth.instance.currentUser!.uid) return;
    await onlyFollowUserOneTime();
  }

  Future<void> onlyFollowUserOneTime() async {
    try {
      if (followLoading.value) return;
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      final alreadyFollowing = await FollowRepository.ensure().isFollowing(
        model.userID,
        currentUid: currentUid,
        preferCache: true,
      );
      if (alreadyFollowing) {
        isFollowing.value = true;
        return;
      }

      followLoading.value = true;
      final outcome = await FollowService.toggleFollow(model.userID);
      if (outcome.nowFollowing) {
        isFollowing.value = true;
      }
      if (outcome.limitReached) {
        AppSnackbar('Takip Limiti', 'Günlük daha fazla kişi takip edilemiyor.');
      }
    } catch (e) {
      print('Bir hata oluştu: $e');
    } finally {
      followLoading.value = false;
    }
  }

  Future<void> sendPost() async {
    Get.bottomSheet(Container(
      height: Get.height / 1.5,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(12), topLeft: Radius.circular(12))),
      child: ShareGrid(postID: model.docID, postType: "Post"),
    ));
  }

  Future<void> sendAdminPushForPost() async {
    if (!canSendAdminPush) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final pushCopy = _buildPostPushCopy();
    final title = pushCopy.title;
    final body = pushCopy.body;
    final imageUrl = _pushPreviewImageUrl();

    try {
      final written = await _adminPushRepository.sendPostPush(
        postId: model.docID,
        title: title,
        body: body,
        imageUrl: imageUrl,
      );
      try {
        await _adminPushRepository.addPostReport(
          senderUid: currentUid,
          title: title,
          body: body,
          targetCount: written,
          postId: model.docID,
          imageUrl: imageUrl,
        );
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
      }
      AppSnackbar('Push', '$written kullaniciya push kuyruga alindi');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        AppSnackbar('Push', 'Push kuyruga alindi');
        return;
      }
      AppSnackbar('Hata', 'Push gonderilemedi: $e');
    } catch (e) {
      AppSnackbar('Hata', 'Push gonderilemedi: $e');
    }
  }

  // Dinamik sayaç güncelleme fonksiyonları
  Future<void> updateCommentCount({bool increment = true}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (increment) {
      commentCount.value++;
      // Yorum yapıldığında kullanıcıyı comments listesine ekle
      if (uid != null && !comments.contains(uid)) {
        comments.add(uid);
      }
    } else if (commentCount.value > 0) {
      commentCount.value--;
      // Yorum silindiğinde kullanıcıyı listeden çıkar (eğer başka yorumu yoksa)
      if (uid != null) {
        // Real-time listener zaten kontrol ediyor, ek işlem gerekmiyor
        // Çünkü _bindCommentsListener kullanıcının yorumlarını dinliyor
      }
    }
  }

  Future<void> updateStatsCount() async {
    try {
      await countManager.updateStatsCount(model.docID, by: 1);
      final newStats = PostStats(
        commentCount: model.stats.commentCount,
        likeCount: model.stats.likeCount,
        reportedCount: model.stats.reportedCount,
        retryCount: model.stats.retryCount,
        savedCount: model.stats.savedCount,
        statsCount: statsCount.value,
      );
      model.stats = newStats;
      currentModel.value = model;
    } catch (e) {
      print('Stats count update error: $e');
    }
  }

  @protected
  void onPostInitialized() {}

  @protected
  void onPostFrameBound() {}

  @protected
  Future<void> onReshareAdded(String? uid) async {
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
  Future<void> onReshareRemoved(String? uid) async {}
}

class _UserProfileCacheEntry {
  final String nickname;
  final String username;
  final String avatarUrl;
  final String token;
  final String fullName;
  final DateTime updatedAt;

  const _UserProfileCacheEntry({
    required this.nickname,
    required this.username,
    required this.avatarUrl,
    required this.token,
    required this.fullName,
    required this.updatedAt,
  });
}

class _ReshareUsersCacheEntry {
  final DateTime updatedAt;
  final List<String> userIds;
  final String displayUserId;
  final String displayNickname;

  const _ReshareUsersCacheEntry({
    required this.updatedAt,
    required this.userIds,
    required this.displayUserId,
    required this.displayNickname,
  });
}
