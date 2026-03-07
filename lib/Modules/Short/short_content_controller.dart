import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';
import '../Agenda/agenda_controller.dart';
import '../Profile/MyProfile/profile_controller.dart';
import '../ShareGrid/share_grid.dart';
import '../../Services/post_delete_service.dart';
import 'short_controller.dart';
import '../../Services/post_interaction_service.dart';

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
  final user = Get.find<FirebaseMyStore>();
  // Kaldırılan deprecated değişkenler:
  // yenidenPaylasildiMi -> isReshared
  // countManager -> PostInteractionService
  // retryCount, statsCount -> lokal RxInt'ler
  StreamSubscription<DocumentSnapshot>? _postDocSub;

  @override
  void onInit() {
    super.onInit();

    // Initialize interaction service
    _interactionService = Get.put(PostInteractionService());

    // Initialize stats from model
    _initializeStats();

    // Initialize other data
    getGizleArsivSikayetEdildi();
    fetchUserData(model.userID);

    // Record view and load user interaction status
    Future.microtask(() {
      _interactionService.recordView(model.docID);
      _loadUserInteractionStatus();
    });

    // Bind listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindPostStatsListener();
    });
  }

  @override
  void onClose() {
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
      final status =
          await _interactionService.getUserInteractionStatus(model.docID);
      isLiked.value = status['liked'] ?? false;
      isSaved.value = status['saved'] ?? false;
      isReshared.value = status['reshared'] ?? false;
      isReported.value = status['reported'] ?? false;
    } catch (e) {
      print('Load user interaction status error: $e');
    }
  }

  // Bind to real-time stats updates
  void _bindPostStatsListener() {
    _postDocSub = FirebaseFirestore.instance
        .collection('Posts')
        .doc(model.docID)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return;

      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      // Update observable values with max(0, value) to prevent negative display
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
  }

  // ========== POST INTERACTION METHODS ==========

  /// Toggle like for the post
  Future<void> toggleLike() async {
    try {
      final newLikeStatus = await _interactionService.toggleLike(model.docID);
      isLiked.value = newLikeStatus;
    } catch (e) {
      AppSnackbar('Hata', 'Beğeni işlemi başarısız: $e');
    }
  }

  Future<void> like() => toggleLike();

  /// Toggle save for the post
  Future<void> toggleSave() async {
    try {
      final newSaveStatus = await _interactionService.toggleSave(model.docID);
      isSaved.value = newSaveStatus;
    } catch (e) {
      AppSnackbar('Hata', 'Kaydetme işlemi başarısız: $e');
    }
  }

  Future<void> save() => toggleSave();

  /// Toggle reshare for the post
  Future<void> toggleReshare() async {
    try {
      final newReshareStatus =
          await _interactionService.toggleReshare(model.docID);
      isReshared.value = newReshareStatus;
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
      AppSnackbar('Hata', 'Yeniden paylaşma işlemi başarısız: $e');
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
        AppSnackbar('Başarılı', 'Post şikayet edildi');
      } else {
        AppSnackbar('Bilgi', 'Bu post daha önce şikayet edilmiş');
      }
    } catch (e) {
      AppSnackbar('Hata', 'Şikayet işlemi başarısız: $e');
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
    // Firestore güncelle
    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .update({
      "arsiv": true,
    });

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

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = false;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.allPosts.indexOf(model);
    if (index10 >= 0) store10.allPosts[index10].arsiv = false;

    arsivlendi.value = true;

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
  }

  Future<void> arsivdenCikart() async {
    // Firestore güncelle
    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .update({
      "arsiv": false,
    });

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

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = false;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.allPosts.indexOf(model);
    if (index10 >= 0) store10.allPosts[index10].arsiv = false;

    arsivlendi.value = false;

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
  }

  Future<void> sil() async {
    await PostDeleteService.instance.softDelete(model);
    silindi.value = true; // UI overlay

    // Yumuşak fade-out
    Future.delayed(const Duration(milliseconds: 2600), () {
      silindiOpacity.value = 0.0;
    });

    // 3 sn sonra overlay'i kaldır ve listeden çıkar
    Future.delayed(const Duration(seconds: 3), () {
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
    try {
      final countSnap = await FirebaseFirestore.instance
          .collection("Posts")
          .doc(model.docID)
          .collection("reshares")
          .count()
          .get();

      // retryCount değerini güncelle (merkezi yöneticide)
      retryCount.value = countSnap.count ?? 0;
    } catch (e) {
      print('[ShortContent] ⚠️ Aggregate query failed for ${model.docID}: $e');
      // Fallback: stats'tan al veya varsayılan değer kullan
      retryCount.value = model.stats.retryCount.toInt();
    }

    // Kaldırıldı: yenidenPaylasildiMi -> isReshared değişkeni artık PostInteractionService'den geliyor
  }

  Future<void> getSeens() async {
    FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .collection("viewers")
        .get()
        .then((snap) {
      // Her dokümanda userID bulunduğu için doküman sayısını al
      // Kaldırıldı: goruntuleme -> viewCount artık real-time güncelleniyor
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
        // Kaldırıldı: countManager -> PostInteractionService.recordView() kullanılıyor
      }
      // Zaten görüntülemiş, tekrar kayıt yapmaya gerek yok
    } catch (_) {}
  }

  Future<void> fetchUserData(String userID) async {
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(userID).get();
    final data = doc.data() ?? const <String, dynamic>{};
    avatarUrl.value = (data["avatarUrl"] ??
            data["avatarUrl"] ??
            data["avatarUrl"] ??
            data["avatarUrl"] ??
            "")
        .toString();
    nickname.value =
        (data["displayName"] ?? data["username"] ?? data["nickname"] ?? "")
            .toString();
    token.value = (data["token"] ?? "").toString();
    fullName.value =
        "${(data["firstName"] ?? "").toString()} ${(data["lastName"] ?? "").toString()}"
            .trim();

    final takipDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("followings")
        .doc(userID)
        .get();

    takipEdiyorum.value = takipDoc.exists;
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
    final myRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('followings')
        .doc(model.userID);

    try {
      final snap = await myRef.get();
      if (snap.exists) {
        // Zaten takip ediyor, işlem yok
        return;
      }
      followLoading.value = true;
      // Takip etmiyorsa, limit dahilinde takip et
      final outcome = await FollowService.toggleFollow(model.userID);
      if (outcome.nowFollowing) {
        takipEdiyorum.value = true;
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
}
