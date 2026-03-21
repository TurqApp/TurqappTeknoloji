import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Utils/deep_link_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class DeepLinkService extends GetxService {
  static DeepLinkService? maybeFind() {
    if (Get.isRegistered<DeepLinkService>()) {
      return Get.find<DeepLinkService>();
    }
    return null;
  }

  final ShortLinkService _shortLinkService = ShortLinkService();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();
  static const Duration _lookupTtl = Duration(seconds: 30);
  static final Map<String, _PostLookupCache> _postLookupCache =
      <String, _PostLookupCache>{};
  static final Map<String, _JobLookupCache> _jobLookupCache =
      <String, _JobLookupCache>{};
  static final Map<String, _MarketLookupCache> _marketLookupCache =
      <String, _MarketLookupCache>{};
  static final Map<String, _UserLookupCache> _userLookupCache =
      <String, _UserLookupCache>{};
  static final Map<String, _StoryListLookupCache> _storyListLookupCache =
      <String, _StoryListLookupCache>{};
  static final Map<String, _StoryDocLookupCache> _storyDocLookupCache =
      <String, _StoryDocLookupCache>{};
  static const Duration _staleRetention = Duration(minutes: 3);
  static const int _maxLookupEntries = 400;
  bool _started = false;
  bool _handling = false;
  final RxBool initialLinkResolved = false.obs;

  T _ensureController<T>(T Function() create) {
    if (Get.isRegistered<T>()) {
      return Get.find<T>();
    }
    return Get.put<T>(create());
  }

  Future<_PostLookupCache> _getPostLookup(String postId) async {
    _pruneStaleLookups();
    final cached = _postLookupCache[postId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _lookupTtl) {
      return cached;
    }
    final doc =
        (await PostRepository.ensure().fetchPostCardsByIds([postId]))[postId];
    final lookup = _PostLookupCache(
      model: doc,
      cachedAt: DateTime.now(),
    );
    _postLookupCache[postId] = lookup;
    return lookup;
  }

  Future<_JobLookupCache> _getJobLookup(String jobId) async {
    _pruneStaleLookups();
    final cached = _jobLookupCache[jobId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _lookupTtl) {
      return cached;
    }
    final lookup = _JobLookupCache(
      model: await JobRepository.ensure().fetchById(
        jobId,
        preferCache: true,
      ),
      cachedAt: DateTime.now(),
    );
    _jobLookupCache[jobId] = lookup;
    return lookup;
  }

  Future<_UserLookupCache> _getUserLookup(String userId) async {
    _pruneStaleLookups();
    final cached = _userLookupCache[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _lookupTtl) {
      return cached;
    }
    final data = await _userSummaryResolver.resolve(
      userId,
      preferCache: true,
    );
    final lookup = _UserLookupCache(
      data: data,
      cachedAt: DateTime.now(),
    );
    _userLookupCache[userId] = lookup;
    return lookup;
  }

  Future<_MarketLookupCache> _getMarketLookup(String itemId) async {
    _pruneStaleLookups();
    final cached = _marketLookupCache[itemId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _lookupTtl) {
      return cached;
    }
    final lookup = _MarketLookupCache(
      model: await MarketRepository.ensure().fetchById(
        itemId,
        preferCache: true,
      ),
      cachedAt: DateTime.now(),
    );
    _marketLookupCache[itemId] = lookup;
    return lookup;
  }

  Future<_StoryDocLookupCache> _getStoryDocLookup(String storyId) async {
    _pruneStaleLookups();
    final cached = _storyDocLookupCache[storyId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _lookupTtl) {
      return cached;
    }
    final storyDoc =
        await StoryRepository.ensure().getStoryRaw(storyId, preferCache: true);
    final lookup = _StoryDocLookupCache(
      data: storyDoc,
      cachedAt: DateTime.now(),
    );
    _storyDocLookupCache[storyId] = lookup;
    return lookup;
  }

  void start() {
    if (_started) return;
    _started = true;
    initialLinkResolved.value = false;
    initialLinkResolved.value = true;
  }

  Future<void> handle(Uri uri) async {
    if (_handling) return;
    final parsed = _parse(uri);
    if (parsed == null) return;

    _handling = true;
    try {
      if (CurrentUserService.instance.userId.isEmpty) {
        return;
      }

      // Function erişimi olmasa bile fallback eğitim linkleri direkt açılsın.
      if (parsed.type == 'edu' &&
          (parsed.id.startsWith('question-') ||
              parsed.id.startsWith('scholarship-') ||
              parsed.id.startsWith('practiceexam-') ||
              parsed.id.startsWith('pastquestion-') ||
              parsed.id.startsWith('answerkey-') ||
              parsed.id.startsWith('tutoring-') ||
              parsed.id.startsWith('job-'))) {
        await _openEducationLink(parsed.id);
        return;
      }
      if (parsed.type == 'market') {
        await _openMarket(parsed.id);
        return;
      }

      final resolved = await _shortLinkService.resolve(
        type: parsed.type,
        id: parsed.id,
      );

      final data = Map<String, dynamic>.from(
        resolved['data'] as Map? ?? const {},
      );
      final entityId = (data['entityId'] ?? '').toString().trim();
      if (entityId.isEmpty) {
        final handled = await _tryDirectFallback(parsed);
        if (!handled) {
          AppSnackbar('common.info'.tr, 'deep_link.resolve_failed'.tr);
        }
        return;
      }

      switch (parsed.type) {
        case 'post':
          await _openPost(entityId);
          return;
        case 'story':
          await _openStory(entityId);
          return;
        case 'user':
          await _openUserProfile(entityId);
          return;
        case 'edu':
          await _openEducationLink(entityId);
          return;
        case 'market':
          await _openMarket(entityId);
          return;
      }
    } catch (_) {
      final handled = await _tryDirectFallback(parsed);
      if (!handled) {
        AppSnackbar('common.info'.tr, 'deep_link.open_failed'.tr);
      }
    } finally {
      _handling = false;
    }
  }

  Future<bool> _tryDirectFallback(_ParsedDeepLink parsed) async {
    final rawId = parsed.id.trim();
    if (rawId.isEmpty) return false;
    try {
      switch (parsed.type) {
        case 'post':
          await _openPost(rawId);
          return true;
        case 'story':
          await _openStory(rawId);
          return true;
        case 'user':
          await _openUserProfile(rawId);
          return true;
        case 'edu':
          await _openEducationLink(rawId);
          return true;
        case 'market':
          await _openMarket(rawId);
          return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  _ParsedDeepLink? _parse(Uri uri) {
    final scheme = normalizeLowercase(uri.scheme);
    final host = normalizeLowercase(uri.host);
    final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();

    if (scheme == 'http' || scheme == 'https') {
      if (!(host == 'turqapp.com' ||
          host == 'www.turqapp.com' ||
          host == 'go.turqapp.com' ||
          host == 'turqqapp.com' ||
          host == 'www.turqqapp.com' ||
          host == 'go.turqqapp.com')) {
        return null;
      }
      if (segments.length < 2) return null;
      final type = normalizeDeepLinkType(segments[0]);
      if (type == null) return null;
      final id = normalizeDeepLinkId(segments[1]);
      if (id.isEmpty) return null;
      return _ParsedDeepLink(type: type, id: id);
    }

    if (scheme == 'turqapp') {
      if (host.isNotEmpty) {
        final mappedHostType = normalizeDeepLinkType(host);
        if (mappedHostType != null && segments.isNotEmpty) {
          final id = normalizeDeepLinkId(segments.first);
          if (id.isEmpty) return null;
          return _ParsedDeepLink(type: mappedHostType, id: id);
        }
      }
      if (segments.length >= 2) {
        final type = normalizeDeepLinkType(segments[0]);
        if (type != null) {
          final id = normalizeDeepLinkId(segments[1]);
          if (id.isEmpty) return null;
          return _ParsedDeepLink(type: type, id: id);
        }
      }
    }

    return null;
  }

  Future<void> _openPost(String postId) async {
    final lookup = await _getPostLookup(postId);
    final model = lookup.model;
    if (model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.post_not_found'.tr);
      return;
    }
    if (model.deletedPost) {
      AppSnackbar('common.info'.tr, 'notify_reader.post_removed'.tr);
      return;
    }

    if (!await _canOpenUserContent(model.userID)) {
      return;
    }

    if (model.video.trim().isNotEmpty) {
      await Get.to(() => SingleShortView(
            startModel: model,
            startList: [model],
          ));
      return;
    }

    if (model.floodCount > 1) {
      await Get.to(() => FloodListing(mainModel: model));
      return;
    }

    if (model.img.isNotEmpty) {
      await Get.to(() => PhotoShorts(
            fetchedList: [model],
            startModel: model,
          ));
      return;
    }

    // İçerik tipi çözülemezse web fallback
    await RedirectionLink().goToLink('https://turqapp.com/p/$postId');
  }

  Future<void> _openStory(String storyId) async {
    final storyLookup = await _getStoryDocLookup(storyId);
    final storyData = storyLookup.data;
    if (storyData == null) {
      AppSnackbar('common.info'.tr, 'deep_link.story_not_found'.tr);
      return;
    }
    if ((storyData['deleted'] ?? false) == true) {
      AppSnackbar('common.info'.tr, 'deep_link.story_removed'.tr);
      return;
    }

    final userId = (storyData['userId'] ?? '').toString().trim();
    if (userId.isEmpty) {
      AppSnackbar('common.info'.tr, 'deep_link.story_owner_missing'.tr);
      return;
    }

    final userLookup = await _getUserLookup(userId);
    final userData = userLookup.data;
    if (userData == null) {
      AppSnackbar('common.info'.tr, 'deep_link.story_owner_missing'.tr);
      return;
    }
    if (!await _canOpenUserContent(userId, summary: userData)) {
      return;
    }

    final stories = await _fetchStoriesByUserIndexSafe(userId);

    if (stories.isEmpty) {
      AppSnackbar('common.info'.tr, 'deep_link.story_not_found'.tr);
      return;
    }

    final index = stories.indexWhere((e) => e.id == storyId);
    if (index > 0) {
      final target = stories.removeAt(index);
      stories.insert(0, target);
    }

    final user = StoryUserModel(
      nickname: userData.preferredName.trim(),
      avatarUrl: userData.avatarUrl.trim(),
      fullName: userData.displayName.trim(),
      userID: userId,
      stories: stories,
    );

    await Get.to(() => StoryViewer(
          startedUser: user,
          storyOwnerUsers: [user],
        ));
  }

  Future<void> _openUserProfile(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      AppSnackbar('common.info'.tr, 'notify_reader.profile_open_failed'.tr);
      return;
    }
    final lookup = await _getUserLookup(normalizedUserId);
    final userData = lookup.data;
    if (userData == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.profile_open_failed'.tr);
      return;
    }
    if (!await _canOpenUserContent(normalizedUserId, summary: userData)) {
      return;
    }
    Get.to(() => SocialProfile(userID: normalizedUserId));
  }

  Future<bool> _canOpenUserContent(
    String userId, {
    UserSummary? summary,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      AppSnackbar('common.info'.tr, 'notify_reader.profile_open_failed'.tr);
      return false;
    }

    final resolvedSummary =
        summary ?? await _userSummaryResolver.resolve(normalizedUserId);
    if (resolvedSummary == null || resolvedSummary.isDeleted) {
      AppSnackbar('common.info'.tr, 'notify_reader.profile_open_failed'.tr);
      return false;
    }

    final followingIds = await _visibilityPolicy.loadViewerFollowingIds();
    final canOpen = _visibilityPolicy.canViewerSeeAuthorFromSummary(
      authorUserId: normalizedUserId,
      followingIds: followingIds,
      isPrivate: resolvedSummary.isPrivate,
      isDeleted: resolvedSummary.isDeleted,
    );
    if (canOpen) return true;

    AppSnackbar(
        'common.info'.tr, 'social_profile.private_follow_to_see_posts'.tr);
    return false;
  }

  Future<void> _openMarket(String itemId) async {
    final lookup = await _getMarketLookup(itemId);
    final item = lookup.model;
    if (item == null) {
      AppSnackbar('common.info'.tr, 'deep_link.listing_not_found'.tr);
      return;
    }
    await Get.to(() => MarketDetailView(item: item));
  }

  Future<List<StoryModel>> _fetchStoriesByUserIndexSafe(String userId) async {
    _pruneStaleLookups();
    final cached = _storyListLookupCache[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _lookupTtl) {
      return List<StoryModel>.from(cached.stories);
    }

    final stories = await StoryRepository.ensure().getStoriesForUser(
      userId,
      preferCache: true,
      includeDeleted: false,
    );
    _storyListLookupCache[userId] = _StoryListLookupCache(
      stories: List<StoryModel>.from(stories),
      cachedAt: DateTime.now(),
    );
    return stories;
  }

  void _pruneStaleLookups() {
    final now = DateTime.now();
    bool isStale(DateTime t) => now.difference(t) > _staleRetention;

    _postLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _jobLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _marketLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _userLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _storyListLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _storyDocLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _trimOldestIfNeeded();
  }

  void _trimOldestIfNeeded() {
    void trimMap<T>(
      Map<String, T> map,
      DateTime Function(T value) cachedAt,
    ) {
      if (map.length <= _maxLookupEntries) return;
      final keysByAge = map.entries.toList()
        ..sort((a, b) => cachedAt(a.value).compareTo(cachedAt(b.value)));
      final removeCount = map.length - _maxLookupEntries;
      for (var i = 0; i < removeCount; i++) {
        map.remove(keysByAge[i].key);
      }
    }

    trimMap<_PostLookupCache>(_postLookupCache, (v) => v.cachedAt);
    trimMap<_JobLookupCache>(_jobLookupCache, (v) => v.cachedAt);
    trimMap<_MarketLookupCache>(_marketLookupCache, (v) => v.cachedAt);
    trimMap<_UserLookupCache>(_userLookupCache, (v) => v.cachedAt);
    trimMap<_StoryListLookupCache>(_storyListLookupCache, (v) => v.cachedAt);
    trimMap<_StoryDocLookupCache>(_storyDocLookupCache, (v) => v.cachedAt);
  }

  Future<void> _openEducationLink(String entityId) async {
    final normalized = normalizeSearchText(entityId);
    if (normalized.startsWith('job:')) {
      await _openJob(entityId.split(':').last.trim());
      return;
    }

    final navController = _ensureController<NavBarController>(
      () => NavBarController(),
    );
    final educationController = _ensureController<EducationController>(
      () => EducationController(),
    );

    // Eğitim ana ekranı sekmesi
    navController.changeIndex(3);

    int targetTab = 0;
    if (normalized.startsWith('scholarship:')) {
      targetTab = 0;
    } else if (normalized.startsWith('question:') ||
        normalized.startsWith('question-')) {
      targetTab = 1;
    } else if (normalized.startsWith('practiceexam:')) {
      targetTab = 2;
    } else if (normalized.startsWith('pastquestion:')) {
      targetTab = 3;
    } else if (normalized.startsWith('answerkey:')) {
      targetTab = 4;
    } else if (normalized.startsWith('tutoring:')) {
      targetTab = 5;
    } else if (normalized.startsWith('job:')) {
      targetTab = 6;
    }

    educationController.onTabTap(targetTab);
  }

  Future<void> _openJob(String jobId) async {
    final cleanId = jobId.trim();
    if (cleanId.isEmpty) {
      AppSnackbar('common.info'.tr, 'deep_link.listing_not_found'.tr);
      return;
    }

    final lookup = await _getJobLookup(cleanId);
    final model = lookup.model;
    if (model == null) {
      AppSnackbar('common.info'.tr, 'deep_link.listing_not_found'.tr);
      return;
    }
    if (model.ended) {
      AppSnackbar('common.info'.tr, 'deep_link.listing_removed'.tr);
      return;
    }

    await Get.to(() => JobDetails(model: model));
  }

  @override
  void onClose() {
    _started = false;
    super.onClose();
  }
}

class _ParsedDeepLink {
  final String type;
  final String id;

  _ParsedDeepLink({required this.type, required this.id});
}

class _PostLookupCache {
  final PostsModel? model;
  final DateTime cachedAt;

  const _PostLookupCache({
    required this.model,
    required this.cachedAt,
  });
}

class _JobLookupCache {
  final JobModel? model;
  final DateTime cachedAt;

  const _JobLookupCache({
    required this.model,
    required this.cachedAt,
  });
}

class _MarketLookupCache {
  final dynamic model;
  final DateTime cachedAt;

  const _MarketLookupCache({
    required this.model,
    required this.cachedAt,
  });
}

class _UserLookupCache {
  final UserSummary? data;
  final DateTime cachedAt;

  const _UserLookupCache({
    required this.data,
    required this.cachedAt,
  });
}

class _StoryListLookupCache {
  final List<StoryModel> stories;
  final DateTime cachedAt;

  const _StoryListLookupCache({
    required this.stories,
    required this.cachedAt,
  });
}

class _StoryDocLookupCache {
  final Map<String, dynamic>? data;
  final DateTime cachedAt;

  const _StoryDocLookupCache({
    required this.data,
    required this.cachedAt,
  });
}
