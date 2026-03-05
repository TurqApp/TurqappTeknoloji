import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Models/social_media_model.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';
import '../../Models/posts_model.dart';
import '../../Models/user_post_reference.dart';
import '../../Services/user_post_link_service.dart';
import '../../Services/user_analytics_service.dart';
import 'package:turqappv2/Core/notification_service.dart';
import '../Agenda/AgendaContent/agenda_content_controller.dart';
import '../Profile/SocialMediaLinks/social_media_links_controller.dart';
import '../Story/StoryMaker/story_model.dart';
import '../Story/StoryRow/story_user_model.dart';

class SocialProfileController extends GetxController {
  var totalMarket = 0.obs;
  var totalPosts = 0.obs;
  var totalLikes = 0.obs;
  var totalFollower = 0.obs;
  var totalFollowing = 0.obs;
  var postSelection = 0.obs;

  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;

  final ScrollController scrollController = ScrollController();
  final RxList<SocialMediaModel> socialMediaList = <SocialMediaModel>[].obs;
  final RxList<PostsModel> reshares = <PostsModel>[].obs;
  StreamSubscription<List<UserPostReference>>? _resharesSub;
  final UserPostLinkService _linkService = Get.put(UserPostLinkService());
  final Map<int, GlobalKey> _postKeys = {};
  final user = Get.find<FirebaseMyStore>();
  var showPfImage = false.obs;

  String userID;
  SocialProfileController({required this.userID});
  var nickname = "".obs;
  var pfImage = "".obs;
  var firstName = "".obs;
  var lastName = "".obs;
  var token = "".obs;
  var email = "".obs;
  var rozet = "".obs;
  var bio = "".obs;

  var adres = "".obs;
  var phoneNumber = "".obs;
  var mailIzin = false.obs;
  var aramaIzin = false.obs;
  var ban = false.obs;
  var gizliHesap = false.obs;
  var hesapOnayi = false.obs;
  var meslek = "".obs;
  var blockedUsers = <String>[].obs;
  var complatedCheck = false.obs;
  var takipEdiyorum = false.obs;
  var followLoading = false.obs;

  final RxList<PostsModel> allPosts = <PostsModel>[].obs;

  final RxList<PostsModel> photos = <PostsModel>[].obs;
  final RxList<PostsModel> scheduledPosts = <PostsModel>[].obs;

  final RxBool isLoadingPosts = false.obs;
  final RxBool hasMorePosts = true.obs;
  DocumentSnapshot? lastPostDoc;
  final int pageSize = 12;

  final RxBool isLoadingPhoto = false.obs;
  final RxBool hasMorePhoto = true.obs;
  DocumentSnapshot? lastPostDocPhoto;
  final int pageSizePhoto = 12;

  // Scheduled (İz Bırak)
  final RxBool isLoadingScheduled = false.obs;
  final RxBool hasMoreScheduled = true.obs;
  DocumentSnapshot? lastScheduledDoc;
  final int pageSizeScheduled = 12;
  StoryUserModel? storyUserModel;
  // Yukarı butonu
  final RxBool showScrollToTop = false.obs;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  @override
  void onInit() {
    UserAnalyticsService.instance.trackFeatureUsage('social_profile_open');
    getUserData();
    getCounters();
    getUserStoryUserModelAndPrint(userID);
    getSocialMediaLinks();
    isFollowingCheck();
    _logProfileVisitIfNeeded();
    super.onInit();
    getPosts(initial: true);
    getPhotos(initial: true);
    getReshares();
    fetchScheduledPosts(initial: true);
  }

