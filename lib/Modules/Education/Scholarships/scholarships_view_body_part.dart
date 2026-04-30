part of 'scholarships_view.dart';

extension ScholarshipsViewBodyPart on _ScholarshipsViewState {
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(AppIcons.arrowLeft, color: Colors.black, size: 25),
              ),
              Obx(() {
                final isSearching = controller.hasActiveSearch;
                final count = isSearching
                    ? controller.visibleScholarships.length
                    : controller.totalCount.value;
                final text = isSearching
                    ? 'scholarship.search_results_title'
                        .trParams({'count': '$count'})
                    : 'scholarship.list_title'.trParams({'count': '$count'});
                return TypewriterText(text: text);
              }),
            ],
          ),
        ),
        IconButton(
          icon: Icon(AppIcons.settings, color: Colors.black, size: 24),
          onPressed: () => controller.settings(Get.context!),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: controller.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'common.search'.tr,
                hintStyle: TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
                prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                suffixIcon: Obx(() {
                  final hasQuery = controller.searchQuery.value.isNotEmpty;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: hasQuery
                        ? GestureDetector(
                            key: const ValueKey('clear'),
                            onTap: () {
                              _searchController.clear();
                              controller.resetSearch();
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 6.0),
                              child: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  );
                }),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.03),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(
            () => AppHeaderActionButton(
              onTap: controller.toggleListingSelection,
              child: Icon(
                controller.listingSelection.value == 1
                    ? AppIcons.squareGrid2
                    : AppIcons.list,
                color: Colors.black,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Expanded(
      child: Obx(
        () => RefreshIndicator(
          backgroundColor: Colors.black,
          color: Colors.white,
          onRefresh: () async {
            await controller.fetchScholarships();
            await controller.refreshTotalCount();
          },
          child: Stack(
            children: [
              if (!controller.listingSelectionReady.value)
                const AppStateView.loading()
              else
                _shouldShowLoading()
                    ? _buildLoadingIndicator()
                    : _buildScholarshipsList(),
              Positioned.fill(
                child: Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowLoading() {
    return controller.isLoading.value &&
        controller.allScholarships.isEmpty &&
        DateTime.now().difference(startTime).inSeconds < 10;
  }

  Widget _buildLoadingIndicator() {
    return const AppStateView.loading();
  }

  Widget _buildScholarshipsList() {
    final isSearching = controller.hasActiveSearch;
    final items = controller.visibleScholarships;
    if (items.isEmpty && !_shouldShowLoading()) {
      return _buildEmptyState();
    }
    if (controller.listingSelection.value == 1) {
      return _buildScholarshipsPasajList(items, isSearching);
    }
    return _buildScholarshipsClassicList(items, isSearching);
  }
}
