import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/profile_posts_cache_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_links_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../Models/posts_model.dart';
import '../../../Models/user_post_reference.dart';
import '../../../Services/user_post_link_service.dart';
import '../../Agenda/AgendaContent/agenda_content_controller.dart';

class ProfileController extends GetxController {
  // 🎯 Using CurrentUserService for optimized user data access
  final userService = CurrentUserService.instance;
  // Aktif oturum kullanıcısını izleyip veri setlerini dinamik yenilemek için
  String? _activeUid;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _counterSub;
  final ProfilePostsCacheService _postsCache = ProfilePostsCacheService();
  Timer? _persistCacheTimer;
  Worker? _allPostsWorker;
  Worker? _photosWorker;
  Worker? _videosWorker;
  Worker? _resharesWorker;
  Worker? _scheduledWorker;
  var postSelection = 0.obs;

  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;

  var followerCount = 0.obs;
  var followingCount = 0.obs;

  final RxList<PostsModel> allPosts = <PostsModel>[].obs;
  DocumentSnapshot? lastPostDoc;
  bool hasMorePosts = true;
  final int postLimit = 10;
  bool isLoadingMore = false;

  // İz Bırak (gelecek tarihli) gönderiler
  final RxList<PostsModel> scheduledPosts = <PostsModel>[].obs;
  DocumentSnapshot? lastScheduledDoc;
  bool hasMoreScheduled = true;
  final int scheduledLimit = 10;
  bool isLoadingScheduled = false;

  final RxList<PostsModel> photos = <PostsModel>[].obs;
  DocumentSnapshot? lastPostDocPhotos;
  bool hasMorePostsPhotos = true;
  final int postLimitPhotos = 10;
  bool isLoadingMorePhotos = false;

  final RxList<PostsModel> videos = <PostsModel>[].obs;
  DocumentSnapshot? lastPostDocVideos;
  bool hasMorePostsVideos = true;
  final int postLimitVideos = 10;
  bool isLoadingMoreVideos = false;

  final RxList<PostsModel> reshares = <PostsModel>[].obs;
  StreamSubscription<List<UserPostReference>>? _resharesSub;
  final UserPostLinkService _linkService = Get.put(UserPostLinkService());
  List<UserPostReference> _latestReshareRefs = const [];
  final Map<int, GlobalKey> _postKeys = {};

  var pausetheall = false.obs;
  final RxBool showScrollToTop = false.obs;
  final ScrollController scrollController = ScrollController();
  var showPfImage = false.obs;
  static const String _bucketAll = 'all';
  static const String _bucketPhotos = 'photos';
  static const String _bucketVideos = 'videos';
  static const String _bucketReshares = 'reshares';
  static const String _bucketScheduled = 'scheduled';

  @override
  void onInit() {
    super.onInit();
    // Aktif kullanıcıyı kaydet ve auth değişimini dinle
    _activeUid = FirebaseAuth.instance.currentUser?.uid;
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);

    _bindCacheWorkers();
    unawaited(_bootstrapProfileData());

