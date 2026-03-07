import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class StoryInteractionOptimizer extends GetxService {
  static StoryInteractionOptimizer get to => Get.find();
  final CurrentUserService _userService = CurrentUserService.instance;

  // Debouncing ve batching için
  Timer? _writeTimer;
  final Map<String, int> _pendingWrites = {};
  final Set<String> _pendingUsers = {};

  // Concurrency kontrolü
  bool _isWriting = false;
  final List<Future<void>> _pendingOperations = [];

  // Local cache için (public reactive access)
  final RxMap<String, bool> localStoryCache = <String, bool>{}.obs;
  final RxMap<String, int> localTimeCache = <String, int>{}.obs;

  // Stream subscriptions for cleanup
  StreamSubscription? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeLocalCache();
  }

  /// Local cache'i Firestore data ile sync et
  void _initializeLocalCache() {
    _userSubscription = _userService.userStream.listen((user) {
      localStoryCache.clear();
      localTimeCache.clear();
      if (user == null) return;

      for (final userId in user.readStories) {
        localStoryCache[userId] = true;
      }
      localTimeCache.assignAll(user.readStoriesTimes);
    });
  }

  /// Optimize edilmiş story view marking (debounced + batched)
  Future<void> markStoryViewed(
      String storyOwnerId, String storyId, int storyTime) async {
    try {
      // Local cache'i hemen güncelle (UI responsiveness için)
      localStoryCache[storyOwnerId] = true;
      localTimeCache[storyOwnerId] = storyTime;

      // Pending writes'a ekle
      _pendingWrites[storyOwnerId] = storyTime;
      _pendingUsers.add(storyOwnerId);

      // Debounce timer'ı reset et
      _writeTimer?.cancel();
      _writeTimer =
          Timer(const Duration(milliseconds: 500), _flushPendingWrites);

      print(
          "📝 Queued story view - Owner: $storyOwnerId, Story: $storyId, Time: $storyTime");
    } catch (e) {
      print("🚨 markStoryViewed error: $e");
      // Error durumunda bile UI responsiveness için local cache güncelle
      localStoryCache[storyOwnerId] = true;
      localTimeCache[storyOwnerId] = storyTime;
    }
  }

  /// Pending writes'ları batch olarak Firestore'a yaz
  Future<void> _flushPendingWrites() async {
    if (_pendingWrites.isEmpty || _isWriting) return;

    // Concurrency kontrolü
    _isWriting = true;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _isWriting = false;
        return;
      }

      // Current pending data'yı lokal değişkenlere kopyala (race condition önlemek için)
      final currentWrites = Map<String, int>.from(_pendingWrites);
      final currentUsers = Set<String>.from(_pendingUsers);

      // Clear pending immediately (yeni isteklerin birikebilmesi için)
      _pendingWrites.clear();
      _pendingUsers.clear();

      // Batch write için hazırla
      final batch = FirebaseFirestore.instance.batch();
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(uid);

      // readStories subcollection updates
      for (var entry in currentWrites.entries) {
        batch.set(
          userDocRef.collection('readStories').doc(entry.key),
          {
            'storyId': entry.key,
            'readDate': entry.value,
            'updatedDate': DateTime.now().millisecondsSinceEpoch,
          },
          SetOptions(merge: true),
        );
      }
      if (currentUsers.isNotEmpty || currentWrites.isNotEmpty) {
        await batch.commit();

        print(
            "✅ Batch write completed - ${currentWrites.length} story updates");
      }
    } catch (e) {
      print("🚨 Batch write error: $e");

      // Retry logic - pending writes'a geri ekle (data loss önlemek için)
      try {
        final retryWrites = Map<String, int>.from(_pendingWrites);
        final retryUsers = Set<String>.from(_pendingUsers);

        for (var entry in retryWrites.entries) {
          _pendingWrites[entry.key] = entry.value;
        }
        _pendingUsers.addAll(retryUsers);

        // 2 saniye sonra tekrar dene
        Timer(const Duration(seconds: 2), _flushPendingWrites);
      } catch (retryError) {
        print("🚨 Retry preparation error: $retryError");
      }
    } finally {
      _isWriting = false;
    }
  }

  /// Local cache'den hızlı story status check
  bool areAllStoriesSeenCached(String storyOwnerId, List<dynamic> stories) {
    if (stories.isEmpty) return true;

    // Local cache'de var mı?
    final isInReadList = localStoryCache[storyOwnerId] ?? false;
    if (!isInReadList) return false;

    final lastSeenTime = localTimeCache[storyOwnerId];
    if (lastSeenTime == null) return false;

    // Tüm hikayelerin zamanını kontrol et
    for (var story in stories) {
      final storyTime = story.createdAt?.millisecondsSinceEpoch ?? 0;
      if (storyTime > lastSeenTime) {
        return false; // Daha yeni hikaye var
      }
    }

    return true; // Tüm hikayeler izlenmiş
  }

  /// Manual flush (acil durumlar için)
  Future<void> forceFlush() async {
    _writeTimer?.cancel();

    // Concurrent işlemlerin bitmesini bekle
    if (_pendingOperations.isNotEmpty) {
      await Future.wait(_pendingOperations);
      _pendingOperations.clear();
    }

    await _flushPendingWrites();
  }

  /// App kapatılırken çağrılacak
  Future<void> cleanup() async {
    print("🧹 StoryInteractionOptimizer cleanup starting...");

    _writeTimer?.cancel();

    // Stream subscriptions'ları temizle
    await _userSubscription?.cancel();

    // Pending operations'ları bekle ve temizle
    if (_pendingOperations.isNotEmpty) {
      try {
        await Future.wait(_pendingOperations, eagerError: false);
      } catch (e) {
        print("🚨 Error waiting for pending operations: $e");
      }
      _pendingOperations.clear();
    }

    // Final flush
    await _flushPendingWrites();

    // Local cache'leri temizle
    localStoryCache.clear();
    localTimeCache.clear();

    print("✅ StoryInteractionOptimizer cleanup completed");
  }

  @override
  void onClose() {
    _writeTimer?.cancel();

    // Stream subscriptions'ları temizle
    _userSubscription?.cancel();

    // Pending operations'ları temizle
    _pendingOperations.clear();

    // Local cache'leri temizle
    localStoryCache.clear();
    localTimeCache.clear();

    super.onClose();
  }
}
