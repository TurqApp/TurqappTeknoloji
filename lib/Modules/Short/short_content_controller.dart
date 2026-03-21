import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import '../Agenda/agenda_controller.dart';
import '../Profile/MyProfile/profile_controller.dart';
import '../ShareGrid/share_grid.dart';
import '../../Services/post_delete_service.dart';
import 'short_controller.dart';
import '../../Services/post_interaction_service.dart';
import '../../Core/Repositories/post_repository.dart';
import '../../Core/Repositories/follow_repository.dart';
import '../../Core/Services/user_summary_resolver.dart';
import '../../Services/current_user_service.dart';

class ShortContentController extends GetxController {
  String postID;
  PostsModel model;

  ShortContentController({
    required this.postID,
    required this.model,
  });

  var avatarUrl = "".obs;
  var nickname = "".obs;
  var fullName = "".obs;
  var token = "".obs;
  var takipEdiyorum = false.obs;
  var followLoading = false.obs;
  // yorumCount -> commentCount RxInt'e taşındı
  var pageCounter = 0.obs;
  // Yeni interaction service
  late PostInteractionService _interactionService;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  // Stats observables - PostsModel.stats'tan alinacak
  RxInt likeCount = 0.obs;
  RxInt commentCount = 0.obs;
  RxInt savedCount = 0.obs;
  RxInt retryCount = 0.obs;
  RxInt viewCount = 0.obs;
  RxInt reportCount = 0.obs;

