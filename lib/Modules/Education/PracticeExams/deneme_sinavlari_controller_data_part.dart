part of 'deneme_sinavlari_controller.dart';

extension DenemeSinavlariControllerDataPart on DenemeSinavlariController {
  String _listingSelectionKeyForImpl(String uid) =>
      '${DenemeSinavlariController._listingSelectionPrefKeyPrefix}_$uid';

  Future<void> _restoreListingSelectionImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      listingSelection.value = 0;
      listingSelectionReady.value = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      listingSelection.value =
          (prefs.getInt(_listingSelectionKeyForImpl(uid)) ?? 0) == 1 ? 1 : 0;
    } catch (_) {
      listingSelection.value = 0;
    } finally {
      listingSelectionReady.value = true;
    }
  }

  Future<void> _persistListingSelectionImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _listingSelectionKeyForImpl(uid),
        listingSelection.value == 1 ? 1 : 0,
      );
    } catch (_) {}
  }

  Future<void> _bootstrapInitialDataImpl() async {
    final savedController = SavedPracticeExamsController.ensure(
      permanent: true,
    );
    await savedController.loadSavedExams(silent: true);
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _practiceExamSnapshotRepository
        .openHome(
          userId: userId,
          limit: DenemeSinavlariController._pageSize,
        )
        .listen(_applyHomeSnapshotResourceImpl);
  }

  Future<void> _getOkulBilgisiImpl() async {
    try {
      final data = await _userSummaryResolver.resolve(
        CurrentUserService.instance.effectiveUserId,
        preferCache: true,
      );
      final rozet = data?.rozet;
      okul.value =
          hasRozetPermission(currentRozet: rozet, minimumRozet: "Sarı");
    } catch (e) {
      AppSnackbar('common.error'.tr, 'practice.school_info_failed'.tr);
    }
  }

  Future<CachedResource<List<SinavModel>>> _loadHomeSnapshotImpl() {
    return _practiceExamSnapshotRepository.loadHome(
      userId: CurrentUserService.instance.effectiveUserId,
      limit: DenemeSinavlariController._pageSize,
    );
  }

  Future<PracticeExamPage> _fetchNextPageImpl() {
    return _practiceExamRepository.fetchPage(
      startAfter: _lastDocument,
      limit: DenemeSinavlariController._pageSize,
    );
  }

  void _applyHomeSnapshotResourceImpl(
      CachedResource<List<SinavModel>> resource) {
    final items = resource.data ?? const <SinavModel>[];
    if (items.isNotEmpty) {
      if (!_sameExamList(items)) {
        list.assignAll(items);
      }
      hasMore.value = items.length >= DenemeSinavlariController._pageSize;
    }

    if (!resource.isRefreshing || items.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (list.isEmpty) {
      isLoading.value = true;
    }
  }
}
