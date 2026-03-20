import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:uuid/uuid.dart';
import '../../../Models/posts_model.dart';
import '../../../Services/reshare_helper.dart';
import '../../../Services/post_count_manager.dart';
import '../../../Services/post_interaction_service.dart';
import '../../Agenda/agenda_controller.dart';
import '../../Profile/MyProfile/profile_controller.dart';
import '../../ShareGrid/share_grid.dart';
import '../../Short/short_controller.dart';
import '../Comments/post_comments.dart';
import '../../../Services/post_delete_service.dart';
import '../../../Core/Services/admin_access_service.dart';
import '../../../Core/Repositories/post_repository.dart';
import '../../../Core/Repositories/admin_push_repository.dart';
import '../../../Core/Services/user_summary_resolver.dart';
import '../../../Core/Services/typesense_post_service.dart';

class PhotoShortsContentController extends GetxController {
  PostsModel model;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  PhotoShortsContentController({required this.model});

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

  var avatarUrl = "".obs;
  var nickname = "".obs;
  var token = "".obs;
  var fullName = "".obs;
  var takipEdiyorum = false.obs;
  var followLoading = false.obs;
  var fullScreen = false.obs;

  var likes = [].obs;
  var unLikes = [].obs;
  var saved = [].obs;
  var comments = [].obs;
  var seens = [].obs;
  var reSharedUsers = [].obs;
  var userComments = [].obs; // Kullanıcının yaptığı yorumlar
  RxBool isLiked = false.obs;
  RxBool isSaved = false.obs;
  RxBool isReshared = false.obs;
  RxBool isReported = false.obs;
  final agendaController = Get.find<AgendaController>();
  final countManager = PostCountManager.instance;
  late final PostInteractionService _interactionService;
  late final PostRepository _postRepository;
  late final AdminPushRepository _adminPushRepository;
  PostRepositoryState? _postState;
  StreamSubscription<DocumentSnapshot>? _likeDocSub;
  StreamSubscription<DocumentSnapshot>? _savedDocSub;
  StreamSubscription<DocumentSnapshot>? _reshareDocSub;
  StreamSubscription<DocumentSnapshot>? _postDocSub;
  Worker? _interactionWorker;

  // Reactive count variables using centralized manager
  RxInt get likeCount => countManager.getLikeCount(model.docID);
  RxInt get commentCount => countManager.getCommentCount(model.docID);
  RxInt get savedCount => countManager.getSavedCount(model.docID);
  RxInt get retryCount => countManager.getRetryCount(model.docID);

  var arsiv = false.obs;
  var gizlendi = false.obs;
  var sikayetEdildi = false.obs;
  var silindi = false.obs;
  var silindiOpacity = 1.0.obs;

  var yenidenPaylasildiMi = false.obs;

