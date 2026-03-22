import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class TutoringController extends GetxController {
  static TutoringController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TutoringController(), permanent: permanent);
  }

  static TutoringController? maybeFind() {
    final isRegistered = Get.isRegistered<TutoringController>();
    if (!isRegistered) return null;
    return Get.find<TutoringController>();
  }

  final TutoringSnapshotRepository _tutoringSnapshotRepository =
      TutoringSnapshotRepository.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  final FocusNode focusNode = FocusNode();
  final TextEditingController searchPreviewController = TextEditingController();
  var isLoading = true.obs;
  var isSearchLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  var tutoringList = <TutoringModel>[].obs;
  var searchResults = <TutoringModel>[].obs;
  final RxString searchQuery = ''.obs;
  final ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;
  StreamSubscription<CachedResource<List<TutoringModel>>>? _homeSnapshotSub;
  Timer? _searchDebounce;
  int _searchToken = 0;
  int _currentPage = 1;

  String _firstImage(TutoringModel item) {
    final imgs = item.imgs;
    if (imgs == null || imgs.isEmpty) return '';
    return imgs.first;
  }

  bool _sameTutoringEntries(
    List<TutoringModel> current,
    List<TutoringModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.brans,
            item.sehir,
            item.ilce,
            item.fiyat,
            item.timeStamp,
            item.viewCount ?? 0,
            item.applicationCount ?? 0,
            item.dersYeri.join('|'),
            _firstImage(item),
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.brans,
            item.sehir,
            item.ilce,
            item.fiyat,
            item.timeStamp,
            item.viewCount ?? 0,
            item.applicationCount ?? 0,
            item.dersYeri.join('|'),
            _firstImage(item),
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  bool _sameTutoringList(List<TutoringModel> next) =>
      _sameTutoringEntries(tutoringList, next);

  static const int _pageSize = 30;
  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    unawaited(_bootstrapTutoringData());
  }

  Future<void> _bootstrapTutoringData() async {
    final savedController = SavedTutoringsController.ensure(permanent: true);
    await savedController.loadSavedTutorings();
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _tutoringSnapshotRepository
        .openHome(
          userId: userId,
          limit: _pageSize,
        )
        .listen(_applyHomeSnapshotResource);
  }

  @override
  void onClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    focusNode.dispose();
    searchPreviewController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    scrollOffset.value = scrollController.offset;
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !hasActiveSearch &&
        !isLoadingMore.value &&
        hasMore.value) {
      loadMore();
    }
  }

  Future<void> listenToTutoringData({
    bool forceRefresh = false,
  }) async {
    final hadLocalItems = tutoringList.isNotEmpty;
    if (!hadLocalItems) {
      isLoading.value = true;
    }
    hasMore.value = true;
    _currentPage = 1;
    try {
      final result = await _tutoringSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: _pageSize,
        forceSync: forceRefresh,
      );
      final items = result.data ?? const <TutoringModel>[];
      hasMore.value = items.length >= _pageSize;
      final nextList = _applyPersonalization(items);
      if (!_sameTutoringList(nextList)) {
        tutoringList.assignAll(nextList);
      }
      SilentRefreshGate.markRefreshed('tutoring:home');
    } catch (_) {
      if (tutoringList.isNotEmpty) {
        tutoringList.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final nextPage = _currentPage + 1;
      final result = await _tutoringSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: _pageSize,
        page: nextPage,
        forceSync: true,
      );
      final newItems = result.data ?? const <TutoringModel>[];
      hasMore.value = newItems.length >= _pageSize;
      _currentPage = nextPage;

      final existingIds = tutoringList.map((item) => item.docID).toSet();
      final merged =
          newItems.where((item) => !existingIds.contains(item.docID));
      tutoringList.addAll(merged);
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
    _searchDebounce?.cancel();
    if (!hasActiveSearch) {
      isSearchLoading.value = false;
      searchResults.clear();
      _searchToken++;
      return;
    }

    final token = ++_searchToken;
    isSearchLoading.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesense(searchQuery.value, token);
    });
  }

  Future<void> _searchFromTypesense(String query, int token) async {
    final normalized = query.trim();
    try {
      final result = await _tutoringSnapshotRepository.search(
        userId: CurrentUserService.instance.effectiveUserId,
        query: normalized,
        limit: 40,
        forceSync: true,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized)
        return;
      final results = result.data ?? const <TutoringModel>[];
      if (token != _searchToken || searchQuery.value.trim() != normalized)
        return;
      final nextResults = _applyPersonalization(results);
      if (!_sameTutoringEntries(searchResults, nextResults)) {
        searchResults.assignAll(nextResults);
      }
    } catch (_) {
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }

  /// Kişiselleştirilmiş sıralama puanı.
  /// Doğrulanmış (+3), kullanıcı şehrinde (+2), yüksek puan (+0-2).
  double _personalizedScore(TutoringModel t) {
    double score = 0;
    if (t.verified == true) score += 3;
    if (t.averageRating != null) {
      score += (t.averageRating!.toDouble() / 5.0) * 2.0;
    }
    // Kullanıcı şehri ile eşleşme
    try {
      final userCity = CurrentUserService.instance.currentUser?.city;
      if (userCity != null && userCity.isNotEmpty && t.sehir == userCity) {
        score += 2;
      }
    } catch (_) {}
    return score;
  }

  /// Listeyi kişiselleştir (doğrulanmış + aynı şehir + yüksek puan öne çık).
  List<TutoringModel> _applyPersonalization(List<TutoringModel> list) {
    final sorted = List<TutoringModel>.from(list);
    sorted.sort((a, b) {
      final scoreA = _personalizedScore(a);
      final scoreB = _personalizedScore(b);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      return 0; // Eşit puanda orijinal sırayı koru
    });
    return sorted;
  }

  Future<bool> toggleFavorite(
    String docId,
    String userId,
    bool isFavorite,
  ) async {
    final tutoringIndex = tutoringList.indexWhere((t) => t.docID == docId);
    final currentTutoring =
        tutoringIndex == -1 ? null : tutoringList[tutoringIndex];
    final oldFavorites = currentTutoring == null
        ? <String>[]
        : List<String>.from(currentTutoring.favorites);
    final nextFavorites = List<String>.from(oldFavorites);
    if (isFavorite) {
      nextFavorites.remove(userId);
    } else if (!nextFavorites.contains(userId)) {
      nextFavorites.add(userId);
    }

    if (currentTutoring != null) {
      tutoringList[tutoringIndex] = currentTutoring.copyWith(
        favorites: nextFavorites,
      );
      tutoringList.refresh();
    }

    try {
      await _tutoringRepository.toggleFavorite(
        docId: docId,
        userId: userId,
        isFavorite: isFavorite,
      );
      return true;
    } catch (_) {
      // Rollback on error
      if (currentTutoring != null) {
        tutoringList[tutoringIndex] = currentTutoring.copyWith(
          favorites: oldFavorites,
        );
        tutoringList.refresh();
      }
      return false;
    }
  }

  void _applyHomeSnapshotResource(
    CachedResource<List<TutoringModel>> resource,
  ) async {
    final items = resource.data ?? const <TutoringModel>[];
    if (items.isNotEmpty) {
      hasMore.value = items.length >= _pageSize;
      final nextList = _applyPersonalization(items);
      if (!_sameTutoringList(nextList)) {
        tutoringList.assignAll(nextList);
      }
    }

    if (!resource.isRefreshing || items.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (tutoringList.isEmpty) {
      isLoading.value = true;
    }
  }
}

extension TutoringModelExtension on TutoringModel {
  TutoringModel copyWith({
    String? docID,
    String? aciklama,
    String? baslik,
    String? brans,
    String? cinsiyet,
    List<String>? dersYeri,
    num? end,
    List<String>? favorites,
    num? fiyat,
    List<String>? imgs,
    String? ilce,
    bool? onayVerildi,
    String? sehir,
    bool? telefon,
    num? timeStamp,
    String? userID,
    bool? whatsapp,
    bool? ended,
    num? endedAt,
    num? viewCount,
    num? applicationCount,
    num? averageRating,
    num? reviewCount,
    Map<String, List<String>>? availability,
    double? lat,
    double? long,
    bool? verified,
    List<String>? verificationDocs,
    String? avatarUrl,
    String? displayName,
    String? nickname,
    String? rozet,
  }) {
    return TutoringModel(
      docID: docID ?? this.docID,
      aciklama: aciklama ?? this.aciklama,
      baslik: baslik ?? this.baslik,
      brans: brans ?? this.brans,
      cinsiyet: cinsiyet ?? this.cinsiyet,
      dersYeri: dersYeri ?? this.dersYeri,
      end: end ?? this.end,
      favorites: favorites ?? this.favorites,
      fiyat: fiyat ?? this.fiyat,
      imgs: imgs ?? this.imgs,
      ilce: ilce ?? this.ilce,
      onayVerildi: onayVerildi ?? this.onayVerildi,
      sehir: sehir ?? this.sehir,
      telefon: telefon ?? this.telefon,
      timeStamp: timeStamp ?? this.timeStamp,
      userID: userID ?? this.userID,
      whatsapp: whatsapp ?? this.whatsapp,
      ended: ended ?? this.ended,
      endedAt: endedAt ?? this.endedAt,
      viewCount: viewCount ?? this.viewCount,
      applicationCount: applicationCount ?? this.applicationCount,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      availability: availability ?? this.availability,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      verified: verified ?? this.verified,
      verificationDocs: verificationDocs ?? this.verificationDocs,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      rozet: rozet ?? this.rozet,
    );
  }
}
