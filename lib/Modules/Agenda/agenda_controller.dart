import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';
import 'package:turqappv2/Services/reshare_helper.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../Core/Services/IndexPool/index_pool_store.dart';
import '../../Core/Services/ContentPolicy/content_policy.dart';
import '../NavBar/nav_bar_controller.dart';
import 'AgendaContent/agenda_content_controller.dart';

class AgendaController extends GetxController {
  final scrollController = ScrollController();

  final RxList<PostsModel> agendaList = <PostsModel>[].obs;
  final Map<String, GlobalKey> _agendaKeys = {};
  /// FAB gösterimi için kullanılır. Her frame'de reactive güncelleme yapmak yerine
  /// sadece eşik aşıldığında güncellenir (scroll jank'ı engeller).
  final RxBool showFAB = true.obs;
  final RxInt centeredIndex = 0.obs;
  int? lastCenteredIndex;
  var isMuted = false.obs;
  DocumentSnapshot? lastDoc;
  final RxBool hasMore = true.obs;
  final RxBool isLoading = false.obs;
  final int fetchLimit = 50;
  final pauseAll = false.obs;
  late NavBarController navBarController;
  final RxSet<String> highlightDocIDs = <String>{}.obs;
  Timer? _visibilityDebounce;
  Timer? _feedPrefetchDebounce;
  final Map<int, double> _visibleFractions = <int, double>{};

  // Video içerik ekrana sadece HLS hazır olduğunda düşsün.
  bool _isRenderablePost(PostsModel post) {
    if (post.video.trim().isEmpty) return true; // text/photo post
    return post.hasPlayableVideo; // HLS ready + playbackUrl var
  }

  Future<bool> _canViewerSeePost(PostsModel post) async {
    if (hiddenPosts.contains(post.docID)) return false;
    if (post.deletedPost == true) return false;
    if (!_isRenderablePost(post)) return false;

    final isPrivate = await _isUserPrivate(post.userID);
    if (!isPrivate) return true;

    final me = FirebaseAuth.instance.currentUser?.uid;
    final isMine = me != null && post.userID == me;
    final follows = followingIDs.contains(post.userID);
    return isMine || follows;
  }

  final RxSet<String> followingIDs = <String>{}.obs;
  final RxMap<String, int> myReshares =
      <String, int>{}.obs; // postID -> reshare timestamp
  final RxList<Map<String, dynamic>> publicReshareEvents =
      <Map<String, dynamic>>[].obs; // {postID,userID,timeStamp}
  final RxList<Map<String, dynamic>> feedReshareEntries =
      <Map<String, dynamic>>[].obs; // Feed'de görünecek reshare entry'leri
  final Map<String, bool> _userPrivacyCache = {};
  late final FirebaseMyStore myStore;

  List<String> hiddenPosts = [];
  double lastOffset = 0.0;
  List<PostsModel> _shuffledPosts = []; // Refresh sonrası karışık postlar
  int _shuffledIndex = 0; // Karışık postlardaki mevcut index
  DateTime? _lastCacheTime; // Son cache zamanı
  final int _cacheValidMinutes = 5; // Cache geçerlilik süresi (dakika)
  final int _initialShuffleSize = 100; // İlk karışık yükleme miktarı
  // null => no time window limit
  static const Duration? _agendaWindow = null;

  int _agendaCutoffMs(int nowMs) {
    if (_agendaWindow == null) return 0;
    return nowMs - _agendaWindow!.inMilliseconds;
  }

  bool _isInAgendaWindow(num ts, int nowMs) {
    if (_agendaWindow == null) return true;
    final v = ts.toInt();
    return v >= _agendaCutoffMs(nowMs) && v <= nowMs;
  }