  @override
  void onInit() {
    super.onInit();
    _interactionService = Get.put(PostInteractionService());
    _postRepository = PostRepository.ensure();
    _adminPushRepository = AdminPushRepository.ensure();
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
      _loadUserInteractionStatus();
    });

    getGizleArsivSikayetEdildi();
    avatarUrl.value = model.authorAvatarUrl.trim();
    nickname.value = model.authorNickname.trim();
    fullName.value = model.authorDisplayName.trim();
    fetchUserData(model.userID);
    getReSharedUsers(model.docID);
    getYenidenPaylasBilgisi();
    // Deprecated method calls removed - real-time listeners handle data updates
    // getComments(), getLikes(), getSaved() are replaced by reactive listeners
    getSeens();
    saveSeeing();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindMembershipListeners();
      _bindReshareListener();
      _bindPostDocCounts();
    });
  }

  @override
  void onClose() {
    _interactionWorker?.dispose();
    _postRepository.releasePost(model.docID);
    _likeDocSub?.cancel();
    _savedDocSub?.cancel();
    _reshareDocSub?.cancel();
    _postDocSub?.cancel();
    super.onClose();
  }

  void _bindMembershipListeners() {
    _postState ??= _postRepository.attachPost(model);
    _syncSharedInteractionState();
    _interactionWorker?.dispose();
    if (_postState != null) {
      _interactionWorker = everAll([
        _postState!.liked,
        _postState!.saved,
        _postState!.reshared,
      ], (_) {
        _syncSharedInteractionState();
      });
    }
  }

  void _bindReshareListener() {
    _syncSharedInteractionState();
  }

  void _bindPostDocCounts() {
    _postState ??= _postRepository.attachPost(model);
  }

  void _syncSharedInteractionState() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_postState == null) return;
    final liked = _postState!.liked.value;
    final savedState = _postState!.saved.value;
    final reshared = _postState!.reshared.value;
    if (uid != null) {
      if (liked) {
        if (!likes.contains(uid)) likes.add(uid);
      } else {
        likes.remove(uid);
      }
      if (savedState) {
        if (!saved.contains(uid)) saved.add(uid);
      } else {
        saved.remove(uid);
      }
    }
    isLiked.value = liked;
    isSaved.value = savedState;
    isReshared.value = reshared;
    yenidenPaylasildiMi.value = reshared;
  }

  void _initializeStats() {
    likeCount.value = model.stats.likeCount.toInt();
    commentCount.value = model.stats.commentCount.toInt();
    savedCount.value = model.stats.savedCount.toInt();
    retryCount.value = model.stats.retryCount.toInt();
  }

  Future<void> _loadUserInteractionStatus() async {
    _postState ??= _postRepository.attachPost(model);
    _syncSharedInteractionState();
    isReported.value = _postState?.reported.value ?? false;
  }

  Future<void> toggleLike() async {
    try {
      await _postRepository.toggleLike(model);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.like_failed'.tr);
    }
  }

  Future<void> like() => toggleLike();

  Future<void> toggleSave() async {
    try {
      await _postRepository.toggleSave(model);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.save_failed'.tr);
    }
  }

  Future<void> save() => toggleSave();

  Future<void> toggleReshare() async {
    try {
      final status = await _postRepository.toggleReshare(model);
      if (status) {
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

  Future<void> reportPost() async {
    try {
      final success = await _interactionService.reportPost(model.docID);
      if (success) {
        isReported.value = true;
        AppSnackbar('common.success'.tr, 'post.report_success'.tr);
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.report_failed'.tr);
    }
  }

  Future<void> getGizleArsivSikayetEdildi() async {
    gizlendi.value = model.gizlendi;
    arsiv.value = model.arsiv;
    silindi.value = model.deletedPost;
  }

  Future<void> gizle() async {
    final shortController = Get.find<ShortController>();
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
    final shortController = Get.find<ShortController>();
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
    await _postRepository.setArchived(model, true);

    // Tüm ilgili store ve listeleri güncelle
    final shortController = Get.find<ShortController>();
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
    await _postRepository.setArchived(model, false);

    // Tüm ilgili store ve listeleri güncelle
    final shortController = Get.find<ShortController>();
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

    arsiv.value = false;
  }

  Future<void> sil() async {
    await PostDeleteService.instance.softDelete(model);
    silindi.value = true; // UI overlay

    // Yumuşak fade-out
    Future.delayed(const Duration(milliseconds: 2600), () {
      silindiOpacity.value = 0.0;
    });

    // 3 sn sonra overlay'i kaldır ve uygun listelerden çıkar
    Future.delayed(const Duration(seconds: 3), () {
      // Explore listeleri
      if (Get.isRegistered<ExploreController>()) {
        final explore = Get.find<ExploreController>();
        final i1 =
            explore.explorePhotos.indexWhere((e) => e.docID == model.docID);
        if (i1 != -1) {
          explore.explorePhotos.removeAt(i1);
        }
        final i2 =
            explore.explorePosts.indexWhere((e) => e.docID == model.docID);
        if (i2 != -1) {
          explore.explorePosts.removeAt(i2);
        }
        explore.explorePhotos.refresh();
        explore.explorePosts.refresh();
      }

      // Agenda listesi
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

  Future<void> getYenidenPaylasBilgisi() async {
    _postState ??= _postRepository.attachPost(model);
    _syncSharedInteractionState();
  }

  Future<void> sikayetEt() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      // 1) Yeni gizleme durumu
      final bool yeniDurum = !model.sikayetEdildi;

      // 2) Firestore güncellemesi
      final hideRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("HiddenPosts")
          .doc(model.docID);

      if (yeniDurum) {
        // Gizle: dokümanı oluştur
        await hideRef.set({
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        // Geri al: dokümanı sil
        await hideRef.delete();
      }

      sikayetEdildi.value = yeniDurum;
      model = model.copyWith(sikayetEdildi: yeniDurum);

      // 4) Ana listedeki modeli de güncelle ve notify et
      final idx =
          agendaController.agendaList.indexWhere((e) => e.docID == model.docID);
      if (idx != -1) {
        agendaController.agendaList[idx] =
            agendaController.agendaList[idx].copyWith(sikayetEdildi: yeniDurum);
        agendaController.agendaList.refresh();
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.hide_failed'.tr);
    }
  }

  Future<void> sikayetEdilenGonderiGoster() async {
    try {
      final bool yeniDurum = !model.sikayetEdildi;
      sikayetEdildi.value = yeniDurum;
      model = model.copyWith(sikayetEdildi: yeniDurum);

      // 4) Ana listedeki modeli de güncelle ve notify et
      final idx =
          agendaController.agendaList.indexWhere((e) => e.docID == model.docID);
      if (idx != -1) {
        agendaController.agendaList[idx] =
            agendaController.agendaList[idx].copyWith(sikayetEdildi: yeniDurum);
        agendaController.agendaList.refresh();
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.hide_failed'.tr);
    }
  }

  Future<void> fetchUserData(String userID) async {
    final postLevelAvatar = model.authorAvatarUrl.trim();
    final postLevelNickname = model.authorNickname.trim();
    final postLevelDisplayName = model.authorDisplayName.trim();
    final hasPostLevelIdentity = postLevelAvatar.isNotEmpty &&
        postLevelNickname.isNotEmpty &&
        postLevelDisplayName.isNotEmpty;

    if (hasPostLevelIdentity) {
      avatarUrl.value = postLevelAvatar;
      nickname.value = postLevelNickname;
      token.value = '';
      fullName.value = postLevelDisplayName;
      takipEdiyorum.value = await FollowRepository.ensure().isFollowing(
        userID,
        currentUid: FirebaseAuth.instance.currentUser!.uid,
        preferCache: true,
      );
      return;
    }

    final summary = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (summary != null) {
      avatarUrl.value = model.authorAvatarUrl.trim().isNotEmpty
          ? model.authorAvatarUrl.trim()
          : summary.avatarUrl;
      nickname.value = model.authorNickname.trim().isNotEmpty
          ? model.authorNickname.trim()
          : (summary.nickname.isNotEmpty
              ? summary.nickname
              : summary.preferredName);
      token.value = summary.token;
      fullName.value = model.authorDisplayName.trim().isNotEmpty
          ? model.authorDisplayName.trim()
          : summary.displayName;
    }

    takipEdiyorum.value = await FollowRepository.ensure().isFollowing(
      userID,
      currentUid: FirebaseAuth.instance.currentUser!.uid,
      preferCache: true,
    );
  }

  Future<void> toggleFollowStatus(String userID) async {
    if (followLoading.value) return;
    final wasFollowing = takipEdiyorum.value;
    takipEdiyorum.value = !wasFollowing; // optimistic
    followLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      takipEdiyorum.value = outcome.nowFollowing;
      if (outcome.limitReached) {
        AppSnackbar('following.limit_title'.tr, 'following.limit_body'.tr);
      }
    } catch (e) {
      takipEdiyorum.value = wasFollowing; // revert on error
      print("Bir hata oluştu: $e");
    } finally {
      followLoading.value = false;
    }
  }

  Future<void> showPostCommentsBottomSheet() async {
    // bottom sheet'i aç
    await Get.bottomSheet(
      SizedBox(
        height: Get.height * 0.5,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: PostComments(
            postID: model.docID,
            userID: model.userID,
            collection: 'Posts',
            onCommentCountChange: (bool increment) async {
              // Centralized count manager ile yorum sayacını güncelle
              await countManager.updateCommentCount(
                  model.docID, model.originalPostID,
                  increment: increment);
            },
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
    );

    // Comment updates are now handled by real-time listeners
  }

  Future<void> getComments() async {
    comments.clear();
    userComments.clear();
  }

  Future<void> getReSharedUsers(String docID) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      reSharedUsers.clear();
      return;
    }
    _postState ??= _postRepository.attachPost(model);
    reSharedUsers.value =
        (_postState?.reshared.value ?? false) ? <String>[uid] : <String>[];
  }

  Future<void> getSaved() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      saved.clear();
      return;
    }
    _postState ??= _postRepository.attachPost(model);
    saved.value =
        (_postState?.saved.value ?? false) ? <String>[uid] : <String>[];
  }

  Future<void> yenidenPaylasSorusu() async {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Get.back();
                reShare(model);
              },
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/reshare.webp",
                    height: 30,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    reSharedUsers
                            .contains(FirebaseAuth.instance.currentUser!.uid)
                        ? 'post.reshare_undo'.tr
                        : 'post.reshare_action'.tr,
                    style: TextStyle(
                      color: reSharedUsers
                              .contains(FirebaseAuth.instance.currentUser!.uid)
                          ? Colors.red
                          : Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                Get.back();
              },
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.arrow_turn_up_right,
                    color: Colors.black,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'common.quote'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  'common.cancel'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> reShare(PostsModel model) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (!reSharedUsers.contains(uid)) {
      // Yeni paylaşım
      final newPostID = const Uuid().v4();
      final newTimestamp = DateTime.now().millisecondsSinceEpoch;

      // Dinamik paylaşım zinciri için orijinal kullanıcı bilgilerini al
      final originalUserInfo = await ReshareHelper.getDynamicOriginalInfo(
        model.docID,
        model.userID,
        model.originalUserID,
        model.originalPostID,
      );

      final normalizedAR = double.parse(model.aspectRatio.toStringAsFixed(4));
      await FirebaseFirestore.instance.collection("Posts").doc(newPostID).set({
        "arsiv": false,
        "aspectRatio": normalizedAR,
        "debugMode": false,
        "deletedPost": false,
        "deletedPostTime": 0,
        "flood": false,
        "floodCount": 0,
        "gizlendi": false,
        "img": [],
        "isAd": false,
        "ad": false,
        "izBirakYayinTarihi": 0,
        "konum": "",
        "mainFlood": "",
        "metin": "",
        "paylasGizliligi": 0,
        "scheduledAt": 0,
        "sikayetEdildi": false,
        "stabilized": false,
        "stats": {
          "commentCount": 0,
          "likeCount": 0,
          "reportedCount": 0,
          "retryCount": 0,
          "savedCount": 0,
          "statsCount": 0
        },
        "tags": [],
        "thumbnail": "",
        "timeStamp": newTimestamp,
        "userID": uid,
        "video": "",
        "yorum": true,
        "originalUserID": originalUserInfo['userID'],
        "originalPostID": originalUserInfo['originalPostID'],
      });
      unawaited(
        TypesensePostService.instance
            .syncPostById(newPostID)
            .catchError((_) {}),
      );

      // Kök ve görünür bir gönderi olarak say (counterOfPosts +=1)
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'counterOfPosts': FieldValue.increment(1)});
      } catch (_) {}

      await FirebaseFirestore.instance
          .collection("Posts")
          .doc(model.docID)
          .collection("YenidenPaylas")
          .doc(uid)
          .set({
        "timeStamp": newTimestamp,
        "yeniPostID": newPostID,
      });

      reSharedUsers.add(FirebaseAuth.instance.currentUser!.uid);

      // Profildeki gönderiler listesine en üstten eklemeyi dene
      try {
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().getLastPostAndAddToAllPosts();
        }
      } catch (_) {}
    } else {
      // Daha önce paylaşılmış -> sil
      final yeniPostID =
          await _postRepository.fetchLegacyResharedPostId(model.docID, uid);

      if (yeniPostID != null && yeniPostID.isNotEmpty) {

        await FirebaseFirestore.instance
            .collection("Posts")
            .doc(yeniPostID)
            .delete();
        await FirebaseFirestore.instance
            .collection("Posts")
            .doc(model.docID)
            .collection("YenidenPaylas")
            .doc(uid)
            .delete();
        reSharedUsers.remove(FirebaseAuth.instance.currentUser!.uid);

        // UI'dan kaldır
        agendaController.agendaList
            .removeWhere((item) => item.docID == yeniPostID);
        agendaController.agendaList.refresh();
      }
    }

    // Diğer güncellemeler
    fetchUserData(model.userID);
    getReSharedUsers(model.docID);
    // Deprecated method calls removed - real-time listeners handle data updates
    getSeens();
    getUnlikes();
  }

  Future<void> getLikes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      likes.clear();
      return;
    }
    _postState ??= _postRepository.attachPost(model);
    likes.value =
        (_postState?.liked.value ?? false) ? <String>[uid] : <String>[];
  }

  Future<void> getUnlikes() async {
    unLikes.value = await _postRepository.fetchDislikeUserIds(model.docID);
  }

  Future<void> getSeens() async {
    seens.clear();
  }

  Future<void> saveSeeing() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _postRepository.ensureViewerSeen(model.docID, uid);
    } catch (_) {}
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
      AppSnackbar(
        'admin_push.queue_title'.tr,
        'admin_push.queue_body_count'.trParams({'count': '$written'}),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        AppSnackbar('admin_push.queue_title'.tr, 'admin_push.queue_body'.tr);
        return;
      }
      AppSnackbar('common.error'.tr, 'admin_push.failed_body'.tr);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'admin_push.failed_body'.tr);
    }
  }
}
