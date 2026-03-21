import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class DenemeSinavlariController extends GetxController {
  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_practice_exam_listing_selection';
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final PracticeExamSnapshotRepository _practiceExamSnapshotRepository =
      PracticeExamSnapshotRepository.ensure();
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  var list = <SinavModel>[].obs;
  var okul = false.obs;
  var showButons = false.obs;
  var ustBar = true.obs;
  var showOkulAlert = false.obs;
  var isLoading = true.obs;
  var isSearchLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  final RxInt listingSelection = 0.obs;
  final RxBool listingSelectionReady = false.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;
  final RxDouble scrollOffset = 0.0.obs;
  final RxString searchQuery = ''.obs;
  final RxList<SinavModel> searchResults = <SinavModel>[].obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 30;
  StreamSubscription<CachedResource<List<SinavModel>>>? _homeSnapshotSub;
  Timer? _searchDebounce;
  int _searchToken = 0;

  bool _sameExamList(List<SinavModel> next) {
    return _sameExamEntries(list, next);
  }

  bool _sameExamEntries(List<SinavModel> current, List<SinavModel> next) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  String _listingSelectionKeyFor(String uid) =>
      '${_listingSelectionPrefKeyPrefix}_$uid';

  Future<void> _restoreListingSelection() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) {
      listingSelection.value = 0;
      listingSelectionReady.value = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      listingSelection.value =
          (prefs.getInt(_listingSelectionKeyFor(uid)) ?? 0) == 1 ? 1 : 0;
    } catch (_) {
      listingSelection.value = 0;
    } finally {
      listingSelectionReady.value = true;
    }
  }

  Future<void> _persistListingSelection() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _listingSelectionKeyFor(uid),
        listingSelection.value == 1 ? 1 : 0,
      );
    } catch (_) {}
  }

  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  @override
  void onInit() {
    super.onInit();
    unawaited(_restoreListingSelection());
    scrolControlcu();
    getOkulBilgisi();
    unawaited(_bootstrapInitialData());
  }

  void toggleListingSelection() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
    unawaited(_persistListingSelection());
  }

  Future<void> _bootstrapInitialData() async {
    final savedController = Get.isRegistered<SavedPracticeExamsController>()
        ? Get.find<SavedPracticeExamsController>()
        : Get.put(SavedPracticeExamsController(), permanent: true);
    await savedController.loadSavedExams(silent: true);
    final userId = CurrentUserService.instance.userId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _practiceExamSnapshotRepository
        .openHome(
          userId: userId,
          limit: _pageSize,
        )
        .listen(_applyHomeSnapshotResource);
  }

  void scrolControlcu() {
    scrollController.addListener(() {
      double currentOffset = scrollController.position.pixels;
      scrollOffset.value = currentOffset;

      if (currentOffset > _previousOffset) {
        if (showButons.value) showButons.value = false;
        if (ustBar.value) ustBar.value = false;
      } else if (currentOffset < _previousOffset) {
        if (showButons.value) showButons.value = false;
        if (!ustBar.value) ustBar.value = true;
      }

      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !hasActiveSearch &&
          !isLoadingMore.value &&
          hasMore.value) {
        loadMore();
      }

      _previousOffset = currentOffset;
    });
  }

  Future<void> getOkulBilgisi() async {
    try {
      final data = await _userSummaryResolver.resolve(
        CurrentUserService.instance.userId,
        preferCache: true,
      );
      final rozet = data?.rozet;
      okul.value =
          hasRozetPermission(currentRozet: rozet, minimumRozet: "Sarı");
    } catch (e) {
      AppSnackbar('common.error'.tr, 'practice.school_info_failed'.tr);
    }
  }

  Future<void> getData() async {
    final hadLocalItems = list.isNotEmpty;
    if (!hadLocalItems) {
      isLoading.value = true;
    }
    hasMore.value = true;
    _lastDocument = null;
    try {
      final resource = await _practiceExamSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.userId,
        limit: _pageSize,
      );
      final items = resource.data ?? const <SinavModel>[];
      if (!_sameExamList(items)) {
        list.assignAll(items);
      }
      hasMore.value = items.length >= _pageSize;
    } catch (e) {
      log("DenemeSinavlariController.getData error: $e");
      AppSnackbar('common.error'.tr, 'practice.load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final page = await _practiceExamRepository.fetchPage(
        startAfter: _lastDocument,
        limit: _pageSize,
      );
      list.addAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
    } catch (e) {
      log("DenemeSinavlariController.loadMore error: $e");
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
      final resource = await _practiceExamSnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.userId,
        limit: 40,
        forceSync: true,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized)
        return;

      final results = resource.data ?? const <SinavModel>[];
      if (token != _searchToken || searchQuery.value.trim() != normalized)
        return;
      if (!_sameExamEntries(searchResults, results)) {
        searchResults.assignAll(results);
      }
    } catch (e) {
      log("Deneme typesense search error: $e");
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }

  void _applyHomeSnapshotResource(CachedResource<List<SinavModel>> resource) {
    final items = resource.data ?? const <SinavModel>[];
    if (items.isNotEmpty) {
      if (!_sameExamList(items)) {
        list.assignAll(items);
      }
      hasMore.value = items.length >= _pageSize;
    }

    if (!resource.isRefreshing || items.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (list.isEmpty) {
      isLoading.value = true;
    }
  }

  @override
  void onClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
