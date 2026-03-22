import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/explore_repository.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content_controller.dart';
import 'package:turqappv2/Modules/Agenda/TopTags/top_tags_repository.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Utils/account_status_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';

import '../../Models/posts_model.dart';

part 'explore_controller_recent_search_part.dart';
part 'explore_controller_feed_part.dart';
part 'explore_controller_search_part.dart';

class ExploreController extends GetxController {
  static ExploreController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ExploreController());
  }

  static ExploreController? maybeFind() {
    final isRegistered = Get.isRegistered<ExploreController>();
    if (!isRegistered) return null;
    return Get.find<ExploreController>();
  }

  static const double _verticalExploreAspectMax = 0.7;
  static const String _recentSearchUsersCachePrefix =
      'explore_recent_search_users_v1_';
  static const int _recentSearchUsersLimit = 100;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 300);
  var selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  RxString searchText = "".obs;
  RxList<OgrenciModel> searchedList = <OgrenciModel>[].obs;
  RxList<OgrenciModel> recentSearchUsers = <OgrenciModel>[].obs;
  RxList<HashtagModel> searchedHashtags = <HashtagModel>[].obs;
  RxList<HashtagModel> searchedTags = <HashtagModel>[].obs;
  RxBool showAllRecent = false.obs;
  RxBool isKeyboardOpen = false.obs;
  RxBool isSearchMode = false.obs;
  final scrollController = ScrollController();
  RxList<HashtagModel> trendingTags = <HashtagModel>[].obs;

  // -------------- Sana Özel (explorePosts) --------------
  final ScrollController exploreScroll = ScrollController();
  RxList<PostsModel> explorePosts = <PostsModel>[].obs;
  DocumentSnapshot? lastExploreDoc;
  RxBool exploreHasMore = true.obs;
  RxBool exploreIsLoading = false.obs;
  final RxBool explorePreviewSuspended = false.obs;
  final RxInt explorePreviewFocusIndex = (-1).obs;

  // -------------- Videolar --------------
  final ScrollController videoScroll = ScrollController();
  RxList<PostsModel> exploreVideos = <PostsModel>[].obs;
  DocumentSnapshot? lastVideoDoc;
  RxBool videoHasMore = true.obs;
  RxBool videoIsLoading = false.obs;

  // -------------- Fotoğraflar --------------
  final ScrollController photoScroll = ScrollController();
  RxList<PostsModel> explorePhotos = <PostsModel>[].obs;
  DocumentSnapshot? lastPhotoDoc;
  RxBool photoHasMore = true.obs;
  RxBool photoIsLoading = false.obs;

  // -------------- FLOODS --------------
  final ScrollController floodsScroll = ScrollController();
  RxList<PostsModel> exploreFloods = <PostsModel>[].obs;
  DocumentSnapshot? lastFloodsDoc;
  RxBool floodsHasMore = true.obs;
  RxBool floodsIsLoading = false.obs;
  final RxInt floodsVisibleIndex = (-1).obs;
  int? lastFloodVisibleIndex;
  String? _pendingFloodDocId;
  RxBool showScrollToTop = false.obs;
  final RxSet<String> followingIDs = <String>{}.obs;
  // Boş sayfa tespit sayaçları (filtre sonrası görünür içerik çıkmadığında)
  int _exploreEmptyScans = 0;
  int _videoEmptyScans = 0;
  int _photoEmptyScans = 0;
  int _floodsEmptyScans = 0;
  // ... diğer kodlar
  UserProfileCacheService get _userCache => UserProfileCacheService.ensure();
  UserSubcollectionRepository get _subcollectionRepository =>
      UserSubcollectionRepository.ensure();
  TopTagsRepository get _topTagsRepository => TopTagsRepository.ensure();
  ExploreRepository get _exploreRepository => ExploreRepository.ensure();
  VisibilityPolicyService get _visibilityPolicy =>
      VisibilityPolicyService.ensure();
  Worker? _currentUserWorker;
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  String _recentSearchReloadKey = '';

  @override
  void onInit() {
    super.onInit();
    _applyUserCacheQuota();
    unawaited(_loadRecentSearchUsersCache());
    UserAnalyticsService.instance.trackFeatureUsage('explore_open');
    fetchTrendingTags();
    unawaited(_quickFillExploreFromPoolAndBootstrap());
    _bindRecentSearchUsers();
    _bindFollowingListener();
    exploreScroll.addListener(() {
      if (exploreScroll.position.pixels >=
          exploreScroll.position.maxScrollExtent - 200) {
        fetchExplorePosts();
      }

      _syncScrollToTopVisibility(exploreScroll.offset);
    });

    videoScroll.addListener(() {
      if (videoScroll.position.pixels >=
          videoScroll.position.maxScrollExtent - 200) {
        fetchVideo();
      }

      _syncScrollToTopVisibility(videoScroll.offset);
    });

    photoScroll.addListener(() {
      if (photoScroll.position.pixels >=
          photoScroll.position.maxScrollExtent - 200) {
        fetchPhoto();
      }

      _syncScrollToTopVisibility(photoScroll.offset);
    });

    floodsScroll.addListener(() {
      if (floodsScroll.position.pixels >=
          floodsScroll.position.maxScrollExtent - 200) {
        fetchFloods();
      }

      _updateFloodVisibleIndex();
      _syncScrollToTopVisibility(floodsScroll.offset);
    });

    searchFocus.addListener(() {
      isKeyboardOpen.value = searchFocus.hasFocus;
      if (searchFocus.hasFocus) {
        isSearchMode.value = true;
      }
    });
  }

  void _syncScrollToTopVisibility(double offset) =>
      _performSyncScrollToTopVisibility(offset);

  String floodSeriesInstanceTag(String docId) => 'explore_series_$docId';

  void disposeFloodContentController(String docId) =>
      _performDisposeFloodContentController(docId);

  void _updateFloodVisibleIndex() => _performUpdateFloodVisibleIndex();

  int resolveFloodSeriesFocusIndex() => _performResolveFloodSeriesFocusIndex();

  void restoreFloodSeriesFocus() => _performRestoreFloodSeriesFocus();

  void capturePendingFloodEntry({int? preferredIndex, PostsModel? model}) =>
      _performCapturePendingFloodEntry(
        preferredIndex: preferredIndex,
        model: model,
      );

  void suspendExplorePreview({int focusIndex = -1}) =>
      _performSuspendExplorePreview(focusIndex: focusIndex);

  void resumeExplorePreview() => _performResumeExplorePreview();

  void _bindFollowingListener() => _performBindFollowingListener();

  Future<void> _fetchFollowingIDs(String uid) => _performFetchFollowingIDs(uid);

  Future<void> fetchExplorePosts() => _performFetchExplorePosts();

  Future<void> _quickFillExploreFromPoolAndBootstrap() =>
      _performQuickFillExploreFromPoolAndBootstrap();

  Future<void> _tryQuickFillExploreFromPool() =>
      _performTryQuickFillExploreFromPool();

  Future<void> _cleanupExplorePoolFill(List<PostsModel> shown) =>
      _performCleanupExplorePoolFill(shown);

  Future<void> _saveExplorePostsToPool(List<PostsModel> posts) =>
      _performSaveExplorePostsToPool(posts);

  bool _isEligibleExplorePost(PostsModel post) =>
      _performIsEligibleExplorePost(post);

  String _exploreCanonicalId(PostsModel post) =>
      _performExploreCanonicalId(post);

  List<PostsModel> _dedupeExplorePosts(List<PostsModel> posts) =>
      _performDedupeExplorePosts(posts);

  Future<List<PostsModel>> _validatePoolPostsAndPrune(List<PostsModel> posts) =>
      _performValidatePoolPostsAndPrune(posts);

  Future<void> fetchTrendingTags() => _performFetchTrendingTags();

  Future<void> fetchVideo() => _performFetchVideo();

  Future<void> fetchPhoto() => _performFetchPhoto();

  Future<void> fetchFloods() => _performFetchFloods();

  Future<List<PostsModel>> _filterByPrivacy(List<PostsModel> items) =>
      _performFilterByPrivacy(items);

  List<PostsModel> _prioritizeCachedVideos(List<PostsModel> items) =>
      _performPrioritizeCachedVideos(items);

  void _scheduleExplorePrefetchFromPosts(List<PostsModel> source) =>
      _performScheduleExplorePrefetchFromPosts(source);

  Future<dynamic> _callTypesenseCallable(
          String callableName, Map<String, dynamic> payload) =>
      _performCallTypesenseCallable(callableName, payload);

  Future<List<OgrenciModel>> _filterPendingOrDeletedUsers(
          List<OgrenciModel> users) =>
      _performFilterPendingOrDeletedUsers(users);

  void onSearchChanged(String value) => _performOnSearchChanged(value);

  void _clearSearchResults() => _performClearSearchResults();

  Future<void> search(String query) => _performSearch(query);

  void resetSearchToDefault() => _performResetSearchToDefault();

  @override
  void onClose() {
    _currentUserWorker?.dispose();
    _currentUserWorker = null;
    _searchDebounce?.cancel();
    exploreScroll.dispose();
    videoScroll.dispose();
    photoScroll.dispose();
    searchController.dispose();
    searchFocus.dispose();
    pageController.dispose();
    super.onClose();
  }

  void goToPage(int index) => _performGoToPage(index);
}