  // User interaction status
  RxBool isLiked = false.obs;
  RxBool isSaved = false.obs;
  RxBool isReshared = false.obs;
  RxBool isReported = false.obs;
  var gizlendi = false.obs;
  var arsivlendi = false.obs;
  var silindi = false.obs;
  var silindiOpacity = 1.0.obs;
  var ilkPaylasanPfImage = "".obs;
  var ilkPaylasanNickname = "".obs;
  var ilkPaylasanUserID = "".obs;
  var fullscreen = true.obs;
  // Kaldırılan deprecated değişkenler:
  // yenidenPaylasildiMi -> isReshared
  // countManager -> PostInteractionService
  // retryCount, statsCount -> lokal RxInt'ler
  StreamSubscription<DocumentSnapshot>? _postDocSub;
  late final PostRepository _postRepository;
  PostRepositoryState? _postState;
  Worker? _interactionWorker;
  Worker? _postDataWorker;
  Timer? _deleteFadeTimer;
  Timer? _deleteRemoveTimer;
  String get _currentUserId {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  @override
  void onInit() {
    super.onInit();

    // Initialize interaction service
    _interactionService = PostInteractionService.ensure();
    _postRepository = PostRepository.ensure();

    // Initialize stats from model
    _initializeStats();

    // Initialize other data
    getGizleArsivSikayetEdildi();
    avatarUrl.value = model.authorAvatarUrl.trim();
    nickname.value = model.authorNickname.trim();
    fullName.value = model.authorDisplayName.trim();
    fetchUserData(model.userID);

    // Record view and load user interaction status
    Future.microtask(() {
      if (isClosed) return;
      _interactionService.recordView(model.docID);
      _loadUserInteractionStatus();
    });

    // Bind listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      _bindPostStatsListener();
    });
  }

  @override
  void onClose() {
    _deleteFadeTimer?.cancel();
    _deleteRemoveTimer?.cancel();
    _interactionWorker?.dispose();
    _postDataWorker?.dispose();
    _postRepository.releasePost(model.docID);
    _postDocSub?.cancel();
    super.onClose();
  }

  // Initialize stats from PostsModel
  void _initializeStats() {
    likeCount.value = model.stats.likeCount.toInt();
    commentCount.value = model.stats.commentCount.toInt();
    savedCount.value = model.stats.savedCount.toInt();
    retryCount.value = model.stats.retryCount.toInt();
    viewCount.value = model.stats.statsCount.toInt();
    reportCount.value = model.stats.reportedCount.toInt();
  }

  // Load user's interaction status for this post
  Future<void> _loadUserInteractionStatus() async {
    try {
      _postState ??= _postRepository.attachPost(model);
      _syncSharedInteractionState();
    } catch (_) {}
  }

  // Bind to real-time stats updates
  void _bindPostStatsListener() {
    _postState ??= _postRepository.attachPost(model);
    _postDataWorker?.dispose();
    _postDataWorker =
        ever<Map<String, dynamic>?>(_postState!.latestPostData, (data) {
      if (isClosed || data == null) return;
      final stats = data['stats'] as Map<String, dynamic>? ?? const {};
      likeCount.value = ((stats['likeCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
      commentCount.value = ((stats['commentCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
      savedCount.value = ((stats['savedCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
      retryCount.value = ((stats['retryCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
      viewCount.value = ((stats['statsCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
      reportCount.value = ((stats['reportedCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
    });
    _interactionWorker?.dispose();
    _interactionWorker = everAll([
      _postState!.liked,
      _postState!.saved,
      _postState!.reshared,
      _postState!.reported,
    ], (_) {
      _syncSharedInteractionState();
    });
  }

  void _syncSharedInteractionState() {
    if (isClosed || _postState == null) return;
    isLiked.value = _postState!.liked.value;
    isSaved.value = _postState!.saved.value;
    isReshared.value = _postState!.reshared.value;
    isReported.value = _postState!.reported.value;
  }

  // ========== POST INTERACTION METHODS ==========

  /// Toggle like for the post
  Future<void> toggleLike() async {
    try {
      await _postRepository.toggleLike(model);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.like_failed'.tr);
    }
  }

  Future<void> like() => toggleLike();

  /// Toggle save for the post
  Future<void> toggleSave() async {
    try {
      await _postRepository.toggleSave(model);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.save_failed'.tr);
    }
  }

  Future<void> save() => toggleSave();

  /// Toggle reshare for the post
  Future<void> toggleReshare() async {
    try {
      final newReshareStatus = await _postRepository.toggleReshare(model);
      if (newReshareStatus) {
        try {
          Get.find<ProfileController>().getResharesSingle();
        } catch (_) {}
      } else {
        try {
          Get.find<ProfileController>().removeReshare(model.docID);
        } catch (_) {}
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.reshare_failed'.tr);
    }
  }

  Future<void> reshare() => toggleReshare();

  /// Report the post
  Future<void> reportPost() async {
    try {
      final success = await _interactionService.reportPost(model.docID);
      if (success) {
        isReported.value = true;
        reportCount.value++;
        AppSnackbar('common.success'.tr, 'post.report_success'.tr);
      } else {
        AppSnackbar('common.info'.tr, 'post.already_reported'.tr);
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.report_failed'.tr);
    }
  }

  Future<void> getGizleArsivSikayetEdildi() async {
    gizlendi.value = model.gizlendi;
    arsivlendi.value = model.arsiv;
    silindi.value = model.deletedPost;
  }

  Future<void> gizle() async {
    final shortController = Get.find<ShortController>();
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].gizlendi = true;
    final explore = Get.find<ExploreController>();

    final index3 = explore.explorePosts.indexOf(model);
    if (index3 >= 0) explore.explorePosts[index3].gizlendi = true;

    final index4 = explore.explorePhotos.indexOf(model);
    if (index4 >= 0) explore.explorePhotos[index4].gizlendi = true;

    final index5 = explore.exploreVideos.indexOf(model);
    if (index5 >= 0) explore.exploreVideos[index5].gizlendi = true;

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
    final shortController = Get.find<ShortController>();
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].gizlendi = false;

    final explore = Get.find<ExploreController>();

    final index3 = explore.explorePosts.indexOf(model);
    if (index3 >= 0) explore.explorePosts[index3].gizlendi = false;

    final index4 = explore.explorePhotos.indexOf(model);
    if (index4 >= 0) explore.explorePhotos[index4].gizlendi = false;

    final index5 = explore.exploreVideos.indexOf(model);
    if (index5 >= 0) explore.exploreVideos[index5].gizlendi = false;

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
    await _postRepository.setArchived(model, true);

    // Tüm ilgili store ve listeleri güncelle
    final shortController = Get.find<ShortController>();
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].arsiv = true;

    final explore = Get.find<ExploreController>();

    final index3 = explore.explorePosts.indexOf(model);
    if (index3 >= 0) explore.explorePosts[index3].arsiv = true;

    final index4 = explore.explorePhotos.indexOf(model);
    if (index4 >= 0) explore.explorePhotos[index4].arsiv = true;

    final index5 = explore.exploreVideos.indexOf(model);
    if (index5 >= 0) explore.exploreVideos[index5].arsiv = true;

    final store8 = Get.find<AgendaController>();
    final index8 = store8.agendaList.indexOf(model);
    if (index8 >= 0) store8.agendaList[index8].arsiv = true;

    final profile = Get.find<ProfileController>();
    final profileIndex = profile.allPosts.indexOf(model);
    if (profileIndex >= 0) profile.allPosts[profileIndex].arsiv = true;

    arsivlendi.value = true;
  }

  Future<void> arsivdenCikart() async {
    await _postRepository.setArchived(model, false);

    // Tüm ilgili store ve listeleri güncelle
    final shortController = Get.find<ShortController>();
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].arsiv = false;

    final explore = Get.find<ExploreController>();

    final index3 = explore.explorePosts.indexOf(model);
    if (index3 >= 0) explore.explorePosts[index3].arsiv = false;

    final index4 = explore.explorePhotos.indexOf(model);
    if (index4 >= 0) explore.explorePhotos[index4].arsiv = false;

    final index5 = explore.exploreVideos.indexOf(model);
    if (index5 >= 0) explore.exploreVideos[index5].arsiv = false;

    final store8 = Get.find<AgendaController>();
    final index8 = store8.agendaList.indexOf(model);
    if (index8 >= 0) store8.agendaList[index8].arsiv = false;

    final profile = Get.find<ProfileController>();
    final profileIndex = profile.allPosts.indexOf(model);
    if (profileIndex >= 0) profile.allPosts[profileIndex].arsiv = false;

    arsivlendi.value = false;
  }

  Future<void> sil() async {
    await PostDeleteService.instance.softDelete(model);
    if (isClosed) return;
    silindi.value = true; // UI overlay

    // Yumuşak fade-out
    _deleteFadeTimer?.cancel();
    _deleteFadeTimer = Timer(const Duration(milliseconds: 2600), () {
      if (isClosed) return;
      silindiOpacity.value = 0.0;
    });

    // 3 sn sonra overlay'i kaldır ve listeden çıkar
    _deleteRemoveTimer?.cancel();
    _deleteRemoveTimer = Timer(const Duration(seconds: 3), () {
      if (isClosed) return;
      // Short listeden kaldır
      if (Get.isRegistered<ShortController>()) {
        final shortController = Get.find<ShortController>();
        final idx =
            shortController.shorts.indexWhere((e) => e.docID == model.docID);
        if (idx != -1) {
          shortController.shorts.removeAt(idx);
          shortController.shorts.refresh();
        }
      }
    });
  }

  Future<void> getYenidenPaylasBilgisi() async {
    retryCount.value = _postState?.latestPostData.value == null
        ? model.stats.retryCount.toInt()
        : (((_postState!.latestPostData.value!['stats']
                    as Map<String, dynamic>?)?['retryCount'] ??
                model.stats.retryCount) as num)
            .toInt();
  }

  Future<void> getSeens() async {}

  Future<void> saveSeeing() async {
    try {
      await _interactionService.recordView(model.docID);
    } catch (_) {}
  }

  Future<void> fetchUserData(String userID) async {
    final postLevelAvatar = model.authorAvatarUrl.trim();
    final postLevelNickname = model.authorNickname.trim();
    final postLevelDisplayName = model.authorDisplayName.trim();
    final hasPostLevelIdentity = postLevelAvatar.isNotEmpty &&
        postLevelNickname.isNotEmpty &&
        postLevelDisplayName.isNotEmpty;

    if (hasPostLevelIdentity) {
      if (isClosed) return;
      avatarUrl.value = postLevelAvatar;
      nickname.value = postLevelNickname;
      fullName.value = postLevelDisplayName;
      token.value = '';
      takipEdiyorum.value = await FollowRepository.ensure().isFollowing(
        userID,
        currentUid: _currentUserId,
        preferCache: true,
      );
      return;
    }

    final summary = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
      cacheOnly: false,
    );
    if (isClosed) return;
    final resolvedAvatar = summary?.avatarUrl.trim().isNotEmpty == true
        ? summary!.avatarUrl.trim()
        : '';
    avatarUrl.value =
        postLevelAvatar.isNotEmpty ? postLevelAvatar : resolvedAvatar;
    nickname.value = postLevelNickname.isNotEmpty
        ? postLevelNickname
        : (summary?.nickname.trim().isNotEmpty == true
            ? summary!.nickname.trim()
            : '');
    token.value = summary?.token ?? '';
    fullName.value = postLevelDisplayName.isNotEmpty
        ? postLevelDisplayName
        : (summary?.displayName.trim().isNotEmpty == true
            ? summary!.displayName.trim()
            : nickname.value);

    takipEdiyorum.value = await FollowRepository.ensure().isFollowing(
      userID,
      currentUid: _currentUserId,
      preferCache: true,
    );
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

  Future<void> onlyFollowUserOneTime() async {
    if (followLoading.value) return;

    try {
      final currentUid = _currentUserId;
      final alreadyFollowing = await FollowRepository.ensure().isFollowing(
        model.userID,
        currentUid: currentUid,
        preferCache: true,
      );
      if (alreadyFollowing) {
        // Zaten takip ediyor, işlem yok
        takipEdiyorum.value = true;
        return;
      }
      followLoading.value = true;
      // Takip etmiyorsa, limit dahilinde takip et
      final outcome = await FollowService.toggleFollow(model.userID);
      if (outcome.nowFollowing) {
        takipEdiyorum.value = true;
      }
      if (outcome.limitReached) {
        AppSnackbar('following.limit_title'.tr, 'following.limit_body'.tr);
      }
    } catch (_) {
    } finally {
      followLoading.value = false;
    }
  }
}
