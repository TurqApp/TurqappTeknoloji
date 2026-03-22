import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/feed_render_coordinator.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Utils/account_status_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/reshare_helper.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../Core/Services/IndexPool/index_pool_store.dart';
import '../../Core/Services/ContentPolicy/content_policy.dart';
import '../../Core/Services/agenda_shuffle_cache_service.dart';
import '../../Core/Services/user_profile_cache_service.dart';
import '../NavBar/nav_bar_controller.dart';
import 'AgendaContent/agenda_content_controller.dart';

part 'agenda_controller_feed_part.dart';
part 'agenda_controller_loading_part.dart';
part 'agenda_controller_playback_part.dart';
part 'agenda_controller_render_part.dart';
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
  static AgendaController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      AgendaController(),
      permanent: permanent,
    );
  }

  static AgendaController? maybeFind() {
    final isRegistered = Get.isRegistered<AgendaController>();
    if (!isRegistered) return null;
    return Get.find<AgendaController>();
  }

  final scrollController = ScrollController();
  UserProfileCacheService get _profileCache => UserProfileCacheService.ensure();
  UserSummaryResolver get _userSummaryResolver => UserSummaryResolver.ensure();
  VisibilityPolicyService get _visibilityPolicy =>
      VisibilityPolicyService.ensure();
  PostRepository get _postRepository => PostRepository.ensure();
  FeedSnapshotRepository get _feedSnapshotRepository =>
      FeedSnapshotRepository.ensure();
  FeedRenderCoordinator get _feedRenderCoordinator =>
      FeedRenderCoordinator.ensure();
  RuntimeInvariantGuard get _invariantGuard => RuntimeInvariantGuard.ensure();

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
  final RxBool playbackSuspended = false.obs;
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
  Timer? _scrollIdleDebounce;
  Timer? _agendaRetryTimer;
  int _agendaRetryCount = 0;
  Worker? _mergedFeedWorker;
  Worker? _filteredFeedWorker;
  Worker? _renderFeedWorker;
  final Map<int, double> _visibleFractions = <int, double>{};
  final Map<int, DateTime> _visibleUpdatedAt = <int, DateTime>{};
  String? _lastPlaybackWindowSignature;
  String? _pendingCenteredDocId;
  int _prefetchedThumbnailPostCount = 0;

  // Video içerik thumbnail ile render edilebilir; autoplay sadece HLS hazırsa başlar.
  bool _isRenderablePost(PostsModel post) {
    if (!post.hasVideoSignal) return true; // text/photo post
    return post.hasRenderableVideoCard;
  }

  bool canAutoplayInTests(PostsModel post) => _canAutoplayVideoPost(post);

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
    return _visibilityPolicy.canViewerSeeAuthorFromSummary(
      authorUserId: post.userID,
      followingIds: followingIDs,
      isPrivate: isPrivate,
      isDeleted: false,
    );
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
    return 'app.name'.tr;
  }

  String get currentUserLocationCity {
    return CurrentUserService.instance.preferredLocationCity;
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
      if (playbackSuspended.value) return;
      if (agendaList.isEmpty && !isLoading.value) {
        unawaited(fetchAgendaBigData(initial: true));
      }
    });
    scrollController.addListener(_onScroll);
    navBarController = NavBarController.ensure();
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
      if (playbackSuspended.value) return;
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
    _scrollIdleDebounce?.cancel();
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

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) =>
      _performOnPostVisibilityChanged(modelIndex, visibleFraction);

  void suspendPlaybackForOverlay() {
    playbackSuspended.value = true;
    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}
  }

  void resumePlaybackAfterOverlay() {
    playbackSuspended.value = false;
    resumeFeedPlayback();
  }

  void _scheduleVisibilityEvaluation({
    required double playThreshold,
    required double stopThreshold,
  }) =>
      _performScheduleVisibilityEvaluation(
        playThreshold: playThreshold,
        stopThreshold: stopThreshold,
      );

  void _evaluateCenteredPlayback({
    required double playThreshold,
    required double stopThreshold,
  }) =>
      _performEvaluateCenteredPlayback(
        playThreshold: playThreshold,
        stopThreshold: stopThreshold,
      );

  void _trackPlaybackWindow() => _performTrackPlaybackWindow();

  void _bindFollowingListener() {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    // İlk yükleme: pull-based (SWR pattern)
    _fetchFollowingAndReshares(uid);
  }

  void _bindMergedFeedEntries() => _performBindMergedFeedEntries();

  void _bindFilteredFeedEntries() => _performBindFilteredFeedEntries();

  void _bindRenderFeedEntries() => _performBindRenderFeedEntries();

  void _rebuildMergedFeedEntries() => _performRebuildMergedFeedEntries();

  void _rebuildFilteredFeedEntries() => _performRebuildFilteredFeedEntries();

  void _rebuildRenderFeedEntries() => _performRebuildRenderFeedEntries();

  /// Pull-based following + reshares fetch (realtime listener yerine).
  /// Dışarıdan da çağrılabilir (ör. follow/unfollow sonrası).
  // Yeni yüklenen gönderileri en üste almak için güvenli yenileme
}
