import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/recommended_users_repository.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Models/recommended_user_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class RecommendedUserListController extends GetxController {
  static RecommendedUserListController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(RecommendedUserListController());
  }

  static RecommendedUserListController? maybeFind() {
    final isRegistered = Get.isRegistered<RecommendedUserListController>();
    if (!isRegistered) return null;
    return Get.find<RecommendedUserListController>();
  }

  RxList<RecommendedUserModel> list = <RecommendedUserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  final RxList<String> takipEdilenler = <String>[].obs;
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();

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
    // İlk feed turunda slotun en sona düşmüş gibi görünmemesi için
    // ön yüklemeyi geciktirmeden başlat.
    _preloadInBackground();
  }

  /// Arka planda sessizce cache'e al
  void _preloadInBackground() {
    Future.microtask(() async {
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

    if (isLoadingFollowing) return;
    isLoadingFollowing = true;

    try {
      final currentUserId = CurrentUserService.instance.effectiveUserId;
      final ids = await _visibilityPolicy.loadViewerFollowingIds(
        viewerUserId: currentUserId,
        preferCache: true,
      );
      takipEdilenler.assignAll(ids.toList());
      hasMoreFollowing = false;
      _lastFollowingLoadTime = DateTime.now();
    } catch (e) {
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
      final currentUserId = CurrentUserService.instance.effectiveUserId;

      // Takip ettiklerimizi yükleyelim (cache'ten gelirse hızlı)
      await getFollowing();

      // İndeks ihtiyacını azaltmak için whereNotIn yerine client-side filtreleme
      final lim = limit ?? usersLimitFull;

      // Timeout ekle - 10 saniye içinde cevap gelmezse iptal et
      final candidates = await RecommendedUsersRepository.ensure()
          .fetchCandidates(limit: lim, preferCache: true)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Kullanıcılar yüklenemedi');
        },
      );

      // Filtre: ne kendimiz ne de takip ettiklerimiz; rozetler client-side elenir
      final filtered = candidates.where((user) {
        if (user.userID == currentUserId) return false;
        if (takipEdilenler.contains(user.userID)) return false;
        final normalizedRozet = normalizeRozetValue(user.rozet);
        return normalizedRozet.isNotEmpty &&
            normalizedRozet != 'kirmizi' &&
            normalizedRozet != 'gri';
      }).toList()
        ..shuffle();

      // Listeye ata
      list.assignAll(filtered);
      _lastLoadTime = DateTime.now();
    } catch (_) {
      hasError.value = true;
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
