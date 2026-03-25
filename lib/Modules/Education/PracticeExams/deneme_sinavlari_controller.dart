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
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'deneme_sinavlari_controller_data_part.dart';

class DenemeSinavlariController extends GetxController {
  static DenemeSinavlariController ensure({
    bool permanent = false,
  }) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(DenemeSinavlariController(), permanent: permanent);
  }

  static DenemeSinavlariController? maybeFind() {
    final isRegistered = Get.isRegistered<DenemeSinavlariController>();
    if (!isRegistered) return null;
    return Get.find<DenemeSinavlariController>();
  }

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
  final RxInt listingSelection = 1.obs;
  final RxBool listingSelectionReady = false.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;
  final RxDouble scrollOffset = 0.0.obs;
  final RxString searchQuery = ''.obs;
  final RxList<SinavModel> searchResults = <SinavModel>[].obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = ReadBudgetRegistry.practiceExamHomeInitialLimit;
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

  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  @override
  void onInit() {
    super.onInit();
    unawaited(_restoreListingSelectionImpl());
    scrolControlcu();
    getOkulBilgisi();
    unawaited(_bootstrapInitialDataImpl());
  }

  void toggleListingSelection() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
    unawaited(_persistListingSelectionImpl());
  }

  void scrolControlcu() => _setupScrollControllerImpl();

  Future<void> getOkulBilgisi() => _getOkulBilgisiImpl();

  Future<void> getData() async {
    final hadLocalItems = list.isNotEmpty;
    if (!hadLocalItems) {
      isLoading.value = true;
    }
    hasMore.value = true;
    _lastDocument = null;
    try {
      final resource = await _loadHomeSnapshotImpl();
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
      final page = await _fetchNextPageImpl();
      list.addAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
    } catch (e) {
      log("DenemeSinavlariController.loadMore error: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setSearchQuery(String query) => _setSearchQueryImpl(query);

  @override
  void onClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
