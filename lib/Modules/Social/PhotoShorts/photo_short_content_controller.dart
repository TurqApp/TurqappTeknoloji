import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:uuid/uuid.dart';
import '../../../Models/posts_model.dart';
import '../../../Services/firebase_my_store.dart';
import '../../../Services/current_user_service.dart';
import '../../../Services/reshare_helper.dart';
import '../../../Services/post_count_manager.dart';
import '../../../Services/post_interaction_service.dart';
import '../../Agenda/agenda_controller.dart';
import '../../Profile/MyProfile/profile_controller.dart';
import '../../ShareGrid/share_grid.dart';
import '../../Short/short_controller.dart';
import '../Comments/post_comments.dart';
import '../../../Services/post_delete_service.dart';

class PhotoShortsContentController extends GetxController {
  static const Set<String> _adminPushUserIds = {
    "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2",
    "hiv3UzAABlRWJaePerm3mtPEolI3",
  };
  static const Set<String> _adminPushNicknames = {
    "osmannafiz",
    "turqapp",
  };
  static const Set<String> _activePushTargetUserIds = {
    "i7RhJD0T5AazadgXl1iCc6ueeHf2",
    "hiv3UzAABlRWJaePerm3mtPEolI3",
    "CePvRgjSPobQrDQwH8SXJFuG1Jw2",
  };
  static const Set<String> _activePushTargetNicknames = {
    "osmannafiz",
    "turqapp",
  };
  static const int _pushTargetCutoffMs = 1772409600000;
  PostsModel model;

  PhotoShortsContentController({required this.model});

  bool get canSendAdminPush {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final currentNickname =
        CurrentUserService.instance.nickname.trim().toLowerCase();
    return _adminPushUserIds.contains(currentUid) ||
        _adminPushNicknames.contains(currentNickname);
  }

  bool _shouldSendPushToUser(DocumentSnapshot<Map<String, dynamic>> userDoc) {
    if (_activePushTargetUserIds.contains(userDoc.id)) return true;
    final data = userDoc.data() ?? const <String, dynamic>{};
    final nickname = (data['nickname'] ?? '').toString().trim().toLowerCase();
    if (_activePushTargetNicknames.contains(nickname)) return true;
    final rawCreatedDate = data['createdDate'];
    final createdAtMs = rawCreatedDate is num
        ? rawCreatedDate.toInt()
        : int.tryParse(rawCreatedDate?.toString() ?? '') ?? 0;
    return createdAtMs >= _pushTargetCutoffMs;
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

  var pfImage = "".obs;
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
  final user = Get.find<FirebaseMyStore>();
  final countManager = PostCountManager.instance;
  late final PostInteractionService _interactionService;
  StreamSubscription<DocumentSnapshot>? _likeDocSub;
  StreamSubscription<DocumentSnapshot>? _savedDocSub;
  StreamSubscription<DocumentSnapshot>? _reshareDocSub;
  StreamSubscription<DocumentSnapshot>? _postDocSub;

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
    _likeDocSub?.cancel();
    _savedDocSub?.cancel();
    _reshareDocSub?.cancel();
    _postDocSub?.cancel();
    super.onClose();
  }

