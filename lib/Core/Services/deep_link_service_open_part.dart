part of 'deep_link_service.dart';

extension DeepLinkServiceOpenPart on DeepLinkService {
  bool _deepLinkAsBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return fallback;
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  Future<void> _performOpenPost(String postId) async {
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

    await RedirectionLink().goToLink('https://turqapp.com/p/$postId');
  }

  Future<void> _performOpenStory(String storyId) async {
    final storyLookup = await _getStoryDocLookup(storyId);
    final storyData = storyLookup.data;
    if (storyData == null) {
      AppSnackbar('common.info'.tr, 'deep_link.story_not_found'.tr);
      return;
    }
    if (_deepLinkAsBool(storyData['deleted'], fallback: false)) {
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

  Future<void> _performOpenUserProfile(String userId) async {
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

  Future<bool> _performCanOpenUserContent(
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
      'common.info'.tr,
      'social_profile.private_follow_to_see_posts'.tr,
    );
    return false;
  }

  Future<void> _performOpenMarket(String itemId) async {
    final lookup = await _getMarketLookup(itemId);
    final item = lookup.model;
    if (item == null) {
      AppSnackbar('common.info'.tr, 'deep_link.listing_not_found'.tr);
      return;
    }
    await Get.to(() => MarketDetailView(item: item));
  }

  Future<void> _performOpenEducationLink(String entityId) async {
    final normalized = normalizeSearchText(entityId);
    if (normalized.startsWith('job:')) {
      await _openJob(entityId.split(':').last.trim());
      return;
    }

    final navController = ensureNavBarController();
    final educationController = ensureEducationController();

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

  Future<void> _performOpenJob(String jobId) async {
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
}
