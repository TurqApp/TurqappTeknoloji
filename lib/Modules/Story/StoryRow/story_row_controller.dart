import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import '../../../Core/Services/turq_image_cache_manager.dart';
import '../../../Core/Services/ContentPolicy/content_policy.dart';
import '../../../Core/Services/user_profile_cache_service.dart';
import '../../../Core/Utils/avatar_url.dart';
import '../../../Services/current_user_service.dart';
import '../../../Services/user_analytics_service.dart';
import '../StoryMaker/story_model.dart';
import 'story_user_model.dart';

class StoryRowController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  RxList<StoryUserModel> users = <StoryUserModel>[].obs;
  final userService = CurrentUserService.instance;
  UserProfileCacheService get _userCache {
    if (Get.isRegistered<UserProfileCacheService>()) {
      return Get.find<UserProfileCacheService>();
    }
    return Get.put(UserProfileCacheService(), permanent: true);
  }

  final int initialLimit = 30;
  final int fullLimit = 100;
  bool _backgroundScheduled = false;
  final RxBool isLoading = false.obs;
  static const Duration _expireCleanupInterval = Duration(minutes: 15);
  DateTime? _lastExpireCleanupAt;
  final StoryRepository _storyRepository = StoryRepository.ensure();

  void _ensureMyUserPlaceholder() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || myUid.isEmpty) return;
    if (users.any((u) => u.userID == myUid)) return;

    final nickname = userService.nickname.trim();
    final fullName = userService.fullName.trim();

    users.insert(
      0,
      StoryUserModel(
        nickname: nickname.isNotEmpty ? nickname : '@kullanici',
        avatarUrl: userService.avatarUrl,
        fullName: fullName,
        userID: myUid,
        stories: const [],
      ),
    );
  }

  String _resolveStoryNickname(Map<String, dynamic> data) {
    final nickname = (data['nickname'] ?? '').toString().trim();
    final username = (data['username'] ?? '').toString().trim();
    final usernameLower = (data['usernameLower'] ?? '').toString().trim();
    final hasSpace = nickname.contains(RegExp(r'\s'));
    if (nickname.isNotEmpty && !hasSpace) return nickname;
    if (username.isNotEmpty) return username;
    if (usernameLower.isNotEmpty) return usernameLower;
    return '';
  }

  String _resolveAvatar(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    return resolveAvatarUrl(data, profile: profile);
  }

  // Auto refresh için static method
  static Future<void> refreshStoriesGlobally() async {
    try {
      final controller = Get.find<StoryRowController>();
      await controller.loadStories();
    } catch (e) {
      debugPrint("Story refresh error: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    _ensureMyUserPlaceholder();
    unawaited(_bootstrapStoryRow());
    // Main.dart'ta zaten hikayeler yüklendiği için burada sadece listener'ları bağla
    // Arka planda tam listeyi genişlet (düşük öncelik)
    _scheduleBackgroundFullLoad();
  }

  Future<void> _bootstrapStoryRow() async {
    await _loadStoriesFromMiniCache();
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (users.isEmpty ||
        SilentRefreshGate.shouldRefresh(
          'story:row:$myUid',
          minInterval: _silentRefreshInterval,
        )) {
      unawaited(loadStories(silentLoad: true, cacheFirst: true));
    }
  }

  // Kendi kullanıcıyı hemen ekle (boş hikayelerle bile olsa görünür olsun)
  Future<void> addMyUserImmediately() async {
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid != null) {
        final data = await _userCache.getProfile(
          myUid,
          preferCache: true,
          cacheOnly: !ContentPolicy.isConnected,
        );
        if (data != null) {
          final existingIndex =
              users.indexWhere((item) => item.userID == myUid);
          final List<StoryModel> existingStories = existingIndex == -1
              ? const <StoryModel>[]
              : users[existingIndex].stories;
          final myUser = StoryUserModel(
            nickname: _resolveStoryNickname(data),
            avatarUrl: _resolveAvatar(data),
            fullName: "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}",
            userID: myUid,
            stories: existingStories,
          );
          if (existingIndex == -1) {
            users.insert(0, myUser);
          } else {
            users[existingIndex] = myUser;
            if (existingIndex != 0) {
              users.removeAt(existingIndex);
              users.insert(0, myUser);
            }
          }
          unawaited(_warmVisibleAvatarFiles(users, take: 6));
        }
      }
    } catch (e) {
      debugPrint("AddMyUserImmediately error: $e");
    }
  }

  Future<void> _warmVisibleAvatarFiles(
    Iterable<StoryUserModel> source, {
    int take = 12,
  }) async {
    final urls = source
        .map((e) => e.avatarUrl.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .take(take)
        .toList();
    if (urls.isEmpty) return;

    for (final url in urls) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(url);
      } catch (_) {}
    }
  }

  Future<void> clearSessionCache() async {
    final ownerUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    users.clear();
    _backgroundScheduled = false;
    if (ownerUid.isEmpty) return;
    try {
      await _storyRepository.invalidateStoryCachesForUser(
        ownerUid,
        clearDeletedStories: false,
      );
    } catch (e) {
      debugPrint('Story mini cache clear error: $e');
    }
  }

  Future<void> loadStories(
      {int? limit, bool cacheFirst = false, bool silentLoad = false}) async {
    final loadWatch = Stopwatch()..start();
    var cacheHit = false;
    try {
      if (!silentLoad) {
        isLoading.value = true;
      }
      if (!ContentPolicy.isConnected) {
        await _loadStoriesFromMiniCache(allowExpired: true);
        return;
      }
      final lim = limit ?? initialLimit;
      final myUid = FirebaseAuth.instance.currentUser?.uid;

      if (myUid != null) {
        final now = DateTime.now();
        final shouldCleanup = _lastExpireCleanupAt == null ||
            now.difference(_lastExpireCleanupAt!) >= _expireCleanupInterval;
        if (shouldCleanup) {
          _lastExpireCleanupAt = now;
          await _storyRepository.markExpiredStoriesDeleted(myUid);
        }
      }

      final result = await _storyRepository.fetchStoryUsers(
        limit: lim,
        cacheFirst: cacheFirst,
        currentUid: myUid ?? '',
        blockedUserIds:
            userService.currentUserRx.value?.blockedUsers ?? const <String>[],
      );
      cacheHit = result.cacheHit;
      final tempList = [...result.users];

      // Önce kendi kullanıcını oluştur/çek
      StoryUserModel? myStoryUser;

      if (myUid != null) {
        // Story'si varsa model tempList'te olacak
        myStoryUser = tempList.firstWhereOrNull((u) => u.userID == myUid);

        // Eğer kendi kullanıcının hiç story'si yoksa yine de başa ekle!
        if (myStoryUser == null) {
          final data = await _userCache.getProfile(
            myUid,
            preferCache: true,
            cacheOnly: !ContentPolicy.isConnected,
          );
          if (data != null) {
            myStoryUser = StoryUserModel(
              nickname: _resolveStoryNickname(data),
              avatarUrl: _resolveAvatar(data),
              fullName: "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}",
              userID: myUid,
              stories: [], // Burada boş!
            );
          }
        }

        // Story'si varsa tempList'ten çıkar, tekrar ekleme olmasın
        tempList.removeWhere((u) => u.userID == myUid);
      }

      // Diğer kullanıcılar: TÜM HİKAYELERE DAYALI SıRALAMA (REACTIVE)
      bool allSeen(StoryUserModel u) {
        if (u.stories.isEmpty) return true; // boşsa seen kabul

        if (!userService.hasReadStory(u.userID)) {
          return false; // Hiç okunmamışsa
        }

        final lastSeen = userService.getStoryReadTime(u.userID);
        if (lastSeen == null) return false;

        // Tüm hikayelerin zamanını kontrol et
        for (final story in u.stories) {
          if (story.createdAt.millisecondsSinceEpoch > lastSeen) {
            return false; // Daha yeni hikaye var
          }
        }

        return true; // Tüm hikayeler izlenmiş
      }

      // Sort users by their latest story time (now at index 0)
      final unseen = tempList.where((u) => !allSeen(u)).toList()
        ..sort((a, b) =>
            b.stories.first.createdAt.compareTo(a.stories.first.createdAt));
      final seen = tempList.where((u) => allSeen(u)).toList()
        ..sort((a, b) =>
            b.stories.first.createdAt.compareTo(a.stories.first.createdAt));

      // Kendi kullanıcı her zaman başta!
      users.value = [
        if (myStoryUser != null) myStoryUser,
        ...unseen,
        ...seen,
      ];
      unawaited(_warmVisibleAvatarFiles(users));
      if (kDebugMode && myUid != null) {
        final me = users.firstWhereOrNull((u) => u.userID == myUid);
        debugPrint(
            "Story row self state: exists=${me != null} stories=${me?.stories.length ?? 0}");
      }
      if (myUid != null && myUid.isNotEmpty) {
        unawaited(
          _storyRepository.saveStoryRowCache(users, ownerUid: myUid),
        );
        SilentRefreshGate.markRefreshed('story:row:$myUid');
      }
    } catch (e) {
      debugPrint("LoadStories error: $e");
      if (users.isEmpty) {
        await _loadStoriesFromMiniCache();
      }
    } finally {
      _ensureMyUserPlaceholder();
      loadWatch.stop();
      if (cacheFirst) {
        unawaited(UserAnalyticsService.instance.trackCachePerformance(
          cacheHit: cacheHit,
          loadTimeMs: loadWatch.elapsedMilliseconds,
        ));
      }
      if (!silentLoad) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _loadStoriesFromMiniCache({bool allowExpired = false}) async {
    try {
      final expectedUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final loaded = await _storyRepository.restoreStoryRowCache(
        ownerUid: expectedUid,
        allowExpired: allowExpired,
      );
      if (loaded.isNotEmpty) {
        users.assignAll(loaded);
        unawaited(_warmVisibleAvatarFiles(loaded));
      }
      _ensureMyUserPlaceholder();
    } catch (e) {
      debugPrint('Story mini cache load error: $e');
    }
  }

  void _scheduleBackgroundFullLoad() {
    if (_backgroundScheduled) return;
    if (!ContentPolicy.allowBackgroundRefresh(ContentScreenKind.story)) return;
    _backgroundScheduled = true;
    Future.delayed(const Duration(seconds: 12), () async {
      try {
        if (!ContentPolicy.allowBackgroundRefresh(ContentScreenKind.story)) {
          return;
        }
        await loadStories(limit: fullLimit, silentLoad: true);
      } catch (_) {}
      _backgroundScheduled = false;
    });
  }
}
