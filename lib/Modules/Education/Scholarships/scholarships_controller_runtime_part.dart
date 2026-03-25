part of 'scholarships_controller.dart';

int get _scholarshipsInitialBatchSize =>
    ReadBudgetRegistry.scholarshipHomeInitialLimit;

const int _scholarshipsBatchSize = 10;

bool _scholarshipsHasActiveSearch(ScholarshipsController controller) {
  return controller.searchQuery.value.length >= controller.minSearchLength;
}

extension ScholarshipsControllerRuntimeX on ScholarshipsController {
  void _handleOnInit() {
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    unawaited(_restoreListingSelection());
    unawaited(_bootstrapScholarships());
  }

  Future<void> _bootstrapScholarships() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _scholarshipSnapshotRepository
        .openHome(
          userId: userId,
          limit: _scholarshipsInitialBatchSize,
        )
        .listen(_applyHomeSnapshotResource);
  }

  void _handleOnClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    scrollController.dispose();
  }

  Future<void> refreshTotalCount() => _refreshTotalCountImpl();

  Future<void> _restoreListingSelection() => _restoreListingSelectionImpl();

  Future<void> _persistListingSelection() => _persistListingSelectionImpl();

  void toggleListingSelection() => _toggleListingSelectionImpl();

  void setSearchQuery(String q) => _setSearchQueryImpl(q);

  void resetSearch() => _resetSearchImpl();

  Future<void> fetchScholarships({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _fetchScholarshipsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> loadMoreScholarships() => _loadMoreScholarshipsImpl();

  Future<void> toggleFollow(String followedId) => _toggleFollowImpl(followedId);

  void updatePageIndex(int scholarshipIndex, int pageIndex) =>
      _updatePageIndexImpl(scholarshipIndex, pageIndex);

  Future<void> toggleLike(String docId, String type) =>
      _toggleLikeImpl(docId, type);

  Future<void> toggleBookmark(String docId, String type) =>
      _toggleBookmarkImpl(docId, type);

  Future<void> shareScholarship(
    Map<String, dynamic> scholarshipData,
    BuildContext context,
  ) =>
      _shareScholarshipImpl(scholarshipData, context);

  Future<void> shareScholarshipExternally(
    Map<String, dynamic> scholarshipData,
  ) =>
      _shareScholarshipExternallyImpl(scholarshipData);

  void toggleExpanded(int index) => _toggleExpandedImpl(index);

  void settings(BuildContext context) => _settingsImpl(context);

  List<InformationModel> get informations => [
        InformationModel(
          title: 'scholarship.info.personal'.tr,
          color: colors[0],
          icon: icons[0],
        ),
        InformationModel(
          title: 'scholarship.info.school'.tr,
          color: colors[1],
          icon: icons[1],
        ),
        InformationModel(
          title: 'scholarship.info.family'.tr,
          color: colors[2],
          icon: icons[2],
        ),
        InformationModel(
          title: 'scholarship.info.dormitory'.tr,
          color: colors[3],
          icon: icons[3],
        ),
      ];
}
