import 'dart:convert';
import 'dart:io';

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import '../../../Core/Services/performance_service.dart';
import '../../../Core/Services/ContentPolicy/content_policy.dart';
import '../../../Core/Services/user_profile_cache_service.dart';
import '../../../Services/current_user_service.dart';
import '../../../Services/user_analytics_service.dart';
import '../StoryMaker/story_model.dart';
import 'story_user_model.dart';

class StoryRowController extends GetxController {
  RxList<StoryUserModel> users = <StoryUserModel>[].obs;
  final userService = CurrentUserService.instance;
  UserProfileCacheService get _userCache => Get.find<UserProfileCacheService>();
  StreamSubscription? _followingSub;
  final int initialLimit = 30;
  final int fullLimit = 100;
  bool _backgroundScheduled = false;
  final RxBool isLoading = false.obs;
  static const Duration _miniCacheTtl = Duration(minutes: 15);
  static const Duration _followingCacheTtl = Duration(minutes: 2);
  static const Duration _expireCleanupInterval = Duration(minutes: 15);
  String? _miniCachePath;
  Set<String> _followingCache = <String>{};
  DateTime? _followingCacheAt;
  DateTime? _lastExpireCleanupAt;

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

  Map<String, dynamic> _fallbackUserData(String userId) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid != null && myUid == userId) {
      final full = userService.fullName.trim();
      final parts = full.split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
      final first = parts.isNotEmpty ? parts.first : '';
      final last = parts.length > 1 ? parts.skip(1).join(' ') : '';
      return <String, dynamic>{
        'nickname': userService.nickname,
        'firstName': first,
        'lastName': last,
        'avatarUrl': userService.avatarUrl,
        'isPrivate': false,
      };
    }
    return <String, dynamic>{
      'nickname': 'kullanici',
      'firstName': '',
      'lastName': '',
      'avatarUrl': '',
      'isPrivate': false,
    };
  }

  Future<Map<String, Map<String, dynamic>>> _loadMissingProfilesFromUsers(
    List<String> userIds,
  ) async {
    final out = <String, Map<String, dynamic>>{};
    if (userIds.isEmpty) return out;
    try {
      const int chunkSize = 10;
      for (int i = 0; i < userIds.length; i += chunkSize) {
        final end =
            (i + chunkSize > userIds.length) ? userIds.length : i + chunkSize;
        final chunk = userIds.sublist(i, end);
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          out[doc.id] = Map<String, dynamic>.from(doc.data());
        }
      }
    } catch (e) {
      debugPrint('Story fallback users fetch error: $e');
    }
    return out;
  }

  // Auto refresh için static method
  static Future<void> refreshStoriesGlobally() async {
    try {
      final controller = Get.find<StoryRowController>();
      await controller.loadStories();
      print("🔄 Stories refreshed globally");
    } catch (e) {
      print("🔄 Global story refresh error: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    _ensureMyUserPlaceholder();
    unawaited(_initMiniCache());
    unawaited(_loadStoriesFromMiniCache());
    // Ensure profile changes (nickname/avatar) are reflected quickly.
    unawaited(loadStories(silentLoad: true));
    // Main.dart'ta zaten hikayeler yüklendiği için burada sadece listener'ları bağla
    _bindFollowingListener();
    // Arka planda tam listeyi genişlet (düşük öncelik)
    _scheduleBackgroundFullLoad();
  }

  // Kendi kullanıcıyı hemen ekle (boş hikayelerle bile olsa görünür olsun)
  Future<void> addMyUserImmediately() async {
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid != null) {
        final data = await _userCache.getProfile(
          myUid,
          preferCache: false,
          cacheOnly: !ContentPolicy.isConnected,
        );
        if (data != null) {
          final myUser = StoryUserModel(
            nickname: _resolveStoryNickname(data),
            avatarUrl: _resolveAvatar(data),
            fullName: "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}",
            userID: myUid,
            stories: [], // Boş hikayelerle başla
          );
          users.add(myUser);
        }
      }
    } catch (e) {
      print("📚 AddMyUserImmediately error: $e");
    }
  }

  void _bindFollowingListener() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    _followingSub?.cancel();

    // ✅ OPTIMIZED: No real-time listener needed
    // Following list doesn't change frequently
    // Manual refresh on user action (pull-to-refresh) is sufficient
  }

  Future<Set<String>> _getFollowingIds(String myUid) async {
    final now = DateTime.now();
    final last = _followingCacheAt;
    if (last != null && now.difference(last) <= _followingCacheTtl) {
      return _followingCache;
    }
    try {
      final followingSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('followings')
          .get();
      _followingCache = followingSnap.docs.map((d) => d.id).toSet();
      _followingCacheAt = now;
    } catch (e) {
      print('Story following cache load error: $e');
    }
    return _followingCache;
  }

  @override
  void onClose() {
    _followingSub?.cancel();
    super.onClose();
  }

  Future<void> clearSessionCache() async {
    users.clear();
    _followingCache = <String>{};
    _followingCacheAt = null;
    _backgroundScheduled = false;
    try {
      if (_miniCachePath == null) await _initMiniCache();
      final path = _miniCachePath;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Story mini cache clear error: $e');
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

      QuerySnapshot<Map<String, dynamic>> snap;
      if (cacheFirst) {
        // Önce cache'ten dene
        snap = await PerformanceService.traceOperation(
          'story_load_cache_first',
          () => FirebaseFirestore.instance
              .collection("stories")
              .orderBy("createdDate", descending: true)
              .limit(lim)
              .get(const GetOptions(source: Source.cache)),
        );
        cacheHit = snap.docs.isNotEmpty;

        // Cache boşsa ağdan çek
        if (snap.docs.isEmpty) {
          snap = await PerformanceService.traceOperation(
            'story_load_network_fallback',
            () => FirebaseFirestore.instance
                .collection("stories")
                .orderBy("createdDate", descending: true)
                .limit(lim)
                .get(),
          );
        }
      } else {
        // Normal ağ isteği
        snap = await PerformanceService.traceOperation(
          'story_load_network',
          () => FirebaseFirestore.instance
              .collection("stories")
              .orderBy("createdDate", descending: true)
              .limit(lim)
              .get(),
        );
      }

      Map<String, List<StoryModel>> userStories = {};
      final Map<String, Map<String, dynamic>> storyEmbeddedUserMeta = {};
      final myUid = FirebaseAuth.instance.currentUser?.uid;

      final now = DateTime.now();
      final expiry = now.subtract(const Duration(hours: 24));

      for (var doc in snap.docs) {
        try {
          final data = doc.data();
          if ((data['deleted'] ?? false) == true) {
            // Silinmiş hikayeleri listeleme
            continue;
          }
          final story = StoryModel.fromDoc(doc);
          // 24 saatten eski hikayeleri listeye dahil etme
          if (story.createdAt.isBefore(expiry)) {
            // Expire olan karşı taraf hikayelerini göstermiyoruz.
            // Kendi hikayelerimiz için arşivleme/temizlik aşağıda yapılacak.
            continue;
          }
          userStories.putIfAbsent(story.userId, () => []);
          userStories[story.userId]!.add(story);
          final embeddedNickname = (data['nickname'] ?? '').toString().trim();
          final embeddedAvatar = (data['avatarUrl'] ?? '').toString().trim();
          final embeddedUsername = (data['username'] ?? '').toString().trim();
          if (embeddedNickname.isNotEmpty ||
              embeddedAvatar.isNotEmpty ||
              embeddedUsername.isNotEmpty) {
            storyEmbeddedUserMeta[story.userId] = <String, dynamic>{
              'nickname': embeddedNickname,
              'avatarUrl': embeddedAvatar,
              'username': embeddedUsername,
              'firstName': (data['firstName'] ?? '').toString(),
              'lastName': (data['lastName'] ?? '').toString(),
            };
          }
        } catch (e) {
          print("📚 Error parsing story ${doc.id}: $e");
          continue;
        }
      }

      List<StoryUserModel> tempList = [];

      // Kullanıcı profil verilerini batched whereIn ile çek
      final userIds = userStories.keys.toList();
      Map<String, Map<String, dynamic>> userDataMap = {};
      userDataMap = await _userCache.getProfiles(
        userIds,
        preferCache: false,
        cacheOnly: !ContentPolicy.isConnected,
      );
      final missingUserIds =
          userIds.where((id) => userDataMap[id] == null).toList();
      if (missingUserIds.isNotEmpty) {
        final fetchedMissing =
            await _loadMissingProfilesFromUsers(missingUserIds);
        if (fetchedMissing.isNotEmpty) {
          userDataMap.addAll(fetchedMissing);
        }
      }

      // Takip edilen kullanıcılar (gizli hesap filtresi için)
      final Set<String> followingIDs = {};
      if (myUid != null) {
        followingIDs.addAll(await _getFollowingIds(myUid));
      }

      for (var entry in userStories.entries) {
        final userId = entry.key;
        // Kullanıcı içindeki hikayeler yeni->eski sıralansın.
        final stories = [...entry.value]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final rawData = userDataMap[userId] ?? storyEmbeddedUserMeta[userId];
        final data = Map<String, dynamic>.from(
          rawData ?? _fallbackUserData(userId),
        );

        // Gizlilik filtresi: gizli hesapsa sadece ben veya takip ettiğim kullanıcılar
        final isPrivate = (data['isPrivate'] ?? false) == true;
        final isMine = myUid != null && userId == myUid;
        final iFollow = followingIDs.contains(userId);
        if (isPrivate && !isMine && !iFollow) {
          if (isMine) {
            print("📚 My story user unexpectedly filtered as private");
          }
          continue;
        }

        // Engellediklerimi gösterme
        if (userService.isUserBlocked(userId)) {
          if (isMine) {
            print("📚 My story user unexpectedly filtered as blocked");
          }
          continue;
        }
        final resolvedNickname = _resolveStoryNickname(data).trim();
        final userModel = StoryUserModel(
          nickname: resolvedNickname.isNotEmpty
              ? resolvedNickname
              : (data['nickname']?.toString().trim().isNotEmpty == true
                  ? data['nickname'].toString().trim()
                  : (isMine
                      ? (userService.nickname.isNotEmpty
                          ? userService.nickname
                          : 'sen')
                      : 'kullanici')),
          avatarUrl: _resolveAvatar(data),
          fullName: "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}",
          userID: userId,
          stories: stories,
        );
        tempList.add(userModel);
      }

      // Önce kendi kullanıcını oluştur/çek
      StoryUserModel? myStoryUser;

      if (myUid != null) {
        // Story'si varsa model tempList'te olacak
        myStoryUser = tempList.firstWhereOrNull((u) => u.userID == myUid);

        // Eğer kendi kullanıcının hiç story'si yoksa yine de başa ekle!
        if (myStoryUser == null) {
          final data = await _userCache.getProfile(
            myUid,
            preferCache: false,
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
      if (kDebugMode && myUid != null) {
        final me = users.firstWhereOrNull((u) => u.userID == myUid);
        debugPrint(
            "Story row self state: exists=${me != null} stories=${me?.stories.length ?? 0}");
      }
      unawaited(_saveStoriesToMiniCache(users));

      // Kendi süresi dolmuş hikayelerini arşivle ve kaldır
      if (myUid != null) {
        final now = DateTime.now();
        final shouldCleanup = _lastExpireCleanupAt == null ||
            now.difference(_lastExpireCleanupAt!) >= _expireCleanupInterval;
        if (shouldCleanup) {
          _lastExpireCleanupAt = now;
          await _archiveAndRemoveExpiredMyStories(myUid);
        }
      }
    } catch (e) {
      print("📚 LoadStories error: $e");
      if (users.isEmpty) {
        await _loadStoriesFromMiniCache(allowExpired: true);
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

  Future<void> _initMiniCache() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final storyDir = Directory('${dir.path}/story_mini_cache');
      if (!await storyDir.exists()) {
        await storyDir.create(recursive: true);
      }
      _miniCachePath = '${storyDir.path}/story_row_v2.json';
    } catch (e) {
      print('Story mini cache init error: $e');
    }
  }

  Future<void> _saveStoriesToMiniCache(List<StoryUserModel> list) async {
    if (list.isEmpty) return;
    if (_miniCachePath == null) await _initMiniCache();
    final path = _miniCachePath;
    if (path == null) return;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final ownerUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final payload = {
        'savedAt': now,
        'ownerUid': ownerUid,
        'users': list.map((u) => u.toCacheMap()).toList(),
      };
      final file = File(path);
      final tmp = File('$path.tmp');
      await tmp.writeAsString(jsonEncode(payload), flush: true);
      await tmp.rename(file.path);
    } catch (e) {
      print('Story mini cache save error: $e');
    }
  }

  Future<void> _loadStoriesFromMiniCache({bool allowExpired = false}) async {
    if (_miniCachePath == null) await _initMiniCache();
    final path = _miniCachePath;
    if (path == null) return;
    try {
      final file = File(path);
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return;
      final data = jsonDecode(raw);
      if (data is! Map) return;
      final expectedUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final ownerUid = (data['ownerUid'] ?? '').toString();
      if (expectedUid.isNotEmpty &&
          (ownerUid.isEmpty || ownerUid != expectedUid)) {
        // Prevent cross-account story bleed from disk cache.
        try {
          await file.delete();
        } catch (_) {}
        return;
      }
      final savedAt = (data['savedAt'] as num?)?.toInt() ?? 0;
      if (!allowExpired && savedAt > 0) {
        final age = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(savedAt));
        if (age > _miniCacheTtl) return;
      }
      final usersJson =
          (data['users'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final loaded = usersJson
          .map(StoryUserModel.fromCacheMap)
          .where((u) => u.userID.isNotEmpty)
          .toList();
      if (loaded.isNotEmpty) {
        users.assignAll(loaded);
      }
      _ensureMyUserPlaceholder();
    } catch (e) {
      print('Story mini cache load error: $e');
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

  Future<void> _archiveAndRemoveExpiredMyStories(String myUid) async {
    try {
      final now = DateTime.now();
      final expiry = now.subtract(const Duration(hours: 24));

      final expiredSnap = await FirebaseFirestore.instance
          .collection('stories')
          .where('userId', isEqualTo: myUid)
          .get();

      for (final doc in expiredSnap.docs) {
        try {
          final model = StoryModel.fromDoc(doc);
          if (model.createdAt.isAfter(expiry)) continue;
          // Archiving/removal yerine sadece deleted:true işaretle
          await FirebaseFirestore.instance
              .collection('stories')
              .doc(model.id)
              .update({
            'deleted': true,
            'deletedAt': DateTime.now().millisecondsSinceEpoch,
            'deleteReason': 'expired'
          });
        } catch (e) {
          print('Archive expired story error: $e');
        }
      }
    } catch (e) {
      print('archiveAndRemoveExpiredMyStories error: $e');
    }
  }
}
