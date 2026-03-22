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

part 'deep_link_service_lookup_part.dart';
part 'deep_link_service_parse_part.dart';
part 'deep_link_service_open_part.dart';

class DeepLinkService extends GetxService {
  static DeepLinkService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(DeepLinkService(), permanent: true);
  }

  static DeepLinkService? maybeFind() {
    final isRegistered = Get.isRegistered<DeepLinkService>();
    if (!isRegistered) return null;
    return Get.find<DeepLinkService>();
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

  Future<_PostLookupCache> _getPostLookup(String postId) =>
      _performGetPostLookup(postId);

  Future<_JobLookupCache> _getJobLookup(String jobId) =>
      _performGetJobLookup(jobId);

  Future<_UserLookupCache> _getUserLookup(String userId) =>
      _performGetUserLookup(userId);

  Future<_MarketLookupCache> _getMarketLookup(String itemId) =>
      _performGetMarketLookup(itemId);

  Future<_StoryDocLookupCache> _getStoryDocLookup(String storyId) =>
      _performGetStoryDocLookup(storyId);

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
      if (CurrentUserService.instance.effectiveUserId.isEmpty) {
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

  Future<bool> _tryDirectFallback(_ParsedDeepLink parsed) =>
      _performTryDirectFallback(parsed);

  _ParsedDeepLink? _parse(Uri uri) => _performParse(uri);

  Future<void> _openPost(String postId) => _performOpenPost(postId);

  Future<void> _openStory(String storyId) => _performOpenStory(storyId);

  Future<void> _openUserProfile(String userId) =>
      _performOpenUserProfile(userId);

  Future<bool> _canOpenUserContent(
    String userId, {
    UserSummary? summary,
  }) =>
      _performCanOpenUserContent(
        userId,
        summary: summary,
      );

  Future<void> _openMarket(String itemId) => _performOpenMarket(itemId);

  Future<List<StoryModel>> _fetchStoriesByUserIndexSafe(String userId) =>
      _performFetchStoriesByUserIndexSafe(userId);

  void _pruneStaleLookups() => _performPruneStaleLookups();

  void _trimOldestIfNeeded() => _performTrimOldestIfNeeded();

  Future<void> _openEducationLink(String entityId) =>
      _performOpenEducationLink(entityId);

  Future<void> _openJob(String jobId) => _performOpenJob(jobId);

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