  @override
  void onInit() {
    super.onInit();
    // Liste boşsa ilk yüklemeyi geciktirmeden başlat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (agendaList.isEmpty && !isLoading.value) {
        unawaited(fetchAgendaBigData(initial: true));
      }
    });
    scrollController.addListener(_onScroll);
    navBarController = Get.find<NavBarController>();
    myStore = Get.find<FirebaseMyStore>();
    _bindFollowingListener();
    _bindCenteredIndexListener();
  }

  @override
  void onReady() {
    super.onReady();

    // 🎯 CRITICAL FIX: İlk açılışta video manuel trigger
    // centeredIndex zaten 0 olduğu için listener tetiklenmiyor
    // Manual olarak ilk videoyu oynatmalıyız
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (agendaList.isNotEmpty && centeredIndex.value == 0) {
        final videoManager = Get.find<VideoStateManager>();
        final firstPost = agendaList[0];
        if (firstPost.video.isNotEmpty) {
          print('🎬 İlk video manuel trigger: ${firstPost.docID}');
          videoManager.playOnlyThis(firstPost.docID);
        }
      }
      _scheduleFeedPrefetch();
    });
  }

  /// 🎯 INSTAGRAM STYLE: centeredIndex değiştiğinde INSTANT video kontrolü
  void _bindCenteredIndexListener() {
    ever<int>(centeredIndex, (newIndex) {
      final videoManager = Get.find<VideoStateManager>();

      // Eğer -1 ise (hiçbir post centered değil), tüm videoları durdur
      if (newIndex == -1) {
        videoManager.pauseAllVideos();
        return;
      }

      // Yeni centered post var
      if (newIndex >= 0 && newIndex < agendaList.length) {
        final centeredPost = agendaList[newIndex];

        // Eğer centered post VIDEO içeriyorsa, SADECE o videoyu oynat
        if (centeredPost.video.isNotEmpty) {
          // 🎯 CRITICAL FIX: pauseAllExcept yerine playOnlyThis kullan
          // playOnlyThis = diğerlerini durdur + bu videoyu OYNAT
          videoManager.playOnlyThis(centeredPost.docID);
        } else {
          // Centered post video değilse, TÜM videoları durdur
          // (Resim, metin gönderisi centered olduğunda)
          videoManager.pauseAllVideos();
        }
      }

      _scheduleFeedPrefetch();
    });
  }

  void _scheduleFeedPrefetch() {
    _feedPrefetchDebounce?.cancel();
    _feedPrefetchDebounce = Timer(const Duration(milliseconds: 500), () {
      _updateFeedPrefetchQueue();
    });
  }

  void _updateFeedPrefetchQueue() {
    if (agendaList.isEmpty) return;
    final videoPosts = agendaList.where((p) => p.hasPlayableVideo).toList();
    if (videoPosts.isEmpty) return;

    final int safeCurrent = centeredIndex.value < 0
        ? 0
        : centeredIndex.value.clamp(0, videoPosts.length - 1);
    final docIds = videoPosts.map((p) => p.docID).toList();

    try {
      Get.find<PrefetchScheduler>().updateFeedQueue(docIds, safeCurrent);
    } catch (_) {}
  }

  /// Uygulama açıkken dışarıdan tetiklenen hafif cache ısınması.
  void ensureFeedCacheWarm() {
    _scheduleFeedPrefetch();
  }

  @override
  void onClose() {
    _visibilityDebounce?.cancel();
    _feedPrefetchDebounce?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (modelIndex < 0 || modelIndex >= agendaList.length) return;
    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
    }
    _visibilityDebounce?.cancel();
    _visibilityDebounce = Timer(const Duration(milliseconds: 250), () {
      _applyVisibilityDecision();
    });
  }

  void _applyVisibilityDecision() {
    final current = centeredIndex.value;
    int bestIndex = -1;
    double bestFraction = 0.0;

    _visibleFractions.forEach((idx, fraction) {
      if (fraction > bestFraction) {
        bestFraction = fraction;
        bestIndex = idx;
      }
    });

    // Ekranda en görünür post oynasın.
    // Header + padding nedeniyle 0.55 pratik ve stabil eşik.
    if (bestIndex >= 0 && bestFraction >= 0.55) {
      if (current != bestIndex) {
        centeredIndex.value = bestIndex;
        lastCenteredIndex = bestIndex;
      }
      return;
    }

    // Hiçbir post yeterince görünmüyorsa durdur.
    if (current != -1 && (bestIndex == -1 || bestFraction < 0.20)) {
      centeredIndex.value = -1;
    }
  }

  void _bindFollowingListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('TakipEdilenler')
        .snapshots()
        .listen((snap) {
      followingIDs.assignAll(snap.docs.map((d) => d.id).toSet());
    });

    // Also bind my reshares to reflect duplicates in feed
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('reshared_posts')
        .snapshots()
        .listen((snap) {
      final map = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final postId = data['post_docID'] as String?;
        if (postId == null || postId.isEmpty) continue;
        final ts = (data['timeStamp'] ?? 0) as int;
        map[postId] = ts;
      }
      myReshares.value = map;
    });
  }

  // Fetch a few recent reshares for these posts from followers and public users
  Future<void> fetchResharesForPosts(List<PostsModel> posts,
      {int perPostLimit = 2}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      for (final p in posts) {
        try {
          final qs = await FirebaseFirestore.instance
              .collection('Posts')
              .doc(p.docID)
              .collection('reshares')
              .orderBy('timeStamp', descending: true)
              .limit(perPostLimit)
              .get();
          for (final d in qs.docs) {
            final rid = d.id;
            if (uid != null && rid == uid) {
              continue; // my own handled via myReshares
            }
            final data = d.data();
            final ts = (data['timeStamp'] ?? 0) as int;
            final originalUserID = data['originalUserID'] as String?;
            final originalPostID = data['originalPostID'] as String?;

            bool include = false;
            if (followingIDs.contains(rid)) {
              include = true;
            } else {
              final isPrivate = await _isUserPrivate(rid);
              include = !isPrivate;
            }
            if (!include) continue;
            final exists = publicReshareEvents
                .any((e) => e['postID'] == p.docID && e['userID'] == rid);
            if (exists) continue;

            // Twitter benzeri reshare event'i ekle - orijinal post bilgileriyle
            final reshareEvent = {
              'postID': p.docID,
              'userID': rid,
              'timeStamp': ts,
              'type': 'reshare'
            };

            // Orijinal post bilgilerini de ekle
            if (originalUserID != null && originalUserID.isNotEmpty) {
              reshareEvent['originalUserID'] = originalUserID;
              reshareEvent['originalPostID'] = originalPostID ?? p.docID;
            } else {
              reshareEvent['originalUserID'] = p.userID;
              reshareEvent['originalPostID'] = p.docID;
            }

            publicReshareEvents.add(reshareEvent);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  // Güvenli ekleme: agendaList'e docID bazında tekilleştirerek ekle
  void _addUniqueToAgenda(List<PostsModel> items) {
    if (items.isEmpty) return;
    final existing = agendaList.map((e) => e.docID).toSet();
    final unique = <PostsModel>[];
    for (final p in items) {
      if (!existing.contains(p.docID)) {
        existing.add(p.docID);
        unique.add(p);
      }
    }
    if (unique.isNotEmpty) {
      agendaList.addAll(unique);
      _scheduleFeedPrefetch();
    }
  }

  Future<bool> _isUserPrivate(String userID) async {
    if (_userPrivacyCache.containsKey(userID)) {
      return _userPrivacyCache[userID]!;
    }
    try {
      final d = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      final gizli = (d.data()?['gizliHesap'] ?? false) == true;
      _userPrivacyCache[userID] = gizli;
      return gizli;
    } catch (_) {
      _userPrivacyCache[userID] = false;
      return false;
    }
  }

  GlobalKey getAgendaKeyForDoc(String docID) {
    return _agendaKeys.putIfAbsent(
        docID, () => GlobalObjectKey("agenda_$docID"));
  }

  void _onScroll() {
    final currentOffset = scrollController.offset;

    // Negatif veya 300'den küçük offset'te daima göster
    if (currentOffset < 300) {
      navBarController.showBar.value = true;
    } else {
      // 300 ve üstü ise yön kontrolü
      if (currentOffset > lastOffset) {
        navBarController.showBar.value = false;
      } else if (currentOffset < lastOffset) {
        navBarController.showBar.value = true;
      }
    }
    lastOffset = currentOffset;

    // Liste sonuna yaklaşınca yeni verileri çek
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      fetchAgendaBigData();
    }

    // FAB'ı sadece eşik geçişlerinde güncelle (her frame'de değil)
    final shouldShowFab = currentOffset <= 1000;
    if (showFAB.value != shouldShowFab) {
      showFAB.value = shouldShowFab;
    }
  }

  void disposeAgendaContentController(String docID) {
    if (Get.isRegistered<AgendaContentController>(tag: docID)) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
      print("Disposed AgendaContentController for $docID");
    }
  }

  void markHighlighted(List<String> docIDs, {Duration? keepFor}) {
    highlightDocIDs.addAll(docIDs);
    // Otomatik olarak belirli süre sonra temizle
    final d = keepFor ?? const Duration(seconds: 2);
    Future.delayed(d, () {
      highlightDocIDs.removeAll(docIDs);
    });
  }

  // Yeni yüklenen gönderileri en üste almak için güvenli yenileme
  Future<void> prependUploadedAndRefresh() async {
    try {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
      await refreshAgenda();
    } catch (e) {
      print('prependUploadedAndRefresh error: $e');
    }
  }

  Future<void> fetchAgendaBigData({bool initial = false}) async {
    if (initial) {
      lastDoc = null;
      hasMore.value = true;
      agendaList.clear();
      _shuffledPosts.clear(); // Shuffle cache'ini temizle
      _shuffledIndex = 0;
      // Eski yeniden paylaşım meta verilerini sıfırla
      publicReshareEvents.clear();
      feedReshareEntries.clear();

      // 🎯 INSTAGRAM STYLE: İlk açılışta centered index'i sıfırla
      centeredIndex.value = -1;

      // Hızlı ilk boya için: cache'ten doldurmayı dene (gizlilik güvenli)
      try {
        await _tryQuickFillFromCache();
      } catch (e) {
        // Sessizce devam et, sunucu isteğine geçilecek
        // print("quick cache fill error: $e");
      }

      // İlk yüklemede reshare eventlerini arka planda getir (feed'i bloklamasın)
      unawaited(_fetchAndMergeReshareEvents());
    }

    // Eğer shuffle edilmiş postlar varsa onlardan devam et
    if (_shuffledPosts.isNotEmpty && _shuffledIndex < _shuffledPosts.length) {
      if (!hasMore.value || isLoading.value) return;
      isLoading.value = true;

      try {
        final remainingCount = _shuffledPosts.length - _shuffledIndex;
        final takeCount =
            remainingCount > fetchLimit ? fetchLimit : remainingCount;

        final nextBatch =
            _shuffledPosts.sublist(_shuffledIndex, _shuffledIndex + takeCount);
        _addUniqueToAgenda(nextBatch);
        _shuffledIndex += takeCount;

        if (_shuffledIndex >= _shuffledPosts.length) {
          hasMore.value = false;
        }
      } finally {
        isLoading.value = false;
      }
      return;
    }

    if (!hasMore.value || isLoading.value) return;

    isLoading.value = true;
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      Query query = FirebaseFirestore.instance
          .collection("Posts")
          .where("arsiv", isEqualTo: false)
          .where("flood", isEqualTo: false)
          .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
          .where('timeStamp', isLessThanOrEqualTo: nowMs)
          .orderBy("timeStamp", descending: true)
          .limit(fetchLimit);

      if (lastDoc != null) {
        query =
            (query as Query<Map<String, dynamic>>).startAfterDocument(lastDoc!);
      }

      final snap = await query.get();

      final items = snap.docs
          .map((doc) =>
              PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          // Son 24 saat penceresi
          .where((p) => _isInAgendaWindow(p.timeStamp, nowMs))
          .where((p) => p.deletedPost != true)
          .toList();

      // Yazarların gizlilik durumlarını çek ve gizli profilleri filtrele
      final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
      Map<String, bool> userPrivacy = {};
      Map<String, Map<String, dynamic>> userMeta = {};
      if (uniqueUserIDs.isNotEmpty) {
        // whereIn 10 eleman sınırı — fetchLimit zaten 10
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: uniqueUserIDs)
            .get();
        for (final d in usersSnap.docs) {
          final data = d.data();
          final gizli = (data['gizliHesap'] ?? false) == true;
          userPrivacy[d.id] = gizli;
          userMeta[d.id] = data;
        }
      }

      final String? me = FirebaseAuth.instance.currentUser?.uid;
      final visibleItems = items.where((post) {
        if (hiddenPosts.contains(post.docID)) return false;
        if (post.deletedPost == true) return false;
        if (!_isRenderablePost(post)) return false;
        final isPrivate = userPrivacy[post.userID] ?? false;
        if (!isPrivate) return true;
        // Gizli ise: sadece kendi gönderisi veya takip ediliyorsa göster
        final isMine = me != null && post.userID == me;
        final follows = followingIDs.contains(post.userID);
        return isMine || follows;
      }).toList();

      lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;

      if (visibleItems.isNotEmpty) {
        unawaited(_saveFeedPostsToPool(visibleItems, userMeta));
        // Yeni eklenecekler içinde "zamanlıydı ve yeni görünür oldu" olanları vurgula
        final existingIDs = agendaList.map((e) => e.docID).toSet();
        final toAdd = <PostsModel>[];
        final freshScheduled = <String>[];
        final tenMinAgo = nowMs - const Duration(minutes: 15).inMilliseconds;
        for (final p in visibleItems) {
          final isNew = !existingIDs.contains(p.docID);
          if (!isNew) continue;
          toAdd.add(p);
          final wasScheduled = p.timeStamp != 0;
          final justBecameVisible = wasScheduled && p.timeStamp >= tenMinAgo;
          if (justBecameVisible) {
            freshScheduled.add(p.docID);
          }
        }
        if (freshScheduled.isNotEmpty) {
          markHighlighted(freshScheduled,
              keepFor: const Duration(milliseconds: 900));
        }
        if (toAdd.isNotEmpty) {
          _addUniqueToAgenda(toAdd);
          // Fetch recent reshare events for these posts (followers or public users)
          // Fire and forget
          fetchResharesForPosts(toAdd, perPostLimit: 1);
        }
      }

      if (items.length < fetchLimit) {
        hasMore.value = false;
      }
    } catch (e) {
      print("fetchAgendaBigData error: $e");
    } finally {
      isLoading.value = false; // HER DURUMDA EN SON ÇALIŞIR

      // 🎯 INSTAGRAM STYLE: İlk açılışta ilk videoyu otomatik centered yap
      if (initial && agendaList.isNotEmpty) {
        // Bir frame bekle ki VisibilityDetector build olsun
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            centeredIndex.value = 0;
            lastCenteredIndex = 0;
          }
        });
      }
    }
  }

  // Cache-first: başlangıçta cache'te varsa hızlıca ilk 10 gönderiyi doldur
  Future<void> _tryQuickFillFromCache() async {
    await _tryQuickFillFromPool();
    if (agendaList.isNotEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = _agendaCutoffMs(nowMs);
    Query query = FirebaseFirestore.instance
        .collection("Posts")
        .where("arsiv", isEqualTo: false)
        .where("flood", isEqualTo: false)
        .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
        .where('timeStamp', isLessThanOrEqualTo: nowMs)
        .orderBy("timeStamp", descending: true)
        .limit(fetchLimit);

    final snap = await query.get(const GetOptions(source: Source.cache));
    if (snap.docs.isEmpty) return;

    final items = snap.docs
        .map((doc) =>
            PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((p) => _isInAgendaWindow(p.timeStamp, nowMs))
        .where((p) => p.deletedPost != true)
        .toList();
    if (items.isEmpty) return;

    // Kullanıcı gizliliklerini cache'ten getir
    final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
    Map<String, bool> userPrivacy = {};
    for (int i = 0; i < uniqueUserIDs.length; i += 10) {
      final chunk = uniqueUserIDs.sublist(
          i, i + 10 > uniqueUserIDs.length ? uniqueUserIDs.length : i + 10);
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.cache));
      for (final d in usersSnap.docs) {
        final gizli = (d.data()['gizliHesap'] ?? false) == true;
        userPrivacy[d.id] = gizli;
      }
    }

    final String? me = FirebaseAuth.instance.currentUser?.uid;
    final filtered = items.where((post) {
      if (hiddenPosts.contains(post.docID)) return false;
      if (!_isRenderablePost(post)) return false;
      final isPrivate = userPrivacy[post.userID] ?? false;
      if (!isPrivate) return true;
      final isMine = me != null && post.userID == me;
      final follows = followingIDs.contains(post.userID);
      return isMine || follows;
    }).toList();

    if (filtered.isEmpty) return;
    // Duplicate'e düşmemek için mevcut ID'leri kontrol et
    final existingIDs = agendaList.map((e) => e.docID).toSet();
    final toAdd =
        filtered.where((p) => !existingIDs.contains(p.docID)).toList();
    if (toAdd.isNotEmpty) {
      _addUniqueToAgenda(toAdd);
      // Reshare'leri gecikmeli getir (açılışta bant genişliğini kritik sorgulara bırak)
      Future.delayed(const Duration(seconds: 2), () {
        fetchResharesForPosts(toAdd, perPostLimit: 1);
      });

      // 🎯 INSTAGRAM STYLE: Cache'den yüklendiğinde de ilk videoyu centered yap
      if (agendaList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            centeredIndex.value = 0;
            lastCenteredIndex = 0;
          }
        });
      }
    }
  }

  Future<void> _tryQuickFillFromPool() async {
    if (!Get.isRegistered<IndexPoolStore>()) return;
    final pool = Get.find<IndexPoolStore>();
    final fromPool = await pool.loadPosts(
      IndexPoolKind.feed,
      limit: ContentPolicy.feedInitialFromPool,
    );
    if (fromPool.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    // Pool'dan gelen postları validasyonsuz hızlıca göster.
    // Basit senkron filtre: silinmiş/gizlenmiş postları çıkar.
    final quickFiltered = fromPool.where((post) {
      if (hiddenPosts.contains(post.docID)) return false;
      if (post.deletedPost == true) return false;
      if (!_isInAgendaWindow(post.timeStamp, nowMs)) return false;
      if (!_isRenderablePost(post)) return false;
      return true;
    }).toList();

    if (quickFiltered.isEmpty) return;

    _addUniqueToAgenda(quickFiltered);

    // Arka planda: validasyon + gizlilik kontrolü + reshare
    unawaited(_postPoolFillCleanup(fromPool, quickFiltered));

    if (agendaList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty && centeredIndex.value == -1) {
          centeredIndex.value = 0;
          lastCenteredIndex = 0;
        }
      });
    }
  }

  /// Pool fill sonrası arka planda: validasyon, gizlilik prune, reshare fetch
  Future<void> _postPoolFillCleanup(
      List<PostsModel> originalPool, List<PostsModel> shown) async {
    try {
      // Validasyon: silinmiş/arşivlenmiş postları pool'dan temizle
      final valid = await _validatePoolPostsAndPrune(originalPool);
      final validIds = valid.map((p) => p.docID).toSet();

      // Toplu gizlilik kontrolü (whereIn ile, tek tek değil)
      final uniqueUserIDs = valid.map((e) => e.userID).toSet().toList();
      final Map<String, bool> userPrivacy = {};
      for (final chunk in _chunkList(uniqueUserIDs, 10)) {
        try {
          final usersSnap = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (final d in usersSnap.docs) {
            final gizli = (d.data()['gizliHesap'] ?? false) == true;
            userPrivacy[d.id] = gizli;
            _userPrivacyCache[d.id] = gizli;
          }
        } catch (_) {}
      }

      final String? me = FirebaseAuth.instance.currentUser?.uid;

      // Gösterilen ama aslında geçersiz/gizli olan postları feed'den kaldır
      final toRemove = <String>[];
      for (final post in shown) {
        if (!validIds.contains(post.docID)) {
          toRemove.add(post.docID);
          continue;
        }
        final isPrivate = userPrivacy[post.userID] ?? false;
        if (isPrivate) {
          final isMine = me != null && post.userID == me;
          final follows = followingIDs.contains(post.userID);
          if (!isMine && !follows) {
            toRemove.add(post.docID);
          }
        }
      }

      if (toRemove.isNotEmpty) {
        agendaList.removeWhere((p) => toRemove.contains(p.docID));
      }

      // Reshare'leri gecikmeli getir (bant genişliği çakışmasını önle)
      Future.delayed(const Duration(seconds: 2), () {
        fetchResharesForPosts(
            agendaList.take(10).toList(), perPostLimit: 1);
      });
    } catch (_) {}
  }

  Future<List<PostsModel>> _validatePoolPostsAndPrune(
      List<PostsModel> posts) async {
    if (posts.isEmpty) return const <PostsModel>[];

    final postIds =
        posts.map((e) => e.docID).where((e) => e.isNotEmpty).toSet();
    final userIds =
        posts.map((e) => e.userID).where((e) => e.isNotEmpty).toSet();

    final validPostIds = <String>{};
    for (final chunk in _chunkList(postIds.toList(), 10)) {
      final snap = await FirebaseFirestore.instance
          .collection('Posts')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final d in snap.docs) {
        final data = d.data();
        final deleted = (data['deletedPost'] ?? false) == true;
        final archived = (data['arsiv'] ?? false) == true;
        final timeStamp =
            (data['timeStamp'] is num) ? (data['timeStamp'] as num).toInt() : 0;
        if (!deleted && !archived && _isInAgendaWindow(timeStamp, nowMs)) {
          validPostIds.add(d.id);
        }
      }
    }

    final validUserIds = <String>{};
    for (final chunk in _chunkList(userIds.toList(), 10)) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        validUserIds.add(d.id);
      }
    }

    final valid = posts
        .where((p) =>
            validPostIds.contains(p.docID) && validUserIds.contains(p.userID))
        .toList();
    if (valid.length == posts.length) return valid;

    final invalidIds = posts
        .where((p) =>
            !validPostIds.contains(p.docID) || !validUserIds.contains(p.userID))
        .map((p) => p.docID)
        .toList();
    if (invalidIds.isNotEmpty && Get.isRegistered<IndexPoolStore>()) {
      await Get.find<IndexPoolStore>()
          .removePosts(IndexPoolKind.feed, invalidIds);
    }

    return valid;
  }

  Future<void> _saveFeedPostsToPool(
    List<PostsModel> posts,
    Map<String, Map<String, dynamic>> userMeta,
  ) async {
    if (posts.isEmpty) return;
    if (!Get.isRegistered<IndexPoolStore>()) return;
    await Get.find<IndexPoolStore>().savePosts(
      IndexPoolKind.feed,
      posts,
      userMeta: userMeta,
    );
  }

  List<List<T>> _chunkList<T>(List<T> input, int size) {
    if (input.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (int i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }

  Future<void> refreshAgenda() async {
    isLoading.value = true;
    try {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
      lastDoc = null;
      hasMore.value = true;
      agendaList.clear();
      // Yeniden paylaşım olaylarını da temizle (güncel meta yeniden oluşsun)
      publicReshareEvents.clear();
      feedReshareEntries.clear();

      // 🎯 INSTAGRAM STYLE: Refresh sırasında centered index'i sıfırla
      centeredIndex.value = -1;

      await _fetchRefreshShuffledLast100();
      // Reshare eventlerini de dahil et
      await _fetchAndMergeReshareEvents();
    } catch (e) {
      print("refreshAgenda error: $e");
    } finally {
      isLoading.value = false;

      // 🎯 INSTAGRAM STYLE: Refresh sonrası ilk videoyu otomatik centered yap
      if (agendaList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            centeredIndex.value = 0;
            lastCenteredIndex = 0;
          }
        });
      }
    }
  }

  // Feed refresh: son 100 gönderiyi çek, shuffle yap, ilk partiyi göster.
  Future<void> _fetchRefreshShuffledLast100() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = _agendaCutoffMs(nowMs);
    final snap = await FirebaseFirestore.instance
        .collection("Posts")
        .where("arsiv", isEqualTo: false)
        .where("flood", isEqualTo: false)
        .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
        .where('timeStamp', isLessThanOrEqualTo: nowMs)
        .orderBy("timeStamp", descending: true)
        .limit(100)
        .get();

    final items = snap.docs
        .map((doc) => PostsModel.fromMap(doc.data(), doc.id))
        .where((p) => _isInAgendaWindow(p.timeStamp, nowMs))
        .where((p) => p.deletedPost != true)
        .toList();

    final visibleItemsRaw = await _filterPrivateItems(items);
    final Map<String, PostsModel> uniqueMap = {
      for (final p in visibleItemsRaw) p.docID: p,
    };
    final visibleItems = uniqueMap.values.toList()..shuffle(Random());

    _shuffledPosts = visibleItems;
    _shuffledIndex = 0;
    _lastCacheTime = DateTime.now();

    final initialItems = _shuffledPosts.take(fetchLimit).toList();
    _addUniqueToAgenda(initialItems);
    _shuffledIndex = initialItems.length;
    hasMore.value = _shuffledPosts.length > _shuffledIndex;
  }

  // Refresh sırasında karışık gönderi getir - HIZLI VERSİYON
  Future<void> fetchRandomizedAgendaData() async {
    try {
      // Cache kontrolü - eğer cache geçerliyse ve karışık postlar varsa hızlı yükle
      if (_isCacheValid() && _shuffledPosts.isNotEmpty) {
        print("Cache'den hızlı yükleme yapılıyor...");
        _shuffledPosts.shuffle(Random()); // Yeniden karıştır
        _shuffledIndex = 0;

        final initialItems = _shuffledPosts.take(fetchLimit).toList();
        _addUniqueToAgenda(initialItems);
        _shuffledIndex = fetchLimit;
        hasMore.value = _shuffledPosts.length > fetchLimit;

        // 🎯 INSTAGRAM STYLE: Cache'den yüklendiğinde ilk videoyu centered yap
        if (agendaList.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (agendaList.isNotEmpty && centeredIndex.value == -1) {
              centeredIndex.value = 0;
              lastCenteredIndex = 0;
            }
          });
        }
        return;
      }

      print("Yeni veri çekiliyor...");

      // İlk olarak küçük bir batch çek (hızlı görünüm için)
      await _fetchInitialShuffledBatch();

      // Arka planda daha fazla veri çek
      _fetchMoreShuffledDataInBackground();
    } catch (e) {
      print("fetchRandomizedAgendaData error: $e");
    }
  }

  // Cache geçerli mi kontrol et
  bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    final now = DateTime.now();
    final diff = now.difference(_lastCacheTime!).inMinutes;
    return diff < _cacheValidMinutes;
  }

  // İlk küçük batch'i hızlıca getir
  Future<void> _fetchInitialShuffledBatch() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = _agendaCutoffMs(nowMs);
    Query query = FirebaseFirestore.instance
        .collection("Posts")
        .where("arsiv", isEqualTo: false)
        .where("flood", isEqualTo: false)
        .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
        .where('timeStamp', isLessThanOrEqualTo: nowMs)
        .orderBy("timeStamp", descending: true)
        .limit(_initialShuffleSize); // 100 gönderi

    final snap = await query.get();
    // nowMs already computed above

    final items = snap.docs
        .map((doc) =>
            PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((p) => _isInAgendaWindow(p.timeStamp, nowMs))
        .where((p) => p.deletedPost != true)
        .toList();

    // Gizlilik kontrolü - sadece gerekli kullanıcılar için
    final visibleItemsRaw = await _filterPrivateItems(items);

    // DocID bazında tekilleştir
    final Map<String, PostsModel> uniqueMap = {
      for (final p in visibleItemsRaw) p.docID: p,
    };
    final visibleItems = uniqueMap.values.toList();

    // Karıştır ve göster
    visibleItems.shuffle(Random());
    _shuffledPosts = visibleItems;
    _shuffledIndex = 0;
    _lastCacheTime = DateTime.now();

    final initialItems = _shuffledPosts.take(fetchLimit).toList();
    _addUniqueToAgenda(initialItems);
    _shuffledIndex = fetchLimit;
    hasMore.value = _shuffledPosts.length > fetchLimit;

    // 🎯 INSTAGRAM STYLE: İlk batch yüklendiğinde ilk videoyu centered yap
    if (agendaList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty && centeredIndex.value == -1) {
          centeredIndex.value = 0;
          lastCenteredIndex = 0;
        }
      });
    }
  }

  // Arka planda daha fazla veri çek
  void _fetchMoreShuffledDataInBackground() async {
    try {
      // 2-3 saniye bekle ki kullanıcı hızlı görünümü görsün
      await Future.delayed(const Duration(seconds: 2));

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      Query query = FirebaseFirestore.instance
          .collection("Posts")
          .where("arsiv", isEqualTo: false)
          .where("flood", isEqualTo: false)
          .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
          .where('timeStamp', isLessThanOrEqualTo: nowMs)
          .orderBy("timeStamp", descending: true)
          .limit(1000); // 2000 yerine 1000 (daha hızlı)

      final snap = await query.get();
      // nowMs already computed above

      final items = snap.docs
          .map((doc) =>
              PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((p) => _isInAgendaWindow(p.timeStamp, nowMs))
          .where((p) => p.deletedPost != true)
          .toList();

      final visibleItemsRaw = await _filterPrivateItems(items);
      // DocID bazında tekilleştir
      final Map<String, PostsModel> uniqueMap = {
        for (final p in visibleItemsRaw) p.docID: p,
      };
      final visibleItems = uniqueMap.values.toList();

      // Mevcut gösterilenleri koru, kalanları güncelle
      final currentVisible = agendaList.take(_shuffledIndex).toList();
      visibleItems.shuffle(Random());

      // Yeni listeyi hazırla (mevcut gösterilenler + yeni karışık liste)
      _shuffledPosts = [
        ...currentVisible,
        ...visibleItems.where(
            (item) => !currentVisible.any((shown) => shown.docID == item.docID))
      ];

      hasMore.value = _shuffledPosts.length > _shuffledIndex;
      print(
          "Arka plan yüklemesi tamamlandı: ${_shuffledPosts.length} gönderi hazır");
    } catch (e) {
      print("Background fetch error: $e");
    }
  }

  // Gizlilik filtreleme - optimize edilmiş
  Future<List<PostsModel>> _filterPrivateItems(List<PostsModel> items) async {
    final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
    Map<String, bool> userPrivacy = {};

    if (uniqueUserIDs.isNotEmpty) {
      // Batch'leri 10'ar yerine 30'ar yap (daha az sorgu)
      final batches = <List<String>>[];
      for (int i = 0; i < uniqueUserIDs.length; i += 30) {
        final endIndex =
            (i + 30 > uniqueUserIDs.length) ? uniqueUserIDs.length : i + 30;
        final batch = uniqueUserIDs.sublist(i, endIndex);
        if (batch.length <= 10) {
          // 10 ve altındaysa tek sorguda çek
          batches.add(batch);
        } else {
          // 10'dan fazlaysa 10'ar böl
          for (int j = 0; j < batch.length; j += 10) {
            final subEndIndex = (j + 10 > batch.length) ? batch.length : j + 10;
            batches.add(batch.sublist(j, subEndIndex));
          }
        }
      }

      for (final batch in batches) {
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final d in usersSnap.docs) {
          final gizli = (d.data()['gizliHesap'] ?? false) == true;
          userPrivacy[d.id] = gizli;
        }
      }
    }

    final String? me = FirebaseAuth.instance.currentUser?.uid;
    return items.where((post) {
      if (hiddenPosts.contains(post.docID)) return false;
      if (post.deletedPost == true) return false;
      if (!_isRenderablePost(post)) return false;
      final isPrivate = userPrivacy[post.userID] ?? false;
      if (!isPrivate) return true;
      final isMine = me != null && post.userID == me;
      final follows = followingIDs.contains(post.userID);
      return isMine || follows;
    }).toList();
  }

  // Yeni yüklenen gönderileri sadece listenin başına ekle (full refresh yapmadan)
  void addUploadedPostsAtTop(List<PostsModel> posts) {
    if (posts.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final existingIDs = agendaList.map((e) => e.docID).toSet();
    final toAdd = <PostsModel>[];
    for (final p in posts) {
      if (!existingIDs.contains(p.docID) &&
          !hiddenPosts.contains(p.docID) &&
          _isInAgendaWindow(p.timeStamp, nowMs) &&
          _isRenderablePost(p)) {
        toAdd.add(p);
      }
    }
    if (toAdd.isEmpty) return;
    agendaList.insertAll(0, toAdd);

    // Yeni eklenen postların originalUserID'lerini cache'e preload et
    _preloadOriginalUserNicknames(toAdd);
  }

  // Paylaşım yapan kullanıcıların nickname'lerini önceden cache'e yükle
  void _preloadOriginalUserNicknames(List<PostsModel> posts) {
    final userIDsToLoad = <String>{};

    for (final post in posts) {
      // Post sahibini cache'e ekle
      userIDsToLoad.add(post.userID);

      // Eğer paylaşım ise, orijinal kullanıcıyı da cache'e ekle
      // Eğer reshare ise, orijinal kullanıcıyı da cache'e ekle
      if (post.originalUserID.isNotEmpty) {
        userIDsToLoad.add(post.originalUserID);
      }
    }

    // Async olarak nickname'leri yükle (UI'yi bloklamadan)
    for (final userID in userIDsToLoad) {
      ReshareHelper.getUserNickname(userID).catchError((e) {
        // Hata durumunda sessizce geç, varsayılan değer döner
        return 'Bilinmeyen Kullanıcı';
      });
    }
  }

  // Reshare eventlerini getir ve ayrı listede tut (orijinal postlara dokunma)
  Future<void> _fetchAndMergeReshareEvents() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Takip edilen kullanıcıların reshare eventlerini getir
      final List<Map<String, dynamic>> allReshareEvents = [];

      // Kendi reshare eventleri (her zaman göster)
      final myReshareSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reshared_posts')
          .orderBy('timeStamp', descending: true)
          .limit(50)
          .get();

      for (final doc in myReshareSnap.docs) {
        final data = doc.data();
        final postId = data['post_docID'] as String?;
        final timestamp = (data['timeStamp'] ?? 0) as int;
        final originalUserID = data['originalUserID'] as String?;
        final originalPostID = data['originalPostID'] as String?;

        if (postId != null && postId.isNotEmpty) {
          allReshareEvents.add({
            'postID': postId,
            'userID': uid,
            'timeStamp': timestamp,
            'originalUserID': originalUserID ?? '',
            'originalPostID': originalPostID ?? '',
            'type': 'reshare'
          });
        }
      }

      // Takip edilen kullanıcıların reshare eventleri
      if (followingIDs.isNotEmpty) {
        for (final followedUserId in followingIDs.take(20)) {
          // İlk 20 takip edilen
          try {
            final userReshareSnap = await FirebaseFirestore.instance
                .collection('users')
                .doc(followedUserId)
                .collection('reshared_posts')
                .orderBy('timeStamp', descending: true)
                .limit(10)
                .get();

            for (final doc in userReshareSnap.docs) {
              final data = doc.data();
              final postId = data['post_docID'] as String?;
              final timestamp = (data['timeStamp'] ?? 0) as int;
              final originalUserID = data['originalUserID'] as String?;
              final originalPostID = data['originalPostID'] as String?;

              if (postId != null && postId.isNotEmpty) {
                allReshareEvents.add({
                  'postID': postId,
                  'userID': followedUserId,
                  'timeStamp': timestamp,
                  'originalUserID': originalUserID ?? '',
                  'originalPostID': originalPostID ?? '',
                  'type': 'reshare'
                });
              }
            }
          } on FirebaseException catch (e) {
            // Rules izin vermiyorsa log spam yapmadan o kullanıcıyı atla.
            if (e.code != 'permission-denied') {
              debugPrint(
                'Reshare fetch error user=$followedUserId code=${e.code}',
              );
            }
          } catch (e) {
            debugPrint(
                'Reshare fetch unexpected error user=$followedUserId: $e');
          }
        }
      }

      // Reshare eventlerdeki postları getir ve feed reshare entries'e ekle
      final Set<String> resharedPostIds =
          allReshareEvents.map((e) => e['postID'] as String).toSet();

      if (resharedPostIds.isNotEmpty) {
        final List<String> postIdsList = resharedPostIds.toList();

        // Firebase whereIn limit 10, bu yüzden batch'lere böl
        for (int i = 0; i < postIdsList.length; i += 10) {
          final batch = postIdsList.sublist(
              i, i + 10 > postIdsList.length ? postIdsList.length : i + 10);

          try {
            final postsSnap = await FirebaseFirestore.instance
                .collection('Posts')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

            for (final postDoc in postsSnap.docs) {
              final post = PostsModel.fromMap(postDoc.data(), postDoc.id);
              if (!await _canViewerSeePost(post)) continue;

              // Bu post ile ilgili tüm reshare eventleri
              final relatedReshares = allReshareEvents
                  .where((event) => event['postID'] == post.docID)
                  .toList();

              for (final reshareEvent in relatedReshares) {
                // Feed reshare entry'si oluştur
                final feedEntry = {
                  'type': 'reshare',
                  'post': post,
                  'reshareTimestamp': reshareEvent['timeStamp'],
                  'reshareUserID': reshareEvent['userID'],
                  'originalUserID': reshareEvent['originalUserID'],
                  'originalPostID': reshareEvent['originalPostID'],
                };

                // Duplicate kontrolü
                final entryId =
                    '${post.docID}_${reshareEvent['userID']}_${reshareEvent['timeStamp']}';
                final exists = feedReshareEntries.any((entry) {
                  final existingId =
                      '${(entry['post'] as PostsModel).docID}_${entry['reshareUserID']}_${entry['reshareTimestamp']}';
                  return existingId == entryId;
                });

                if (!exists) {
                  feedReshareEntries.add(feedEntry);
                }

                // Metadata'ya da ekle
                publicReshareEvents.add(reshareEvent);
              }
            }
          } catch (e) {
            print('Error fetching posts for batch $i: $e');
          }
        }
      }
    } catch (e) {
      print('_fetchAndMergeReshareEvents error: $e');
    }
  }

  // Sadece reshare entries'leri güncelle (scroll position'ı koruyarak)
  Future<void> updateReshareEntries() async {
    try {
      feedReshareEntries.clear();
      await _fetchAndMergeReshareEvents();
    } catch (e) {
      print('updateReshareEntries error: $e');
    }
  }

  // Yeni bir reshare entry'si ekle (en üste, en yeni timestamp ile)
  Future<void> addNewReshareEntry(String postId, String reshareUserID) async {
    try {
      // İlgili post'u bul
      final post = agendaList.firstWhereOrNull((p) => p.docID == postId);
      if (post == null) {
        // Post bulunamadıysa Firebase'den çek
        final postDoc = await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .get();

        if (!postDoc.exists) return;

        final fetchedPost = PostsModel.fromMap(postDoc.data()!, postDoc.id);
        if (!await _canViewerSeePost(fetchedPost)) return;

        // Yeni reshare entry'si oluştur
        final reshareEntry = {
          'type': 'reshare',
          'post': fetchedPost,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': fetchedPost.originalUserID.isNotEmpty
              ? fetchedPost.originalUserID
              : fetchedPost.userID,
          'originalPostID': fetchedPost.originalPostID.isNotEmpty
              ? fetchedPost.originalPostID
              : fetchedPost.docID,
        };

        // En üste ekle
        feedReshareEntries.insert(0, reshareEntry);
      } else {
        if (!await _canViewerSeePost(post)) return;
        // Mevcut post'tan reshare entry'si oluştur
        final reshareEntry = {
          'type': 'reshare',
          'post': post,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': post.originalUserID.isNotEmpty
              ? post.originalUserID
              : post.userID,
          'originalPostID':
              post.originalPostID.isNotEmpty ? post.originalPostID : post.docID,
        };

        // En üste ekle
        feedReshareEntries.insert(0, reshareEntry);
      }
    } catch (e) {
      print('addNewReshareEntry error: $e');
    }
  }

  // Scroll pozisyonunu koruyarak reshare entry ekle
  Future<void> addNewReshareEntryWithoutScroll(
      String postId, String reshareUserID) async {
    try {
      // Mevcut scroll pozisyonunu kaydet
      final currentOffset =
          scrollController.hasClients ? scrollController.offset : 0.0;
      // İlgili post'u bul
      final post = agendaList.firstWhereOrNull((p) => p.docID == postId);
      if (post == null) {
        // Post bulunamadıysa Firebase'den çek
        final postDoc = await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .get();

        if (!postDoc.exists) return;

        final fetchedPost = PostsModel.fromMap(postDoc.data()!, postDoc.id);
        if (!await _canViewerSeePost(fetchedPost)) return;

        // Yeni reshare entry'si oluştur
        final reshareEntry = {
          'type': 'reshare',
          'post': fetchedPost,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': fetchedPost.originalUserID.isNotEmpty
              ? fetchedPost.originalUserID
              : fetchedPost.userID,
          'originalPostID': fetchedPost.originalPostID.isNotEmpty
              ? fetchedPost.originalPostID
              : fetchedPost.docID,
        };

        // En üste ekle
        feedReshareEntries.insert(0, reshareEntry);
      } else {
        if (!await _canViewerSeePost(post)) return;
        // Mevcut post'tan reshare entry'si oluştur
        final reshareEntry = {
          'type': 'reshare',
          'post': post,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': post.originalUserID.isNotEmpty
              ? post.originalUserID
              : post.userID,
          'originalPostID':
              post.originalPostID.isNotEmpty ? post.originalPostID : post.docID,
        };

        // En üste ekle
        feedReshareEntries.insert(0, reshareEntry);
      }

      // UI güncellensin diye bir frame bekle, sonra scroll pozisyonunu geri yükle
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scrollController.hasClients) {
          // Yeni item eklendi, bu nedenle eski pozisyona geri dön
          // Ama yeni item height'ı da hesaba kat
          await scrollController.animateTo(
            currentOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('addNewReshareEntryWithoutScroll error: $e');
    }
  }

  // Reshare entry'sini kaldır
  void removeReshareEntry(String postId, String reshareUserID) {
    try {
      feedReshareEntries.removeWhere((entry) {
        final entryPost = entry['post'] as PostsModel;
        final entryUserID = entry['reshareUserID'] as String;
        return entryPost.docID == postId && entryUserID == reshareUserID;
      });
    } catch (e) {
      print('removeReshareEntry error: $e');
    }
  }
}