  Future<void> _logProfileVisitIfNeeded() async {
    try {
      final current = FirebaseAuth.instance.currentUser?.uid;
      if (current == null) return;
      if (current == userID) return; // kendi profili
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .collection('ProfileVisits')
          .add({
        'visitorId': current,
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Profile visit log error: $e');
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    _userDocSub?.cancel();
    _resharesSub?.cancel();
    super.onClose();
  }

  Future<void> getCounters() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userID)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final followerCounter =
            (data?['counterOfFollowers'] as num?)?.toInt() ??
                (data?['followersCount'] as num?)?.toInt() ??
                (data?['takipci'] as num?)?.toInt() ??
                (data?['followerCount'] as num?)?.toInt() ??
                0;
        final followingCounter =
            (data?['counterOfFollowings'] as num?)?.toInt() ??
                (data?['followingCount'] as num?)?.toInt() ??
                (data?['takip'] as num?)?.toInt() ??
                (data?['followCount'] as num?)?.toInt() ??
                0;

        totalFollower.value = followerCounter;
        totalFollowing.value = followingCounter;
      }

      // Counter alanı sıfırlanmış/bozuksa, gerçek ilişki koleksiyonlarından yeniden say.
      if (totalFollower.value == 0 || totalFollowing.value == 0) {
        final followersAgg = await FirebaseFirestore.instance
            .collection("users")
            .doc(userID)
            .collection("Takipciler")
            .count()
            .get();
        final followingAgg = await FirebaseFirestore.instance
            .collection("users")
            .doc(userID)
            .collection("TakipEdilenler")
            .count()
            .get();

        final followers = followersAgg.count ?? 0;
        final followings = followingAgg.count ?? 0;
        totalFollower.value = followers;
        totalFollowing.value = followings;
      }
    } catch (e) {
      print("⚠️ SocialProfile getCounters error: $e");
    }
  }

  Future<void> getReshares() async {
    _resharesSub?.cancel();
    _resharesSub = _linkService.listenResharedPosts(userID).listen((refs) {
      _hydrateReshares(refs);
    });
  }

  Future<void> _hydrateReshares(List<UserPostReference> refs) async {
    try {
      final posts = await _linkService.fetchResharedPosts(userID, refs);
      reshares.value = posts;
    } catch (e) {
      print('SocialProfileController hydrate reshares error: $e');
    }
  }

  Future<void> getPosts({bool initial = false}) async {
    if (isLoadingPosts.value || !hasMorePosts.value) return;
    isLoadingPosts.value = true;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    Query query = FirebaseFirestore.instance
        .collection("Posts")
        .where("flood", isEqualTo: false)
        .where("userID", isEqualTo: userID)
        .where("arsiv", isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: nowMs)
        .orderBy("timeStamp", descending: true)
        .limit(pageSize);

    if (!initial && lastPostDoc != null) {
      query = query.startAfterDocument(lastPostDoc!);
    }

    final snap = await PerformanceService.traceFeedLoad(
      () => query.get(),
      postCount: allPosts.length,
      feedMode: 'profile_posts',
    );
    final posts = snap.docs
        .map((doc) =>
            PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((p) => (p.timeStamp) <= nowMs)
        .where((p) => p.deletedPost != true)
        .toList();

    if (initial) {
      allPosts.value = posts;
    } else {
      allPosts.addAll(posts);
    }

    if (snap.docs.isNotEmpty) lastPostDoc = snap.docs.last;
    if (posts.length < pageSize) hasMorePosts.value = false;

    isLoadingPosts.value = false;
  }

  Future<void> getPhotos({bool initial = false}) async {
    if (isLoadingPhoto.value || !hasMorePhoto.value) return;
    isLoadingPhoto.value = true;

    final nowMs2 = DateTime.now().millisecondsSinceEpoch;
    Query query = FirebaseFirestore.instance
        .collection("Posts")
        .where("flood", isEqualTo: false)
        .where("video", isEqualTo: "")
        .where("userID", isEqualTo: userID)
        .where("arsiv", isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: nowMs2)
        .orderBy("timeStamp", descending: true)
        .limit(pageSizePhoto);

    if (!initial && lastPostDocPhoto != null) {
      query = query.startAfterDocument(lastPostDocPhoto!);
    }

    final snap = await PerformanceService.traceFeedLoad(
      () => query.get(),
      postCount: photos.length,
      feedMode: 'profile_photos',
    );
    final posts = snap.docs
        .map((doc) =>
            PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((p) => (p.timeStamp) <= nowMs2)
        .where((p) => p.deletedPost != true)
        .toList();

    if (initial) {
      photos.value = posts;
    } else {
      photos.addAll(posts);
    }

    if (snap.docs.isNotEmpty) lastPostDocPhoto = snap.docs.last;
    if (posts.length < pageSizePhoto) hasMorePhoto.value = false;

    isLoadingPhoto.value = false;
  }

  Future<void> isFollowingCheck() async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("TakipEdilenler")
        .doc(userID)
        .get()
        .then((doc) {
      takipEdiyorum.value = doc.exists;
      complatedCheck.value = true;
    });
  }

  Future<void> setPostSelection(int index) async {
    postSelection.value = index;
    UserAnalyticsService.instance
        .trackFeatureUsage('social_profile_tab_$index');
    if (index == 5) {
      if (scheduledPosts.isEmpty || lastScheduledDoc == null) {
        await fetchScheduledPosts(initial: true);
      }
    }
  }

  GlobalKey getPostKey(int index) {
    return _postKeys.putIfAbsent(index, () => GlobalObjectKey('post_$index'));
  }

  Future<void> fetchScheduledPosts({bool initial = false}) async {
    if (isLoadingScheduled.value || !hasMoreScheduled.value) return;
    isLoadingScheduled.value = true;
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      Query query = FirebaseFirestore.instance
          .collection('Posts')
          .where('userID', isEqualTo: userID)
          .where('arsiv', isEqualTo: false)
          .where('flood', isEqualTo: false)
          .where('timeStamp', isGreaterThan: nowMs)
          .orderBy('timeStamp')
          .limit(pageSizeScheduled);

      if (!initial && lastScheduledDoc != null) {
        query = query.startAfterDocument(lastScheduledDoc!);
      }

      QuerySnapshot snap;
      try {
        snap = await PerformanceService.traceFeedLoad(
          () => query.get(),
          postCount: scheduledPosts.length,
          feedMode: 'profile_scheduled',
        );
      } catch (e) {
        final isIndexError = e is FirebaseException
            ? e.code == 'failed-precondition'
            : e.toString().contains('requires an index');
        if (!isIndexError) rethrow;

        Query fallback = FirebaseFirestore.instance
            .collection('Posts')
            .where('timeStamp', isGreaterThan: nowMs)
            .orderBy('timeStamp')
            .limit(pageSizeScheduled);
        if (!initial && lastScheduledDoc != null) {
          fallback = fallback.startAfterDocument(lastScheduledDoc!);
        }
        snap = await PerformanceService.traceFeedLoad(
          () => fallback.get(),
          postCount: scheduledPosts.length,
          feedMode: 'profile_scheduled_fallback',
        );
      }
      final posts = snap.docs
          .map(
              (d) => PostsModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .where((p) => p.userID == userID && !p.arsiv && !p.flood)
          .toList();

      if (initial) {
        scheduledPosts.value = posts;
      } else {
        scheduledPosts.addAll(posts);
      }

      if (snap.docs.isNotEmpty) lastScheduledDoc = snap.docs.last;
      if (snap.docs.length < pageSizeScheduled) hasMoreScheduled.value = false;
    } catch (e) {
      print('fetchScheduledPosts(SocialProfile) error: $e');
    }
    isLoadingScheduled.value = false;
  }

  Future<void> refreshAll() async {
    try {
      // Temel kullanıcı verileri ve sayfalar
      await getCounters();
      await getUserData();
      await getSocialMediaLinks();

      // Postlar
      lastPostDoc = null;
      hasMorePosts.value = true;
      allPosts.clear();

      // Fotoğraflar
      lastPostDocPhoto = null;
      hasMorePhoto.value = true;
      photos.clear();

      // Reshare
      reshares.clear();

      // Scheduled
      lastScheduledDoc = null;
      hasMoreScheduled.value = true;
      scheduledPosts.clear();

      await Future.wait([
        getPosts(initial: true),
        getPhotos(initial: true),
        getReshares(),
        fetchScheduledPosts(initial: true),
      ]);
    } catch (e) {
      print('SocialProfile.refreshAll error: $e');
    }
  }

  Future<void> disposeAgendaContentController(String docID) async {
    if (Get.isRegistered<AgendaContentController>(tag: docID)) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
      print("Disposed AgendaContentController for $docID");
    }
  }

  Future<void> getSocialMediaLinks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .collection("SosyalMedyaLinkleri")
        .orderBy("sira")
        .get();

    final list = snapshot.docs
        .map((doc) => SocialMediaModel.fromFirestore(doc))
        .toList();

    list.sort((a, b) =>
        a.sira.compareTo(b.sira)); // opsiyonel, sıralama zaten varsa gerek yok

    socialMediaList.value = list; // observable list ise
  }

  Future<void> showSocialMediaLinkDelete(String docID) async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Bağlantıyı Kaldır ?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Bu bağlantıyı kaldırmak istediğinizden emin misiniz",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Vazgeç",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Get.back();
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(userID)
                          .collection("SosyalMedyaLinkleri")
                          .doc(docID)
                          .delete();

                      final links = Get.find<SocialMediaController>();
                      links.getData();
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Text(
                        "Kaldır",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> getUserData() async {
    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .snapshots()
        .listen((doc) {
      nickname.value = doc.get("nickname") ?? "";
      pfImage.value = doc.get("pfImage");
      firstName.value = doc.get("firstName");
      lastName.value = doc.get("lastName");
      email.value = doc.get("email");
      rozet.value = doc.get("rozet");
      bio.value = doc.get("bio");
      adres.value = doc.get("adres");
      token.value = doc.get("token");
      phoneNumber.value = doc.get("phoneNumber");
      // İletişim izinleri
      try {
        mailIzin.value = (doc.data().toString().contains('mailIzin'))
            ? (doc.get("mailIzin") ?? false)
            : false;
      } catch (_) {
        mailIzin.value = false;
      }
      try {
        aramaIzin.value = (doc.data().toString().contains('aramaIzin'))
            ? (doc.get("aramaIzin") ?? false)
            : false;
      } catch (_) {
        aramaIzin.value = false;
      }
      ban.value = doc.get("ban");
      gizliHesap.value = doc.get("gizliHesap");
      hesapOnayi.value = doc.get("hesapOnayi");
      meslek.value = doc.get("meslekKategori");
      blockedUsers.value = List.from(doc.get("blockedUsers"));
      totalMarket.value = 0; // when end of the market coding
      // Gönderi ve beğeni sayısı kullanıcı doc'undan dinamik
      totalPosts.value = doc.get("counterOfPosts") ?? 0;
      totalLikes.value = doc.get("counterOfLikes") ?? 0;
    });
  }

  Future<void> toggleFollowStatus() async {
    if (followLoading.value) return;
    final bool wasFollowing = takipEdiyorum.value;
    // Optimistic UI update
    takipEdiyorum.value = !wasFollowing;
    followLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      // Reconcile with server outcome
      takipEdiyorum.value = outcome.nowFollowing;

      // ⚠️ CRITICAL FIX: Update follower count after follow/unfollow
      if (outcome.nowFollowing && !wasFollowing) {
        // Followed - increase follower count
        totalFollower.value++;
        NotificationService.instance.sendNotification(
          token: token.value,
          title: user.nickname.value,
          body: "seni takip etmeye başladı",
          docID: userID,
          type: "User",
        );
      } else if (!outcome.nowFollowing && wasFollowing) {
        // Unfollowed - decrease follower count
        totalFollower.value--;
      }

      if (outcome.limitReached) {
        AppSnackbar('Takip Limiti', 'Günlük daha fazla kişi takip edilemiyor.');
      }
    } catch (e) {
      // Revert on error
      takipEdiyorum.value = wasFollowing;
      print("Bir hata oluştu: $e");
    } finally {
      followLoading.value = false;
    }
  }

  Future<void> block() async {
    await noYesAlert(
      title: "Engelle",
      message: "Bu kullanıcıyı engellemek istediğinizden emin misiniz?",
      cancelText: "Vazgeç",
      yesText: "Engelle",
      onYesPressed: () async {
        final currentUid = FirebaseAuth.instance.currentUser!.uid;

        // 1) Engellenenler listesine ekle
        await FirebaseFirestore.instance
            .collection("users")
            .doc(currentUid)
            .update({
          "blockedUsers": FieldValue.arrayUnion([userID])
        });

        // 2) Takip ilişkilerini temizle (batch ile topluca)
        final batch = FirebaseFirestore.instance.batch();
        final meDoc =
            FirebaseFirestore.instance.collection("users").doc(currentUid);
        final otherDoc =
            FirebaseFirestore.instance.collection("users").doc(userID);

        batch.delete(meDoc.collection("TakipEdilenler").doc(userID));
        batch.delete(meDoc.collection("Takipciler").doc(userID));
        batch.delete(otherDoc.collection("TakipEdilenler").doc(currentUid));
        batch.delete(otherDoc.collection("Takipciler").doc(currentUid));

        await batch.commit();

        // 3) Veri yenileme
        user.getUserData();
        getUserData();
        isFollowingCheck();
      },
    );
  }

  Future<void> unblock() async {
    await noYesAlert(
      title: "Engeli Kaldır",
      message: "Engeli kaldırmak istediğinizden emin misiniz?",
      cancelText: "Vazgeç",
      yesText: "Engeli Kaldır",
      onYesPressed: () async {
        // 1) Engellenenler listesinden kaldır
        await FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          "blockedUsers": FieldValue.arrayRemove([userID])
        });
        // 2) Verileri yenile
        user.getUserData();
        getUserData();
        isFollowingCheck();
      },
    );
  }

  Future<void> getUserStoryUserModelAndPrint(String userId) async {
    // Stories koleksiyonunda ilgili userId'ye ait tüm story'leri topla
    final snap = await FirebaseFirestore.instance
        .collection("stories")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .get();

    if (snap.docs.isEmpty) {
      print("Kullanıcıya ait hiç hikaye yok.");
      return;
    }

    List<StoryModel> stories = snap.docs
        .where((doc) {
          final data = doc.data();
          return (data['deleted'] ?? false) != true;
        })
        .map((doc) => StoryModel.fromDoc(doc))
        .toList();

    // Kullanıcı bilgisini çek
    final userSnap =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();
    if (!userSnap.exists) {
      print("Kullanıcı bulunamadı.");
      return;
    }

    final data = userSnap.data()!;
    final userModel = StoryUserModel(
      nickname:
          data['displayName'] ?? data['username'] ?? data['nickname'] ?? "",
      pfImage: data['avatarUrl'] ?? data['pfImage'] ?? data['photoURL'] ?? "",
      fullName: "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}",
      userID: userId,
      stories: stories,
    );

    print("Kullanıcı StoryUserModel: $userModel");
    storyUserModel = userModel;
    print(
        "Nickname: ${userModel.nickname}, Story Sayısı: ${userModel.stories.length}");
  }
}