    scrollController.addListener(() {
      if (scrollController.offset > 500) {
        showScrollToTop.value = true;
      } else {
        showScrollToTop.value = false;
      }
    });
  }

  @override
  void onClose() {
    // Bellek sızıntısını önlemek için dinleyiciyi kapat
    _authSub?.cancel();
    _resharesSub?.cancel();
    _counterSub?.cancel();
    _persistCacheTimer?.cancel();
    _allPostsWorker?.dispose();
    _photosWorker?.dispose();
    _videosWorker?.dispose();
    _resharesWorker?.dispose();
    _scheduledWorker?.dispose();
    super.onClose();
  }

  Future<void> _bootstrapProfileData() async {
    await _restoreCachedListsForActiveUser();
    getCounters();
    _listenToCounterChanges();
    _bindResharesRealtime();
    fetchPosts(isInitial: true);
    fetchPhotos(isInitial: true);
    fetchVideos(isInitial: true);
    getReshares();
    fetchScheduledPosts(isInitial: true);
  }

  void _bindCacheWorkers() {
    _allPostsWorker = ever(allPosts, (_) => _schedulePersistPostCaches());
    _photosWorker = ever(photos, (_) => _schedulePersistPostCaches());
    _videosWorker = ever(videos, (_) => _schedulePersistPostCaches());
    _resharesWorker = ever(reshares, (_) => _schedulePersistPostCaches());
    _scheduledWorker =
        ever(scheduledPosts, (_) => _schedulePersistPostCaches());
  }

  void _schedulePersistPostCaches() {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    _persistCacheTimer?.cancel();
    _persistCacheTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistPostCaches(uid));
    });
  }

  Future<void> _persistPostCaches(String uid) async {
    await Future.wait([
      _postsCache.writeBucket(uid: uid, bucket: _bucketAll, posts: allPosts),
      _postsCache.writeBucket(uid: uid, bucket: _bucketPhotos, posts: photos),
      _postsCache.writeBucket(uid: uid, bucket: _bucketVideos, posts: videos),
      _postsCache.writeBucket(
          uid: uid, bucket: _bucketReshares, posts: reshares),
      _postsCache.writeBucket(
          uid: uid, bucket: _bucketScheduled, posts: scheduledPosts),
    ]);
  }

  Future<void> _restoreCachedListsForActiveUser() async {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final loaded = await Future.wait([
      _postsCache.readBucket(uid: uid, bucket: _bucketAll),
      _postsCache.readBucket(uid: uid, bucket: _bucketPhotos),
      _postsCache.readBucket(uid: uid, bucket: _bucketVideos),
      _postsCache.readBucket(uid: uid, bucket: _bucketReshares),
      _postsCache.readBucket(uid: uid, bucket: _bucketScheduled),
    ]);

    final loadedAll = loaded[0];
    final loadedPhotos = loaded[1];
    final loadedVideos = loaded[2];
    final loadedReshares = loaded[3];
    final loadedScheduled = loaded[4];

    if (loadedAll.isNotEmpty) allPosts.assignAll(loadedAll);
    if (loadedPhotos.isNotEmpty) photos.assignAll(loadedPhotos);
    if (loadedVideos.isNotEmpty) videos.assignAll(loadedVideos);
    if (loadedReshares.isNotEmpty) reshares.assignAll(loadedReshares);
    if (loadedScheduled.isNotEmpty) scheduledPosts.assignAll(loadedScheduled);
    unawaited(_warmProfileSurfaceCache());
  }

  Future<void> _warmProfileSurfaceCache() async {
    final urls = <String>{
      userService.avatarUrl,
    };

    void collectFrom(Iterable<PostsModel> posts) {
      for (final post in posts.take(18)) {
        if (post.thumbnail.trim().isNotEmpty) {
          urls.add(post.thumbnail.trim());
        }
        if (post.authorAvatarUrl.trim().isNotEmpty) {
          urls.add(post.authorAvatarUrl.trim());
        }
        for (final img in post.img.take(2)) {
          final normalized = img.trim();
          if (normalized.isNotEmpty) {
            urls.add(normalized);
          }
        }
      }
    }

    collectFrom(allPosts);
    collectFrom(photos);
    collectFrom(videos);
    collectFrom(scheduledPosts);

    for (final url in urls.where((e) => e.isNotEmpty).take(32)) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(url);
      } catch (_) {}
    }
  }

  void _clearInMemoryPostLists() {
    allPosts.clear();
    photos.clear();
    videos.clear();
    reshares.clear();
    scheduledPosts.clear();
  }

  void _listenToCounterChanges() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _counterSub?.cancel();

    // ⚠️ REAL-TIME FIX: Listen to user document changes for instant counter updates
    _counterSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          followerCount.value = (data['counterOfFollowers'] as num?)?.toInt() ??
              (data['followersCount'] as num?)?.toInt() ??
              (data['takipci'] as num?)?.toInt() ??
              (data['followerCount'] as num?)?.toInt() ??
              0;
          followingCount.value =
              (data['counterOfFollowings'] as num?)?.toInt() ??
                  (data['followingCount'] as num?)?.toInt() ??
                  (data['takip'] as num?)?.toInt() ??
                  (data['followCount'] as num?)?.toInt() ??
                  0;
        }
      }
    });
  }

  void _bindResharesRealtime() {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _resharesSub?.cancel();
    _resharesSub = _linkService.listenResharedPosts(uid).listen((refs) {
      _latestReshareRefs = refs;
      _hydrateReshares(uid, refs);
    });
  }

  Future<void> _hydrateReshares(
      String uid, List<UserPostReference> refs) async {
    try {
      final posts = await _linkService.fetchResharedPosts(uid, refs);
      if (posts.isNotEmpty || reshares.isEmpty) {
        // fetchResharedPosts bazı akışlarda unmodifiable liste döndürebiliyor.
        // RxList'e modifiable kopya atarak insert/remove hatalarını engelle.
        reshares.assignAll(List<PostsModel>.from(posts));
      }
    } catch (e) {
      print('ProfileController hydrate reshares error: $e');
    }
  }

  int reshareSortTimestampFor(String postId, int fallback) {
    for (final ref in _latestReshareRefs) {
      if (ref.postId == postId) return ref.timeStamp.toInt();
    }
    return fallback;
  }

  void _onAuthChanged(User? user) {
    final newUid = user?.uid;
    // Oturum kapandıysa tüm verileri sıfırla
    if (newUid == null) {
      _activeUid = null;
      _counterSub?.cancel();
      _counterSub = null;
      // ⚠️ CRITICAL FIX: Safely clear RxLists
      try {
        allPosts.clear();
      } catch (e) {
        allPosts.value = [];
      }
      try {
        photos.clear();
      } catch (e) {
        photos.value = [];
      }
      try {
        videos.clear();
      } catch (e) {
        videos.value = [];
      }
      try {
        reshares.clear();
      } catch (e) {
        reshares.value = [];
      }
      try {
        scheduledPosts.clear();
      } catch (e) {
        scheduledPosts.value = [];
      }

      followerCount.value = 0;
      followingCount.value = 0;
      // Pagination göstergelerini de sıfırla
      lastPostDoc = null;
      lastPostDocPhotos = null;
      lastPostDocVideos = null;
      lastScheduledDoc = null;
      hasMorePosts = true;
      hasMorePostsPhotos = true;
      hasMorePostsVideos = true;
      hasMoreScheduled = true;
      return;
    }

    // Kullanıcı değiştiyse (logout/login) verileri taze çek
    if (newUid != _activeUid) {
      _activeUid = newUid;
      _clearInMemoryPostLists();
      _listenToCounterChanges();
      unawaited(_restoreCachedListsForActiveUser());
      refreshAll();
    }
  }

  Future<void> getCounters() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (userDoc.exists) {
        final data = userDoc.data();
        followerCount.value = (data?['counterOfFollowers'] as num?)?.toInt() ??
            (data?['followersCount'] as num?)?.toInt() ??
            (data?['takipci'] as num?)?.toInt() ??
            (data?['followerCount'] as num?)?.toInt() ??
            0;
        followingCount.value =
            (data?['counterOfFollowings'] as num?)?.toInt() ??
                (data?['followingCount'] as num?)?.toInt() ??
                (data?['takip'] as num?)?.toInt() ??
                (data?['followCount'] as num?)?.toInt() ??
                0;
      }

      if (followerCount.value == 0 || followingCount.value == 0) {
        final followersAgg = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("followers")
            .count()
            .get();
        final followingAgg = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("followings")
            .count()
            .get();

        final followers = followersAgg.count ?? 0;
        final followings = followingAgg.count ?? 0;
        followerCount.value = followers;
        followingCount.value = followings;
      }
    } catch (e) {
      print("⚠️ getCounters error: $e");
    }
  }

  void setPostSelection(int index) {
    postSelection.value = index;
    if (index == 5) {
      // Ayak izi sekmesine geçildiğinde liste boşsa veya ilk kez ise çek
      if (scheduledPosts.isEmpty || lastScheduledDoc == null) {
        fetchScheduledPosts(isInitial: true);
      }
    }
  }

  GlobalKey getPostKey(int index) {
    return _postKeys.putIfAbsent(index, () => GlobalObjectKey('post_$index'));
  }

  void disposeAgendaContentController(String docID) {
    if (Get.isRegistered<AgendaContentController>(tag: docID)) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
      print("Disposed AgendaContentController for $docID");
    }
  }

  Future<void> fetchPosts({bool isInitial = false, bool force = false}) async {
    if (isLoadingMore && !force) return;
    if (!isInitial && (!hasMorePosts || lastPostDoc == null)) return;

    isLoadingMore = true;
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      var query = FirebaseFirestore.instance
          .collection("Posts")
          .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where("arsiv", isEqualTo: false)
          .where("flood", isEqualTo: false)
          .where('timeStamp', isLessThanOrEqualTo: nowMs)
          .orderBy("timeStamp", descending: true)
          .limit(postLimit);

      if (!isInitial && lastPostDoc != null) {
        query = query.startAfterDocument(lastPostDoc!);
      }

      final snapshot =
          await query.get(const GetOptions(source: Source.serverAndCache));
      final newPosts = snapshot.docs.map((doc) {
        final data = doc.data();
        final model = PostsModel.fromMap(data, doc.id);
        // Gelecek tarihli gönderileri normal akıştan çıkar (timeStamp'a göre)
        if (model.timeStamp > nowMs) {
          return null;
        }
        return model;
      }).toList();

      final filtered = newPosts
          .whereType<PostsModel>()
          .where((p) => p.deletedPost != true)
          .toList();
      if (isInitial) {
        if (force && filtered.isEmpty && allPosts.isNotEmpty) {
          // Refresh sırasında boş sonuç gelirse mevcut görünür listeyi koru.
        } else {
          allPosts.assignAll(filtered);
          unawaited(_warmProfileSurfaceCache());
        }
      } else {
        allPosts.addAll(filtered);
        unawaited(_warmProfileSurfaceCache());
      }

      if (snapshot.docs.isNotEmpty) {
        lastPostDoc = snapshot.docs.last;
      }
      if (snapshot.docs.length < postLimit) {
        hasMorePosts = false;
      }
    } catch (e) {
      print("fetchPosts error: $e");
    }
    isLoadingMore = false;
  }

  Future<void> fetchPhotos({bool isInitial = false, bool force = false}) async {
    if (isLoadingMorePhotos && !force) return;
    if (!isInitial && (!hasMorePostsPhotos || lastPostDocPhotos == null)) {
      return;
    }

    isLoadingMorePhotos = true;
    try {
      final nowMsPhotos = DateTime.now().millisecondsSinceEpoch;
      var query = FirebaseFirestore.instance
          .collection("Posts")
          .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where("arsiv", isEqualTo: false)
          .where("video", isEqualTo: "")
          .where("flood", isEqualTo: false)
          .where('timeStamp', isLessThanOrEqualTo: nowMsPhotos)
          .orderBy("timeStamp", descending: true)
          .limit(postLimitPhotos);

      if (!isInitial && lastPostDocPhotos != null) {
        query = query.startAfterDocument(lastPostDocPhotos!);
      }

      final snapshot =
          await query.get(const GetOptions(source: Source.serverAndCache));
      final newPosts = snapshot.docs.map((doc) {
        final data = doc.data();
        final model = PostsModel.fromMap(data, doc.id);
        if (model.timeStamp > nowMsPhotos) {
          return null;
        }
        return model;
      }).toList();

      final filtered = newPosts
          .whereType<PostsModel>()
          .where((p) => p.deletedPost != true)
          .toList();
      if (isInitial) {
        if (force && filtered.isEmpty && photos.isNotEmpty) {
          // Refresh sırasında boş sonuç gelirse mevcut görünür listeyi koru.
        } else {
          photos.assignAll(filtered);
          unawaited(_warmProfileSurfaceCache());
        }
      } else {
        photos.addAll(filtered);
        unawaited(_warmProfileSurfaceCache());
      }

      if (snapshot.docs.isNotEmpty) {
        lastPostDocPhotos = snapshot.docs.last;
      }
      if (snapshot.docs.length < postLimitPhotos) {
        hasMorePostsPhotos = false;
      }
    } catch (e) {
      print("fetchphotos error: $e");
    }
    isLoadingMorePhotos = false;
  }

  Future<void> fetchVideos({bool isInitial = false, bool force = false}) async {
    if (isLoadingMoreVideos && !force) return;
    if (!isInitial && (!hasMorePostsVideos || lastPostDocVideos == null)) {
      return;
    }

    isLoadingMoreVideos = true;
    try {
      final nowMsVideos = DateTime.now().millisecondsSinceEpoch;
      var query = FirebaseFirestore.instance
          .collection("Posts")
          .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where("arsiv", isEqualTo: false)
          .where("flood", isEqualTo: false)
          .where("hlsStatus", isEqualTo: "ready")
          .where('timeStamp', isLessThanOrEqualTo: nowMsVideos)
          .orderBy("timeStamp", descending: true)
          .limit(postLimitVideos);

      if (!isInitial && lastPostDocVideos != null) {
        query = query.startAfterDocument(lastPostDocVideos!);
      }

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot =
            await query.get(const GetOptions(source: Source.serverAndCache));
      } catch (e) {
        final isIndexError = e is FirebaseException
            ? e.code == 'failed-precondition'
            : e.toString().contains('requires an index');
        if (!isIndexError) rethrow;

        var fallback = FirebaseFirestore.instance
            .collection("Posts")
            .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .where("arsiv", isEqualTo: false)
            .where("flood", isEqualTo: false)
            .where('timeStamp', isLessThanOrEqualTo: nowMsVideos)
            .orderBy("timeStamp", descending: true)
            .limit(postLimitVideos);

        if (!isInitial && lastPostDocVideos != null) {
          fallback = fallback.startAfterDocument(lastPostDocVideos!);
        }
        snapshot = await fallback.get(
          const GetOptions(source: Source.serverAndCache),
        );
      }

      final newPosts = snapshot.docs.map((doc) {
        final data = doc.data();
        final model = PostsModel.fromMap(data, doc.id);
        return model;
      }).toList();

      final filtered = newPosts
          .whereType<PostsModel>()
          .where((p) => p.deletedPost != true)
          .where((p) => p.hasPlayableVideo)
          .toList();
      if (isInitial) {
        if (force && filtered.isEmpty && videos.isNotEmpty) {
          // Refresh sırasında boş sonuç gelirse mevcut görünür listeyi koru.
        } else {
          videos.assignAll(filtered);
          unawaited(_warmProfileSurfaceCache());
        }
      } else {
        videos.addAll(filtered);
        unawaited(_warmProfileSurfaceCache());
      }

      if (snapshot.docs.isNotEmpty) {
        lastPostDocVideos = snapshot.docs.last;
      }
      if (snapshot.docs.length < postLimitVideos) {
        hasMorePostsVideos = false;
      }
    } catch (e) {
      print("fetchvideis error: $e");
    }
    isLoadingMoreVideos = false;
  }

  Future<void> fetchScheduledPosts(
      {bool isInitial = false, bool force = false}) async {
    if (isLoadingScheduled && !force) return;
    if (!isInitial && (!hasMoreScheduled || lastScheduledDoc == null)) return;

    isLoadingScheduled = true;
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final uid = FirebaseAuth.instance.currentUser!.uid;
      var query = FirebaseFirestore.instance
          .collection("Posts")
          .where("userID", isEqualTo: uid)
          .where("arsiv", isEqualTo: false)
          .where("flood", isEqualTo: false)
          .where('timeStamp', isGreaterThan: nowMs)
          .orderBy('timeStamp')
          .limit(scheduledLimit);

      if (!isInitial && lastScheduledDoc != null) {
        query = query.startAfterDocument(lastScheduledDoc!);
      }

      final snapshot =
          await query.get(const GetOptions(source: Source.serverAndCache));
      final newPosts = snapshot.docs
          .map((d) => PostsModel.fromMap(d.data(), d.id))
          .where((p) => p.deletedPost != true)
          .toList();

      if (isInitial) {
        if (force && newPosts.isEmpty && scheduledPosts.isNotEmpty) {
          // Refresh sırasında boş sonuç gelirse mevcut görünür listeyi koru.
        } else {
          scheduledPosts.assignAll(newPosts);
          unawaited(_warmProfileSurfaceCache());
        }
      } else {
        scheduledPosts.addAll(newPosts);
        unawaited(_warmProfileSurfaceCache());
      }

      if (snapshot.docs.isNotEmpty) {
        lastScheduledDoc = snapshot.docs.last;
      }
      if (snapshot.docs.length < scheduledLimit) {
        hasMoreScheduled = false;
      }
    } catch (e) {
      print('fetchScheduledPosts error (primary query): $e');
      // Fallback: tekrar dene (aynı query). Firestore index sorunlarında
      // kullanıcıya işlevsellik sağlamak adına asgari alanlarla çekildi.
      try {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final snapshot = await FirebaseFirestore.instance
            .collection('Posts')
            .where('timeStamp', isGreaterThan: nowMs)
            .orderBy('timeStamp')
            .limit(scheduledLimit)
            .get(const GetOptions(source: Source.serverAndCache));

        final newPosts = snapshot.docs
            .map((d) => PostsModel.fromMap(d.data(), d.id))
            .where((p) => p.userID == uid && !p.arsiv && !p.flood)
            .toList();

        if (isInitial) {
          scheduledPosts.assignAll(newPosts);
        } else {
          scheduledPosts.addAll(newPosts);
        }
        if (snapshot.docs.isNotEmpty) {
          lastScheduledDoc = snapshot.docs.last;
        }
        if (snapshot.docs.length < scheduledLimit) {
          hasMoreScheduled = false;
        }
      } catch (e2) {
        print('fetchScheduledPosts fallback error: $e2');
      }
    }
    isLoadingScheduled = false;
  }

  Future<void> showSocialMediaLinkDelete(String docID) async {
    await noYesAlert(
      title: "Bağlantıyı Kaldır",
      message: "Bu bağlantıyı kaldırmak istediğinizden emin misiniz?",
      cancelText: "Vazgeç",
      yesText: "Kaldır",
      onYesPressed: () async {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection("SosyalMedyaLinkleri")
            .doc(docID)
            .delete();

        final links = Get.find<SocialMediaController>();
        links.getData();
      },
    );
  }

  Future<void> getLastPostAndAddToAllPosts() async {
    final snap = await FirebaseFirestore.instance
        .collection("Posts")
        .where("userID", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where("arsiv", isEqualTo: false)
        .where("flood", isEqualTo: false)
        .orderBy("timeStamp", descending: true)
        .limit(1) // Sadece son post
        .get(const GetOptions(source: Source.serverAndCache));

    if (snap.docs.isNotEmpty) {
      final lastPost =
          PostsModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (lastPost.timeStamp > nowMs || lastPost.deletedPost == true) {
        return; // ileri tarihli ise normal listeye ekleme
      }
      if (lastPost.video.trim().isNotEmpty && !lastPost.hasPlayableVideo) {
        return; // video post HLS hazır değilse profile düşürme
      }
      // Duplicate guard: avoid inserting if already exists
      final existsIndex = allPosts.indexWhere((p) => p.docID == lastPost.docID);
      if (existsIndex == -1) {
        final List<PostsModel> currentPosts =
            List<PostsModel>.from(allPosts); // copy
        currentPosts.insert(0, lastPost); // prepend
        allPosts.value = currentPosts;
      } else if (existsIndex > 0) {
        // If exists but not at top, move it to top to reflect recency
        final List<PostsModel> currentPosts = List<PostsModel>.from(allPosts);
        final existing = currentPosts.removeAt(existsIndex);
        currentPosts.insert(0, existing);
        allPosts.value = currentPosts;
      }
    }
  }

  Future<void> getReshares() async {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _hydrateReshares(uid, _latestReshareRefs);
  }

  Future<void> getResharesSingle() async {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('reshared_posts')
        .orderBy('timeStamp', descending: true)
        .limit(1)
        .get(const GetOptions(source: Source.serverAndCache));

    if (snap.docs.isEmpty) {
      reshares.clear();
      return;
    }

    final data = snap.docs.first.data();
    final postId = data['post_docID'] as String?;
    if (postId == null || postId.isEmpty) return;

    final doc =
        await FirebaseFirestore.instance.collection('Posts').doc(postId).get();
    final postData = doc.data();
    if (postData == null) return;

    final post = PostsModel.fromMap(postData, doc.id);
    if (post.timeStamp > DateTime.now().millisecondsSinceEpoch ||
        post.deletedPost == true) {
      return;
    }

    final exists = reshares.any((p) => p.docID == post.docID);
    if (!exists) {
      reshares.insert(0, post);
    }
  }

  void removeReshare(String postId) {
    reshares.removeWhere((post) => post.docID == postId);
  }

  Future<void> refreshAll() async {
    try {
      // Sayaçlar
      await getCounters();

      // Gönderiler
      lastPostDoc = null;
      hasMorePosts = true;

      // Fotoğraflar
      lastPostDocPhotos = null;
      hasMorePostsPhotos = true;

      // Videolar
      lastPostDocVideos = null;
      hasMorePostsVideos = true;

      // Reshare
      // Listeyi anlık boşaltma, fetch sonrası güncellenecek.

      // Scheduled (İz Bırak)
      lastScheduledDoc = null;
      hasMoreScheduled = true;
      // Listeyi anlık boşaltma, fetch sonrası güncellenecek.

      await Future.wait([
        fetchPosts(isInitial: true, force: true),
        fetchPhotos(isInitial: true, force: true),
        fetchVideos(isInitial: true, force: true),
        getReshares(),
        fetchScheduledPosts(isInitial: true, force: true),
      ]);
    } catch (e) {
      print('refreshAll error: $e');
    }
  }
}
