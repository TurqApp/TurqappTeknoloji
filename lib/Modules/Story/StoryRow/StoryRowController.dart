import 'dart:convert';
import 'dart:io';

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../Core/Services/PerformanceService.dart';
import '../../../Core/Services/ContentPolicy/content_policy.dart';
import '../../../Services/FirebaseMyStore.dart';
import '../../../Services/user_analytics_service.dart';
import '../StoryMaker/StoryModel.dart';
import 'StoryUserModel.dart';

class StoryRowController extends GetxController {
  RxList<StoryUserModel> users = <StoryUserModel>[].obs;
  final userStore = Get.find<FirebaseMyStore>();
  StreamSubscription? _followingSub;
  final int initialLimit = 30;
  final int fullLimit = 100;
  bool _backgroundScheduled = false;
  final RxBool isLoading = false.obs;
  static const Duration _miniCacheTtl = Duration(minutes: 45);
  String? _miniCachePath;

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
    unawaited(_initMiniCache());
    unawaited(_loadStoriesFromMiniCache());
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
        DocumentSnapshot<Map<String, dynamic>> userSnap;
        try {
          // Önce cache'ten dene
          userSnap = await FirebaseFirestore.instance
              .collection("users")
              .doc(myUid)
              .get(const GetOptions(source: Source.cache));
        } catch (_) {
          // Cache yoksa ağdan çek
          userSnap = await FirebaseFirestore.instance
              .collection("users")
              .doc(myUid)
              .get();
        }

        if (userSnap.exists) {
          final data = userSnap.data()!;
          final myUser = StoryUserModel(
            nickname: data['nickname'] ?? "",
            pfImage: data['pfImage'] ?? "",
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

  // Cache-first hızlı yükleme: önce cache'ten doldur, sonra ağdan güncel veri çek
  Future<void> _quickLoadFromCacheFirst() async {
    try {
      // Önce cache'ten hızlı yükle (loading state'ini değiştirme)
      await loadStories(
          limit: initialLimit, cacheFirst: true, silentLoad: true);
      // Sonra ağdan güncel veri çek
      Future.delayed(Duration(milliseconds: 100), () {
        loadStories(limit: initialLimit, cacheFirst: false);
      });
    } catch (e) {
      print("📚 QuickLoadFromCache error: $e");
      // Hata durumunda normal yükleme yap
      await loadStories(limit: initialLimit);
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

  @override
  void onClose() {
    _followingSub?.cancel();
    super.onClose();
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
              .collection("Stories")
              .orderBy("createdAt", descending: true)
              .limit(lim)
              .get(const GetOptions(source: Source.cache)),
        );
        cacheHit = snap.docs.isNotEmpty;

        // Cache boşsa ağdan çek
        if (snap.docs.isEmpty) {
          snap = await PerformanceService.traceOperation(
            'story_load_network_fallback',
            () => FirebaseFirestore.instance
                .collection("Stories")
                .orderBy("createdAt", descending: true)
                .limit(lim)
                .get(),
          );
        }
      } else {
        // Normal ağ isteği
        snap = await PerformanceService.traceOperation(
          'story_load_network',
          () => FirebaseFirestore.instance
              .collection("Stories")
              .orderBy("createdAt", descending: true)
              .limit(lim)
              .get(),
        );
      }

      Map<String, List<StoryModel>> userStories = {};
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
        } catch (e) {
          print("📚 Error parsing story ${doc.id}: $e");
          continue;
        }
      }

      List<StoryUserModel> tempList = [];

      // Kullanıcı profil verilerini batched whereIn ile çek
      final userIds = userStories.keys.toList();
      Map<String, Map<String, dynamic>> userDataMap = {};
      const chunkSize = 10; // Firestore whereIn max 10
      for (var i = 0; i < userIds.length; i += chunkSize) {
        final chunk = userIds.sublist(
            i, i + chunkSize > userIds.length ? userIds.length : i + chunkSize);
        final qs = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final d in qs.docs) {
          userDataMap[d.id] = d.data();
        }
      }

      // Takip edilen kullanıcılar (gizli hesap filtresi için)
      final Set<String> followingIDs = {};
      if (myUid != null) {
        final followingSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .collection('TakipEdilenler')
            .get();
        followingIDs.addAll(followingSnap.docs.map((d) => d.id));
      }

      for (var entry in userStories.entries) {
        final userId = entry.key;
        // Newest-to-oldest within a user's stories
        final stories = [...entry.value]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final data = userDataMap[userId];
        if (data == null) continue;

        // Gizlilik filtresi: gizli hesapsa sadece ben veya takip ettiğim kullanıcılar
        final isPrivate = (data['gizliHesap'] ?? false) == true;
        final isMine = myUid != null && userId == myUid;
        final iFollow = followingIDs.contains(userId);
        if (isPrivate && !isMine && !iFollow) {
          continue;
        }

        // Engellediklerimi gösterme
        if (userStore.blockedUsers.contains(userId)) {
          continue;
        }
        final userModel = StoryUserModel(
          nickname: data['nickname'] ?? "",
          pfImage: data['pfImage'] ?? "",
          fullName: "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}",
          userID: userId,
          stories: stories,
        );
        tempList.add(userModel);
      }

      final seenTimes = userStore.readStoriesTimes;

      // Önce kendi kullanıcını oluştur/çek
      StoryUserModel? myStoryUser;

      if (myUid != null) {
        // Story'si varsa model tempList'te olacak
        myStoryUser = tempList.firstWhereOrNull((u) => u.userID == myUid);

        // Eğer kendi kullanıcının hiç story'si yoksa yine de başa ekle!
        if (myStoryUser == null) {
          final userSnap = await FirebaseFirestore.instance
              .collection("users")
              .doc(myUid)
              .get();
          if (userSnap.exists) {
            final data = userSnap.data()!;
            myStoryUser = StoryUserModel(
              nickname: data['nickname'] ?? "",
              pfImage: data['pfImage'] ?? "",
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

        // REACTIVE: userStore.readStories'ı dinle
        if (!userStore.readStories.value.contains(u.userID)) {
          return false; // Hiç okunmamışsa
        }

        // REACTIVE: userStore.readStoriesTimes'ı dinle
        final lastSeen = userStore.readStoriesTimes.value[u.userID];
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
      unawaited(_saveStoriesToMiniCache(users));

      // Kendi süresi dolmuş hikayelerini arşivle ve kaldır
      if (myUid != null) {
        await _archiveAndRemoveExpiredMyStories(myUid);
      }
    } catch (e) {
      print("📚 LoadStories error: $e");
      if (users.isEmpty) {
        await _loadStoriesFromMiniCache(allowExpired: true);
      }
    } finally {
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
      _miniCachePath = '${storyDir.path}/story_row.json';
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
      final payload = {
        'savedAt': now,
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
          .collection('Stories')
          .where('userId', isEqualTo: myUid)
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in expiredSnap.docs) {
        try {
          final model = StoryModel.fromDoc(doc);
          if (model.createdAt.isAfter(expiry)) continue;
          // Archiving/removal yerine sadece deleted:true işaretle
          await FirebaseFirestore.instance
              .collection('Stories')
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
