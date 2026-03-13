import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';

class DeepLinkService extends GetxService {
  final AppLinks _appLinks = AppLinks();
  final ShortLinkService _shortLinkService = ShortLinkService();
  static const Duration _lookupTtl = Duration(seconds: 30);
  static final Map<String, _PostLookupCache> _postLookupCache =
      <String, _PostLookupCache>{};
  static final Map<String, _JobLookupCache> _jobLookupCache =
      <String, _JobLookupCache>{};
  static final Map<String, _UserLookupCache> _userLookupCache =
      <String, _UserLookupCache>{};
  static final Map<String, _StoryListLookupCache> _storyListLookupCache =
      <String, _StoryListLookupCache>{};
  static final Map<String, _StoryDocLookupCache> _storyDocLookupCache =
      <String, _StoryDocLookupCache>{};
  static const Duration _staleRetention = Duration(minutes: 3);
  static const int _maxLookupEntries = 400;
  StreamSubscription<Uri>? _subscription;
  bool _started = false;
  bool _handling = false;
  final RxBool initialLinkResolved = false.obs;

  Future<_PostLookupCache> _getPostLookup(String postId) async {
    _pruneStaleLookups();
    final cached = _postLookupCache[postId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _lookupTtl) {
      return cached;
    }
    final doc =
        (await PostRepository.ensure().fetchPostsByIds([postId]))[postId];
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
    final data = await UserRepository.ensure().getUserRaw(userId);
    final lookup = _UserLookupCache(
      data: data,
      cachedAt: DateTime.now(),
    );
    _userLookupCache[userId] = lookup;
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

    _appLinks
        .getInitialLink()
        .then((initial) async {
          if (initial != null) {
            await _handle(initial);
          }
        })
        .catchError((_) {})
        .whenComplete(() {
          initialLinkResolved.value = true;
        });

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handle(uri)),
      onError: (_) {},
    );
  }

  Future<void> _handle(Uri uri) async {
    if (_handling) return;
    final parsed = _parse(uri);
    if (parsed == null) return;

    _handling = true;
    try {
      if (FirebaseAuth.instance.currentUser == null) {
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
          AppSnackbar('Bilgi', 'Link çözülemedi.');
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
          Get.to(() => SocialProfile(userID: entityId));
          return;
        case 'edu':
          await _openEducationLink(entityId);
          return;
      }
    } catch (_) {
      final handled = await _tryDirectFallback(parsed);
      if (!handled) {
        AppSnackbar('Bilgi', 'Link açılamadı.');
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
          Get.to(() => SocialProfile(userID: rawId));
          return true;
        case 'edu':
          await _openEducationLink(rawId);
          return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  _ParsedDeepLink? _parse(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
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
      final type = _normalizeType(segments[0]);
      if (type == null) return null;
      final id = _normalizeId(segments[1]);
      if (id.isEmpty) return null;
      return _ParsedDeepLink(type: type, id: id);
    }

    if (scheme == 'turqapp') {
      if (host.isNotEmpty) {
        final mappedHostType = _normalizeType(host);
        if (mappedHostType != null && segments.isNotEmpty) {
          final id = _normalizeId(segments.first);
          if (id.isEmpty) return null;
          return _ParsedDeepLink(type: mappedHostType, id: id);
        }
      }
      if (segments.length >= 2) {
        final type = _normalizeType(segments[0]);
        if (type != null) {
          final id = _normalizeId(segments[1]);
          if (id.isEmpty) return null;
          return _ParsedDeepLink(type: type, id: id);
        }
      }
    }

    return null;
  }

  String? _normalizeType(String raw) {
    final value = raw.toLowerCase();
    if (value == 'p' || value == 'post') return 'post';
    if (value == 's' || value == 'story') return 'story';
    if (value == 'u' || value == 'user' || value == 'profile') return 'user';
    if (value == 'i' ||
        value == 'e' ||
        value == 'edu' ||
        value == 'education') {
      return 'edu';
    }
    return null;
  }

  String _normalizeId(String raw) {
    var id = raw.trim();
    // Mesaj içinde yazılırken sona gelen noktalama/boş karakterleri temizle.
    id = id.replaceAll(RegExp(r'^[^A-Za-z0-9_-]+'), '');
    id = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]+$'), '');
    return id;
  }

  Future<void> _openPost(String postId) async {
    final lookup = await _getPostLookup(postId);
    final model = lookup.model;
    if (model == null) {
      AppSnackbar('Bilgi', 'Gönderi bulunamadı.');
      return;
    }
    if (model.deletedPost) {
      AppSnackbar('Bilgi', 'Gönderi kaldırılmış.');
      return;
    }

    if (model.video.trim().isNotEmpty) {
      await Get.to(() => SingleShortView(
            startModel: model,
            startList: [model],
          ));
      return;
    }

    if (model.flood == false && model.floodCount > 1) {
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
      AppSnackbar('Bilgi', 'Hikaye bulunamadı.');
      return;
    }
    if ((storyData['deleted'] ?? false) == true) {
      AppSnackbar('Bilgi', 'Hikaye süresi dolmuş veya silinmiş.');
      return;
    }

    final userId = (storyData['userId'] ?? '').toString().trim();
    if (userId.isEmpty) {
      AppSnackbar('Bilgi', 'Hikaye sahibi bulunamadı.');
      return;
    }

    final userLookup = await _getUserLookup(userId);
    final userData = userLookup.data;
    if (userData == null) {
      AppSnackbar('Bilgi', 'Hikaye sahibi bulunamadı.');
      return;
    }

    final stories = await _fetchStoriesByUserIndexSafe(userId);

    if (stories.isEmpty) {
      AppSnackbar('Bilgi', 'Hikaye bulunamadı.');
      return;
    }

    final index = stories.indexWhere((e) => e.id == storyId);
    if (index > 0) {
      final target = stories.removeAt(index);
      stories.insert(0, target);
    }

    final user = StoryUserModel(
      nickname: (userData['nickname'] ?? '').toString(),
      avatarUrl: (userData['avatarUrl'] ?? '').toString(),
      fullName:
          '${(userData['firstName'] ?? '').toString()} ${(userData['lastName'] ?? '').toString()}'
              .trim(),
      userID: userId,
      stories: stories,
    );

    await Get.to(() => StoryViewer(
          startedUser: user,
          storyOwnerUsers: [user],
        ));
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
    trimMap<_UserLookupCache>(_userLookupCache, (v) => v.cachedAt);
    trimMap<_StoryListLookupCache>(_storyListLookupCache, (v) => v.cachedAt);
    trimMap<_StoryDocLookupCache>(_storyDocLookupCache, (v) => v.cachedAt);
  }

  Future<void> _openEducationLink(String entityId) async {
    final normalized = entityId.trim().toLowerCase();
    if (normalized.startsWith('job:')) {
      await _openJob(entityId.split(':').last.trim());
      return;
    }

    final navController = Get.isRegistered<NavBarController>()
        ? Get.find<NavBarController>()
        : Get.put(NavBarController());
    final educationController = Get.isRegistered<EducationController>()
        ? Get.find<EducationController>()
        : Get.put(EducationController());

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
      AppSnackbar('Bilgi', 'İlan bulunamadı.');
      return;
    }

    final lookup = await _getJobLookup(cleanId);
    final model = lookup.model;
    if (model == null) {
      AppSnackbar('Bilgi', 'İlan bulunamadı.');
      return;
    }
    if (model.ended) {
      AppSnackbar('Bilgi', 'İlan yayından kaldırılmış.');
      return;
    }

    await Get.to(() => JobDetails(model: model));
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _subscription = null;
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

class _UserLookupCache {
  final Map<String, dynamic>? data;
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