  void _bindMembershipListeners() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _likeDocSub?.cancel();
    _savedDocSub?.cancel();
    _likeDocSub = FirebaseFirestore.instance
        .collection('Posts')
        .doc(model.docID)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        if (!likes.contains(uid)) likes.add(uid);
        isLiked.value = true;
      } else {
        likes.remove(uid);
        isLiked.value = false;
      }
    });
    _savedDocSub = FirebaseFirestore.instance
        .collection('Posts')
        .doc(model.docID)
        .collection('saveds')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        if (!saved.contains(uid)) saved.add(uid);
        isSaved.value = true;
      } else {
        saved.remove(uid);
        isSaved.value = false;
      }
    });
  }

  void _bindReshareListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _reshareDocSub?.cancel();
    _reshareDocSub = FirebaseFirestore.instance
        .collection('Posts')
        .doc(model.docID)
        .collection('reshares')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      final exists = doc.exists;
      yenidenPaylasildiMi.value = exists;
      isReshared.value = exists;
    });
  }

  void _bindPostDocCounts() {
    _postDocSub?.cancel();
    _postDocSub = FirebaseFirestore.instance
        .collection('Posts')
        .doc(model.docID)
        .snapshots()
        .listen((d) {
      final data = d.data();
      if (data == null) return;
      final stats = data['stats'] as Map<String, dynamic>? ?? {};
      countManager.getLikeCount(model.docID).value =
          (stats['likeCount'] ?? data['likeCount'] ?? 0) as int;
      countManager.getCommentCount(model.docID).value =
          (stats['commentCount'] ?? data['commentCount'] ?? 0) as int;
      countManager.getSavedCount(model.docID).value =
          (stats['savedCount'] ?? data['savedCount'] ?? 0) as int;
      countManager.getRetryCount(model.docID).value =
          (stats['retryCount'] ?? data['retryCount'] ?? 0) as int;
      countManager.getStatsCount(model.docID).value =
          (stats['statsCount'] ?? data['statsCount'] ?? 0) as int;
    });
  }

  void _initializeStats() {
    likeCount.value = model.stats.likeCount.toInt();
    commentCount.value = model.stats.commentCount.toInt();
    savedCount.value = model.stats.savedCount.toInt();
    retryCount.value = model.stats.retryCount.toInt();
  }

  Future<void> _loadUserInteractionStatus() async {
    final status =
        await _interactionService.getUserInteractionStatus(model.docID);
    isLiked.value = status['liked'] ?? false;
    isSaved.value = status['saved'] ?? false;
    isReshared.value = status['reshared'] ?? false;
    isReported.value = status['reported'] ?? false;
  }

  Future<void> toggleLike() async {
    try {
      final newLikeStatus = await _interactionService.toggleLike(model.docID);
      isLiked.value = newLikeStatus;
    } catch (e) {
      AppSnackbar('Hata', 'Beğeni işlemi başarısız: $e');
    }
  }

  Future<void> like() => toggleLike();

  Future<void> toggleSave() async {
    try {
      final newSaveStatus = await _interactionService.toggleSave(model.docID);
      isSaved.value = newSaveStatus;
    } catch (e) {
      AppSnackbar('Hata', 'Kaydetme işlemi başarısız: $e');
    }
  }

  Future<void> save() => toggleSave();

  Future<void> toggleReshare() async {
    try {
      final status = await _interactionService.toggleReshare(model.docID);
      isReshared.value = status;
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
      AppSnackbar('Hata', 'Yeniden paylaşma işlemi başarısız: $e');
    }
  }

  Future<void> reshare() => toggleReshare();

  Future<void> reportPost() async {
    try {
      final success = await _interactionService.reportPost(model.docID);
      if (success) {
        isReported.value = true;
        AppSnackbar('Başarılı', 'Post şikayet edildi');
      }
    } catch (e) {
      AppSnackbar('Hata', 'Şikayet işlemi başarısız: $e');
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
    // Firestore güncelle
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
    final countSnap = await FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .collection("reshares")
        .count()
        .get();

    // Centralized manager'da da değeri (retryCount) güncelle
    retryCount.value = countSnap.count ?? 0;

    final doc = await FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .collection("reshares")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    yenidenPaylasildiMi.value = doc.exists;
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
      AppSnackbar(
          "Hata", "Gizleme işleminde bir sorun oluştu : sikayet edilme");
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
      AppSnackbar(
          "Hata", "Gizleme işleminde bir sorun oluştu : sikayet edilme");
    }
  }

  Future<void> fetchUserData(String userID) async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .get()
        .then((DocumentSnapshot doc) {
      pfImage.value = doc.get("pfImage");
      nickname.value = doc.get("nickname");
      token.value = doc.get("token");
      fullName.value = "${doc.get("firstName")} ${doc.get("lastName")}";
    });

    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("TakipEdilenler")
        .doc(userID)
        .get()
        .then((doc) {
      takipEdiyorum.value = doc.exists;
      print(FirebaseAuth.instance.currentUser!.uid);
    });
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
        AppSnackbar('Takip Limiti', 'Günlük daha fazla kişi takip edilemiyor.');
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
    final uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .collection("Yorumlar")
        .get()
        .then((snap) {
      comments.value = snap.docs.map((val) => val.id).toList();

      // Kullanıcının yorumlarını filtrele
      userComments.value = snap.docs
          .where((doc) => doc.data()['userID'] == uid)
          .map((val) => val.id)
          .toList();
    });
  }

  Future<void> getReSharedUsers(String docID) async {
    final ref = FirebaseFirestore.instance
        .collection("Posts")
        .doc(docID)
        .collection("reshares");
    ref.get().then((snap) {
      reSharedUsers.value = snap.docs.map((val) => val.id).toList();
    });
  }

  Future<void> getSaved() async {
    final ref = FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .collection("saveds");
    ref.get().then((snap) {
      saved.value = snap.docs.map((val) => val.id).toList();
    });
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
                        ? "Yeniden paylaşmayı geri al"
                        : "Yeniden paylaş",
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
                  const Text(
                    "Alıntıla",
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
                child: const Text(
                  "İptal",
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
      final doc = await FirebaseFirestore.instance
          .collection("Posts")
          .doc(model.docID)
          .collection("YenidenPaylas")
          .doc(uid)
          .get();

      if (doc.exists) {
        final String yeniPostID = doc.get("yeniPostID");

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
    FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .collection("likes")
        .get()
        .then((snap) {
      likes.value = snap.docs.map((val) => val.id).toList();
    });
  }

  Future<void> getUnlikes() async {
    FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .collection("Begenmemeler")
        .get()
        .then((snap) {
      unLikes.value = snap.docs.map((val) => val.id).toList();
    });
  }

  Future<void> getSeens() async {
    FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .collection("viewers")
        .get()
        .then((snap) {
      // Her dokümanda userID bulunduğu için doküman sayısını al
      seens.value =
          snap.docs.map((doc) => doc.data()['userID'] as String).toList();
    });
  }

  Future<void> saveSeeing() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final viewersRef = FirebaseFirestore.instance
          .collection("Posts")
          .doc(model.docID)
          .collection("viewers");

      // Önce bu kullanıcının daha önce görüntüleyip görüntülemediğini kontrol et
      final existingQuery =
          await viewersRef.where("userID", isEqualTo: uid).limit(1).get();

      if (existingQuery.docs.isEmpty) {
        // Auto-generated docID ile yeni görüntüleme kaydı oluştur
        await viewersRef.doc().set({
          "userID": uid,
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
        });
        await PostCountManager.instance.updateStatsCount(model.docID, by: 1);
      }
      // Zaten görüntülemiş, tekrar kayıt yapmaya gerek yok
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
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    try {
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      var written = 0;
      var opCount = 0;
      var batch = FirebaseFirestore.instance.batch();

      Future<void> commitBatch() async {
        if (opCount == 0) return;
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        opCount = 0;
      }

      for (final userDoc in usersSnap.docs) {
        if (userDoc.id == currentUid || !_shouldSendPushToUser(userDoc)) {
          continue;
        }
        final notificationRef =
            userDoc.reference.collection('notifications').doc();
        batch.set(notificationRef, {
          'type': 'posts',
          'fromUserID': currentUid,
          'postID': model.docID,
          if (imageUrl != null) 'imageUrl': imageUrl,
          'adminPush': true,
          'hideInAppInbox': true,
          'timeStamp': nowMs,
          'read': false,
          'title': title,
          'body': body,
        });
        written++;
        opCount++;

        if (opCount >= 400) {
          await commitBatch();
        }
      }

      await commitBatch();
      await FirebaseFirestore.instance
          .collection('adminConfig')
          .doc('admin')
          .collection('pushReports')
          .add({
        'senderUid': currentUid,
        'title': title,
        'body': body,
        'type': 'posts',
        if (imageUrl != null) 'imageUrl': imageUrl,
        'targetCount': written,
        'postID': model.docID,
        'createdAt': FieldValue.serverTimestamp(),
      });
      AppSnackbar('Push', '$written kullaniciya push kuyruga alindi');
    } catch (e) {
      AppSnackbar('Hata', 'Push gonderilemedi: $e');
    }
  }
}
