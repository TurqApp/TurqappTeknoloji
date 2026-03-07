import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/recommended_user_model.dart';

class RecommendedUserListController extends GetxController {
  RxList<RecommendedUserModel> list = <RecommendedUserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  final RxList<String> takipEdilenler = <String>[].obs;

  DocumentSnapshot? lastFollowingDoc;
  bool hasMoreFollowing = true;
  bool isLoadingFollowing = false;
  final int followingLimit = 100;
  final int usersLimitInitial = 200;
  final int usersLimitFull = 500; // 1000'den 500'e düşürdük
  bool _bgScheduled = false;
  bool loadedOnce = false;

  // Cache mekanizması
  DateTime? _lastLoadTime;
  DateTime? _lastFollowingLoadTime;
  final Duration _cacheValidDuration = const Duration(minutes: 10);
  final Duration _followingCacheValidDuration = const Duration(minutes: 30);

  @override
  void onInit() {
    super.onInit();
    // Lazy-load: RecommendedUserList görünürlüğe yaklaştığında tetiklenecek
    // İlk yükleme için arka planda cache'e al
    _preloadInBackground();
  }

  /// Arka planda sessizce cache'e al
  void _preloadInBackground() {
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        await ensureLoaded(limit: usersLimitInitial);
      } catch (_) {
        // Sessizce başarısız ol
      }
    });
  }

  /// Cache geçerliliğini kontrol et
  bool _isCacheValid() {
    if (_lastLoadTime == null) return false;
    return DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration;
  }

  /// Takip listesi cache'i geçerli mi?
  bool _isFollowingCacheValid() {
    if (_lastFollowingLoadTime == null) return false;
    return DateTime.now().difference(_lastFollowingLoadTime!) <
        _followingCacheValidDuration;
  }

  /// Zorunlu olmayan: mevcut listeyi yeniden karıştır (ağ isteği olmadan)
  void reshuffleLocal() {
    final copy = List<RecommendedUserModel>.from(list);
    copy.shuffle();
    list.assignAll(copy);
  }

  /// Tam yenileme: takip listesini sıfırla ve yeniden getir
  Future<void> refreshUsers() async {
    lastFollowingDoc = null;
    hasMoreFollowing = true;
    isLoadingFollowing = false;
    takipEdilenler.clear();
    _lastLoadTime = null;
    _lastFollowingLoadTime = null;
    hasError.value = false;
    await getUsers();
  }

  /// 1) Önce takip edilenleri getir (cache destekli)
  Future<void> getFollowing() async {
    // Cache geçerliyse ve liste doluysa atla
    if (_isFollowingCacheValid() && takipEdilenler.isNotEmpty) {
      return;
    }

    if (isLoadingFollowing || !hasMoreFollowing) return;
    isLoadingFollowing = true;

    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      Query query = FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .collection("followings")
          .orderBy("timeStamp", descending: true)
          .limit(followingLimit);

      if (lastFollowingDoc != null) {
        query = query.startAfterDocument(lastFollowingDoc!);
      }

      final snap = await query.get(const GetOptions(
        source: Source.serverAndCache, // Cache öncelikli
      ));

      if (snap.docs.isNotEmpty) {
        lastFollowingDoc = snap.docs.last;
        for (var doc in snap.docs) {
          final id = doc.id;
          if (!takipEdilenler.contains(id)) {
            takipEdilenler.add(id);
          }
        }
        if (snap.docs.length < followingLimit) {
          hasMoreFollowing = false;
        }
        _lastFollowingLoadTime = DateTime.now();
      } else {
        hasMoreFollowing = false;
      }
    } catch (e) {
      print('Error loading following list: $e');
      // Takip listesi yüklenemezse boş devam et
      hasError.value = true;
    } finally {
      isLoadingFollowing = false;
    }
  }

  /// 2) Önerilecek kullanıcıları çek, takip ettiklerimizi filtrele (cache destekli)
  Future<void> getUsers({int? limit}) async {
    // Cache geçerliyse ve liste doluysa atla
    if (_isCacheValid() && list.isNotEmpty) {
      return;
    }

    // Zaten yükleniyor mu?
    if (isLoading.value) return;

    isLoading.value = true;
    hasError.value = false;

    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Takip ettiklerimizi yükleyelim (cache'ten gelirse hızlı)
      await getFollowing();

      // İndeks ihtiyacını azaltmak için whereNotIn yerine client-side filtreleme
      final lim = limit ?? usersLimitFull;

      // Timeout ekle - 10 saniye içinde cevap gelmezse iptal et
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('isPrivate', isEqualTo: false)
          .limit(lim)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Kullanıcılar yüklenemedi');
        },
      );

      // Filtre: ne kendimiz ne de takip ettiklerimiz; rozetler client-side elenir
      final filtered = snap.docs
          .where((doc) {
            if (doc.id == currentUserId) return false;
            if (takipEdilenler.contains(doc.id)) return false;
            final r = (doc.data())['rozet'] as String? ?? '';
            return r.isNotEmpty && r != 'Kirmizi' && r != 'Gri';
          })
          .map((doc) => RecommendedUserModel.fromDocument(doc))
          .toList()
        ..shuffle();

      // Listeye ata
      list.assignAll(filtered);
      _lastLoadTime = DateTime.now();
    } catch (e) {
      hasError.value = true;
      // Hata olsa bile cache'te varsa göster
      if (list.isEmpty) {
        print('Error loading recommended users: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> ensureLoaded({int? limit}) async {
    // Cache geçerliyse ve liste varsa atla
    if (_isCacheValid() && list.isNotEmpty) {
      return;
    }

    if (loadedOnce && list.isNotEmpty) {
      // Liste var ama cache süresi dolmuş, background'da yenile
      _scheduleBackgroundUsersLoad();
      return;
    }

    await getUsers(limit: limit ?? usersLimitInitial);
    loadedOnce = true;
    _scheduleBackgroundUsersLoad();
  }

  void _scheduleBackgroundUsersLoad() {
    if (_bgScheduled) return;
    _bgScheduled = true;
    // Daha uzun süre bekle, çok sık background load yapma
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        // Cache geçersizse yenile
        if (!_isCacheValid()) {
          await getUsers(limit: usersLimitFull);
        }
      } catch (_) {
        // Sessizce başarısız ol
      } finally {
        _bgScheduled = false;
      }
    });
  }
}
