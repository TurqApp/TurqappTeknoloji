import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/recommended_users_repository.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Models/recommended_user_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'recommended_user_list_controller_runtime_part.dart';

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
    _RecommendedUserListControllerRuntimeX(this)._preloadInBackground();
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
  Future<void> getFollowing() =>
      _RecommendedUserListControllerRuntimeX(this).getFollowing();

  /// 2) Önerilecek kullanıcıları çek, takip ettiklerimizi filtrele (cache destekli)
  Future<void> getUsers({int? limit}) =>
      _RecommendedUserListControllerRuntimeX(this).getUsers(limit: limit);

  Future<void> ensureLoaded({int? limit}) =>
      _RecommendedUserListControllerRuntimeX(this).ensureLoaded(limit: limit);
}
