part of 'scholarships_view.dart';

const int _pasajListAdInterval = 6;
const int _loadMoreTriggerDistance = 10;

extension ScholarshipsViewListPart on _ScholarshipsViewState {
  Widget _buildScholarshipsClassicList(
    List<Map<String, dynamic>> items,
    bool isSearching,
  ) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length + (controller.isLoadingMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(animating: true),
            ),
          );
        }

        _maybeLoadMoreForIndex(
          index: index,
          totalItems: items.length,
          isSearching: isSearching,
        );

        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: _buildScholarshipCard(index, items),
          );
        }

        return _buildScholarshipCard(index, items);
      },
    );
  }

  Widget _buildScholarshipsPasajList(
    List<Map<String, dynamic>> items,
    bool isSearching,
  ) {
    final adCount = items.length ~/ _pasajListAdInterval;
    final contentItemCount = items.length + adCount;
    final totalItemCount =
        contentItemCount + (controller.isLoadingMore.value ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        if (index == contentItemCount) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(animating: true),
            ),
          );
        }

        if (_isPasajAdIndex(index)) {
          final slot = ((index + 1) ~/ (_pasajListAdInterval + 1)) - 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: AdmobKare(
              key: ValueKey('scholarship-list-ad-$slot'),
              suggestionPlacementId: 'scholarship',
            ),
          );
        }

        final itemIndex = _pasajItemIndexForBuilderIndex(index);
        _maybeLoadMoreForIndex(
          index: itemIndex,
          totalItems: items.length,
          isSearching: isSearching,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: _buildScholarshipListingCard(items[itemIndex]),
        );
      },
    );
  }

  bool _isPasajAdIndex(int builderIndex) {
    return (builderIndex + 1) % (_pasajListAdInterval + 1) == 0;
  }

  int _pasajItemIndexForBuilderIndex(int builderIndex) {
    return builderIndex - ((builderIndex + 1) ~/ (_pasajListAdInterval + 1));
  }

  void _maybeLoadMoreForIndex({
    required int index,
    required int totalItems,
    required bool isSearching,
  }) {
    if (isSearching ||
        controller.isLoadingMore.value ||
        !controller.hasMoreData.value ||
        totalItems == 0) {
      return;
    }
    final triggerIndex = (totalItems - _loadMoreTriggerDistance).clamp(
      0,
      totalItems - 1,
    );
    if (index < triggerIndex) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.loadMoreScholarships();
    });
  }

  Widget _buildEmptyState() {
    final isSearching = controller.hasActiveSearch;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: Get.height * 0.15),
        Icon(
          isSearching ? CupertinoIcons.search : CupertinoIcons.doc_text,
          size: 48,
          color: Colors.grey.shade500,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            isSearching ? 'common.no_results'.tr : 'scholarship.empty_title'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (isSearching) ...[
          Center(
            child: Text(
              'scholarship.no_results_for'
                  .trParams({'query': controller.searchQuery.value}),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'scholarship.search_hint_body'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchTipsChips(),
        ] else ...[
          Center(
            child: Text(
              'scholarship.empty_body'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchTipsChips() {
    final tips = [
      'scholarship.title_label'.tr,
      'scholarship.cities_label'.tr,
      'scholarship.universities_label'.tr,
      'scholarship.provider_label'.tr,
      'signup.username'.tr,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'scholarship.search_tip_header'.tr,
            style: TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: tips.map((tip) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  tip,
                  style: TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScholarshipCard(int index, List<Map<String, dynamic>> items) {
    final isSearching = controller.hasActiveSearch;
    if (!isSearching && index == 4 && controller.hasMoreData.value) {
      controller.loadMoreScholarships();
    }

    final scholarshipData = items[index];
    final burs = scholarshipData['model'];
    final type = kIndividualScholarshipType;
    final userData = scholarshipData['userData'] as Map<String, dynamic>?;
    final firmaData = null;
    final docId = scholarshipData['docId'] as String;
    final daysDiff = _calculateDaysDiff(type, burs);

    final children = <Widget>[];

    if (burs.img.isNotEmpty) {
      children.add(
        Row(
          children: [
            Expanded(child: _buildUserHeader(type, userData, firmaData)),
            5.pw,
          ],
        ),
      );
      children.add(8.ph);
      children.add(_buildScholarshipImage(index, type, burs, scholarshipData));
    }

    children.add(
      _buildScholarshipContent(
        index,
        type,
        burs,
        userData,
        firmaData,
        daysDiff,
        scholarshipData,
        docId,
      ),
    );

    if ((index + 1) % 3 == 0) {
      final slot = ((index + 1) ~/ 3);
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: AdmobKare(
            key: ValueKey('scholarship-ad-$slot'),
            suggestionPlacementId: 'scholarship',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  int _calculateDaysDiff(String type, dynamic burs) {
    if (!isIndividualScholarshipType(type) ||
        burs is! IndividualScholarshipsModel) {
      return -1;
    }
    final rawEndDate = burs.bitisTarihi.trim();
    if (rawEndDate.isEmpty) return -1;
    try {
      final endDate = DateFormat('dd.MM.yyyy').parseStrict(rawEndDate);
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      return endDateOnly.difference(todayOnly).inDays;
    } catch (_) {
      return -1;
    }
  }

  Widget _buildScholarshipListingCard(Map<String, dynamic> scholarshipData) {
    final docId = (scholarshipData['docId'] ?? '').toString();
    return ScholarshipListingCard(
      scholarshipData: scholarshipData,
      isSaved: controller.bookmarkedScholarships[docId] ?? false,
      onOpen: () async {
        await ScholarshipNavigationService.openDetail(scholarshipData);
      },
      onToggleSaved: () => controller.toggleBookmark(
        docId,
        kIndividualScholarshipType,
      ),
      onShare: () => controller.shareScholarshipExternally(scholarshipData),
    );
  }
}
