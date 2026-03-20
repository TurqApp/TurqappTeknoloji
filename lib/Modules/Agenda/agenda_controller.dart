import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/feed_render_coordinator.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/reshare_helper.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../Core/Services/IndexPool/index_pool_store.dart';
import '../../Core/Services/ContentPolicy/content_policy.dart';
import '../../Core/Services/agenda_shuffle_cache_service.dart';
import '../../Core/Services/user_profile_cache_service.dart';
import '../NavBar/nav_bar_controller.dart';
import 'AgendaContent/agenda_content_controller.dart';
import '../../Services/current_user_service.dart';

part 'agenda_controller_feed_part.dart';
part 'agenda_controller_loading_part.dart';
part 'agenda_controller_reshare_part.dart';

enum FeedViewMode { forYou, following, city }

class _AgendaSourcePage {
  const _AgendaSourcePage({
    required this.items,
    required this.lastDoc,
    required this.usesPrimaryFeed,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool usesPrimaryFeed;
}

class AgendaController extends GetxController {
  final scrollController = ScrollController();
  UserProfileCacheService get _profileCache =>
      Get.isRegistered<UserProfileCacheService>()
          ? Get.find<UserProfileCacheService>()
          : Get.put(UserProfileCacheService(), permanent: true);
  UserSummaryResolver get _userSummaryResolver => UserSummaryResolver.ensure();
  PostRepository get _postRepository => PostRepository.ensure();
  FeedSnapshotRepository get _feedSnapshotRepository =>
      FeedSnapshotRepository.ensure();
  FeedRenderCoordinator get _feedRenderCoordinator =>
      FeedRenderCoordinator.ensure();

  final RxList<PostsModel> agendaList = <PostsModel>[].obs;
  final RxList<Map<String, dynamic>> mergedFeedEntries =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFeedEntries =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> renderFeedEntries =
      <Map<String, dynamic>>[].obs;
  final Map<String, GlobalKey> _agendaKeys = {};

  /// FAB gösterimi için kullanılır. Her frame'de reactive güncelleme yapmak yerine
  /// sadece eşik aşıldığında güncellenir (scroll jank'ı engeller).
  final RxBool showFAB = true.obs;
  final RxInt centeredIndex = 0.obs;
  int? lastCenteredIndex;
  var isMuted = false.obs;
  DocumentSnapshot? lastDoc;
  bool _usePrimaryFeedPaging = true;
  final RxBool hasMore = true.obs;
  final RxBool isLoading = false.obs;
  final int fetchLimit = 50;
  final pauseAll = false.obs;
  late NavBarController navBarController;
  final RxSet<String> highlightDocIDs = <String>{}.obs;
  Timer? _visibilityDebounce;
  Timer? _feedPrefetchDebounce;
  Timer? _agendaRetryTimer;
  int _agendaRetryCount = 0;
  Worker? _mergedFeedWorker;
  Worker? _filteredFeedWorker;
  Worker? _renderFeedWorker;
  final Map<int, double> _visibleFractions = <int, double>{};
  final Map<int, DateTime> _visibleUpdatedAt = <int, DateTime>{};
  String? _lastPlaybackWindowSignature;
  String? _pendingCenteredDocId;

  // Video içerik thumbnail ile render edilebilir; autoplay sadece HLS hazırsa başlar.
  bool _isRenderablePost(PostsModel post) {
    if (!post.hasVideoSignal) return true; // text/photo post
    return post.hasRenderableVideoCard;
  }

  bool _isBlurredIzBirakVideo(PostsModel post, [int? nowMs]) {
    final scheduled = post.scheduledAt.toInt();
    if (scheduled <= 0 || post.video.trim().isEmpty) return false;
    final publishAt =
        scheduled > 0 ? scheduled : post.izBirakYayinTarihi.toInt();
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return publishAt > now;
  }

  bool _canAutoplayVideoPost(PostsModel post, [int? nowMs]) {
    return post.hasPlayableVideo && !_isBlurredIzBirakVideo(post, nowMs);
  }

  Future<bool> _canViewerSeePost(PostsModel post) async {
    if (hiddenPosts.contains(post.docID)) return false;
    if (post.deletedPost == true) return false;
    if (!_isRenderablePost(post)) return false;
    if (await _isUserDeactivated(post.userID)) return false;

    final isPrivate = await _isUserPrivate(post.userID);
    if (!isPrivate) return true;

    final me = FirebaseAuth.instance.currentUser?.uid;
    final isMine = me != null && post.userID == me;
    final follows = followingIDs.contains(post.userID);
    return isMine || follows;
  }

  final RxSet<String> followingIDs = <String>{}.obs;
  final Rx<FeedViewMode> feedViewMode = FeedViewMode.forYou.obs;
  final RxMap<String, int> myReshares =
      <String, int>{}.obs; // postID -> reshare timestamp
  final RxList<Map<String, dynamic>> publicReshareEvents =
      <Map<String, dynamic>>[].obs; // {postID,userID,timeStamp}
  final RxList<Map<String, dynamic>> feedReshareEntries =
      <Map<String, dynamic>>[].obs; // Feed'de görünecek reshare entry'leri
  final Map<String, bool> _userPrivacyCache = {};
  final Map<String, bool> _userDeactivatedCache = {};

  List<String> hiddenPosts = [];
  double lastOffset = 0.0;
  AgendaShuffleCacheService get _shuffleCache =>
      AgendaShuffleCacheService.ensure();
  bool _ensureInitialLoadInFlight = false;
  DateTime? _lastEnsureInitialLoadAt;
  // null => no time window limit
  static const Duration? _agendaWindow = null;
  static const int _reshareScanPostLimit = 12;

  bool get isFollowingMode => feedViewMode.value == FeedViewMode.following;
  bool get isCityMode => feedViewMode.value == FeedViewMode.city;

  String get feedTitle {
    if (isFollowingMode) return 'agenda.following'.tr;
    if (isCityMode) return 'agenda.city'.tr;
    return 'TurqApp';
  }

  String get currentUserLocationCity {
    final user = CurrentUserService.instance.currentUserRx.value;
    final candidates = [
      user?.locationSehir,
      user?.city,
      user?.ikametSehir,
      user?.il,
      user?.ulke,
    ];
    for (final raw in candidates) {
      final value = (raw ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return 'common.country_turkey'.tr;
  }

  void setFeedViewMode(FeedViewMode mode) {
    if (feedViewMode.value == mode) return;
    feedViewMode.value = mode;
  }

  int _agendaCutoffMs(int nowMs) {
    if (_agendaWindow == null) return 0;
    return nowMs - _agendaWindow!.inMilliseconds;
  }

  bool _isInAgendaWindow(num ts, int nowMs) {
    if (_agendaWindow == null) return true;
    final v = ts.toInt();
    return v >= _agendaCutoffMs(nowMs) && v <= nowMs;
  }

  bool _isEligibleAgendaPost(PostsModel post, int nowMs) {
    final ts = post.timeStamp.toInt();
    if (_agendaWindow != null && ts < _agendaCutoffMs(nowMs)) {
      return false;
    }
    if (ts <= nowMs) {
      return true;
    }
    return post.scheduledAt.toInt() > 0;
  }

  Future<List<PostsModel>> _fetchVisiblePublicIzBirakPosts({
    required int nowMs,
    required int cutoffMs,
    int limit = 40,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final effectivePreferCache = cacheOnly ? preferCache : false;
    final publicIzBirakPosts =
        await _postRepository.fetchPublicScheduledIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      preferCache: effectivePreferCache,
      cacheOnly: cacheOnly,
    );
    if (publicIzBirakPosts.isEmpty) return const <PostsModel>[];

    final authorMeta = await _userSummaryResolver.resolveMany(
      publicIzBirakPosts.map((p) => p.userID).toSet().toList(),
      preferCache: effectivePreferCache,
      cacheOnly: cacheOnly,
    );
    return publicIzBirakPosts.where((post) {
      final meta = authorMeta[post.userID];
      final rozet = meta?.rozet.trim() ?? '';
      final isApproved = meta?.isApproved == true;
      if (rozet.isEmpty && !isApproved) return false;
      return true;
    }).toList(growable: false);
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
    navBarController = Get.isRegistered<NavBarController>()
        ? Get.find<NavBarController>()
        : Get.put(NavBarController());
    _bindFollowingListener();
    _bindCenteredIndexListener();
    _bindMergedFeedEntries();
    _bindFilteredFeedEntries();
    _bindRenderFeedEntries();
  }

  @override
  void onReady() {
    super.onReady();

    // 🎯 CRITICAL FIX: İlk açılışta video manuel trigger
    // centeredIndex zaten 0 olduğu için listener tetiklenmiyor
    // Manual olarak ilk videoyu oynatmalıyız
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (agendaList.isNotEmpty && centeredIndex.value == 0) {
        final videoManager = VideoStateManager.instance;
        final firstPost = agendaList[0];
        if (_canAutoplayVideoPost(firstPost)) {
          videoManager.playOnlyThis(firstPost.docID);
        }
      }
      _scheduleFeedPrefetch();
    });
  }

  @override
  void onClose() {
    _mergedFeedWorker?.dispose();
    _filteredFeedWorker?.dispose();
    _renderFeedWorker?.dispose();
    _visibilityDebounce?.cancel();
    _feedPrefetchDebounce?.cancel();
    _agendaRetryTimer?.cancel();
    unawaited(persistWarmLaunchCache());
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  Future<void> addNewReshareEntryWithoutScroll(
    String postId,
    String reshareUserID,
  ) async {
    try {
      final currentOffset =
          scrollController.hasClients ? scrollController.offset : 0.0;
      final post = agendaList.firstWhereOrNull((p) => p.docID == postId);
      if (post == null) {
        final fetchedPost = await _postRepository.fetchPostById(
          postId,
          preferCache: true,
        );
        if (fetchedPost == null) return;
        if (!await _canViewerSeePost(fetchedPost)) return;

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

        feedReshareEntries.insert(0, reshareEntry);
      } else {
        if (!await _canViewerSeePost(post)) return;
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

        feedReshareEntries.insert(0, reshareEntry);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scrollController.hasClients) {
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

  void removeReshareEntry(String postId, String reshareUserID) {
    try {
      feedReshareEntries.removeWhere((entry) {
        final entryPost = entry['post'] as PostsModel;
        final entryUserID = (entry['reshareUserID'] ?? '').toString();
        final entryOriginalPostID =
            (entry['originalPostID'] ?? '').toString().trim();
        final entryPostID = entryPost.docID.trim();
        final normalizedTarget = postId.trim();
        final matchesPost = entryPostID == normalizedTarget ||
            entryOriginalPostID == normalizedTarget ||
            entryPost.originalPostID.trim() == normalizedTarget;
        final matchesUser = entryUserID == reshareUserID;
        return matchesPost && matchesUser;
      });
      feedReshareEntries.refresh();
    } catch (e) {
      print('removeReshareEntry error: $e');
    }
  }

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (modelIndex < 0 || modelIndex >= agendaList.length) return;
    final prev = _visibleFractions[modelIndex];

    // Android'de hızlı scroll sırasında çok sık visibility callback gelir;
    // küçük dalgalanmaları ignore ederek rebuild/focus thrash'i azalt.
    if (GetPlatform.isAndroid &&
        prev != null &&
        (prev - visibleFraction).abs() < 0.08) {
      return;
    }

    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
      _visibleUpdatedAt.remove(modelIndex);
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
      _visibleUpdatedAt[modelIndex] = DateTime.now();
    }

    // Arşiv projedeki daha stabil akış:
    // %80+ görünürlükte oynat, %40 altına düşünce durdur.
    // Böylece üstte çok az görünen video oynatılmaz; merkezdeki video öncelik alır.
    const double playThreshold = 0.80;
    // Stop threshold'u Android'de biraz daha düşük tut:
    // merkez postu gereksiz yere -1 yapıp oynatma/pausa döngüsü oluşturmasın.
    final double stopThreshold = GetPlatform.isAndroid ? 0.25 : 0.40;

    _scheduleVisibilityEvaluation(
      playThreshold: playThreshold,
      stopThreshold: stopThreshold,
    );
  }

  void _scheduleVisibilityEvaluation({
    required double playThreshold,
    required double stopThreshold,
  }) {
    _visibilityDebounce?.cancel();
    _visibilityDebounce = Timer(
      GetPlatform.isAndroid
          ? const Duration(milliseconds: 24)
          : const Duration(milliseconds: 40),
      () => _evaluateCenteredPlayback(
        playThreshold: playThreshold,
        stopThreshold: stopThreshold,
      ),
    );
  }

  void _evaluateCenteredPlayback({
    required double playThreshold,
    required double stopThreshold,
  }) {
    final current = centeredIndex.value;
    var bestIndex = -1;
    var bestFraction = 0.0;

    _visibleFractions.forEach((index, fraction) {
      if (index < 0 || index >= agendaList.length) return;
      if (fraction < playThreshold) return;
      final post = agendaList[index];
      if (!_canAutoplayVideoPost(post)) return;
      if (fraction > bestFraction) {
        bestFraction = fraction;
        bestIndex = index;
      }
    });

    if (bestIndex >= 0) {
      final currentFraction =
          current >= 0 ? (_visibleFractions[current] ?? 0.0) : 0.0;
      final hysteresis = GetPlatform.isAndroid ? 0.10 : 0.06;
      final shouldSwitch = current == -1 ||
          current == bestIndex ||
          currentFraction < playThreshold ||
          bestFraction >= currentFraction + hysteresis;

      if (shouldSwitch && centeredIndex.value != bestIndex) {
        centeredIndex.value = bestIndex;
        lastCenteredIndex = bestIndex;
      }
      _trackPlaybackWindow();
      return;
    }

    if (current >= 0) {
      final currentFraction = _visibleFractions[current] ?? 0.0;
      if (currentFraction < stopThreshold) {
        centeredIndex.value = -1;
      }
    }

    _trackPlaybackWindow();
  }

  void _trackPlaybackWindow() {
    if (!Get.isRegistered<PlaybackKpiService>()) return;
    final centered = centeredIndex.value;
    final activeDocId = centered >= 0 && centered < agendaList.length
        ? agendaList[centered].docID
        : '';
    final visibleCount = _visibleFractions.length;
    var strongestIndex = -1;
    var strongestFraction = 0.0;
    _visibleFractions.forEach((index, fraction) {
      if (fraction > strongestFraction) {
        strongestFraction = fraction;
        strongestIndex = index;
      }
    });
    final signature = <String>[
      '$centered',
      activeDocId,
      '$visibleCount',
      '$strongestIndex',
      strongestFraction.toStringAsFixed(2),
    ].join('|');
    if (signature == _lastPlaybackWindowSignature) return;
    _lastPlaybackWindowSignature = signature;
    Get.find<PlaybackKpiService>().track(
      PlaybackKpiEventType.playbackWindow,
      <String, dynamic>{
        'surface': 'feed',
        'activeIndex': centered,
        'activeDocId': activeDocId,
        'visibleCount': visibleCount,
        'strongestIndex': strongestIndex,
        'strongestFraction': strongestFraction,
      },
    );
  }

  void _bindFollowingListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // İlk yükleme: pull-based (SWR pattern)
    _fetchFollowingAndReshares(uid);
  }

  void _bindMergedFeedEntries() {
    _mergedFeedWorker?.dispose();
    _mergedFeedWorker = everAll(
      [agendaList, feedReshareEntries],
      (_) => _rebuildMergedFeedEntries(),
    );
    _rebuildMergedFeedEntries();
  }

  void _bindFilteredFeedEntries() {
    _filteredFeedWorker?.dispose();
    _filteredFeedWorker = everAll(
      [
        mergedFeedEntries,
        feedViewMode,
        followingIDs,
        CurrentUserService.instance.currentUserRx,
      ],
      (_) => _rebuildFilteredFeedEntries(),
    );
    _rebuildFilteredFeedEntries();
  }

  void _bindRenderFeedEntries() {
    _renderFeedWorker?.dispose();
    _renderFeedWorker = ever<List<Map<String, dynamic>>>(
      filteredFeedEntries,
      (_) => _rebuildRenderFeedEntries(),
    );
    _rebuildRenderFeedEntries();
  }

  void _rebuildMergedFeedEntries() {
    if (agendaList.isEmpty && feedReshareEntries.isEmpty) {
      mergedFeedEntries.clear();
      return;
    }
    final merged = _feedRenderCoordinator.buildMergedEntries(
      agendaList: agendaList.toList(growable: false),
      feedReshareEntries: feedReshareEntries.toList(growable: false),
    );
    final patch = _feedRenderCoordinator.buildPatch(
      previous: mergedFeedEntries.toList(growable: false),
      next: merged,
      reason: 'merged_feed_rebuild',
    );
    _feedRenderCoordinator.applyPatch(mergedFeedEntries, patch);
  }

  void _rebuildFilteredFeedEntries() {
    if (mergedFeedEntries.isEmpty) {
      filteredFeedEntries.clear();
      return;
    }
    final filtered = _feedRenderCoordinator.filterEntries(
      mergedEntries: mergedFeedEntries.toList(growable: false),
      isFollowingMode: isFollowingMode,
      isCityMode: isCityMode,
      followingIds: followingIDs.toSet(),
      city: currentUserLocationCity,
    );
    final patch = _feedRenderCoordinator.buildPatch(
      previous: filteredFeedEntries.toList(growable: false),
      next: filtered,
      reason: 'filtered_feed_rebuild',
    );
    _feedRenderCoordinator.applyPatch(filteredFeedEntries, patch);
  }

  void _rebuildRenderFeedEntries() {
    if (filteredFeedEntries.isEmpty) {
      renderFeedEntries.clear();
      return;
    }
    final renderEntries = _feedRenderCoordinator.buildRenderEntries(
      filteredEntries: filteredFeedEntries.toList(growable: false),
    );
    final patch = _feedRenderCoordinator.buildPatch(
      previous: renderFeedEntries.toList(growable: false),
      next: renderEntries,
      reason: 'render_feed_rebuild',
    );
    _feedRenderCoordinator.applyPatch(renderFeedEntries, patch);
  }

  /// Pull-based following + reshares fetch (realtime listener yerine).
  /// Dışarıdan da çağrılabilir (ör. follow/unfollow sonrası).
  // Yeni yüklenen gönderileri en üste almak için güvenli yenileme
}
