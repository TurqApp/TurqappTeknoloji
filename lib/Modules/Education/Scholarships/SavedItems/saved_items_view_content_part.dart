part of 'saved_items_view.dart';

extension _SavedItemsViewContentPart on _SavedItemsViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: Get.back,
                  icon: Icon(AppIcons.arrowLeft, size: 25, color: Colors.black),
                ),
                Expanded(
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTab(
                          index: 0,
                          label:
                              '${'common.saved'.tr} (${controller.bookmarkedScholarships.length})',
                        ),
                        _buildTab(
                          index: 1,
                          label:
                              '${'common.liked'.tr} (${controller.likedScholarships.length})',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(
                () => controller.isLoading.value &&
                        controller.likedScholarships.isEmpty &&
                        controller.bookmarkedScholarships.isEmpty
                    ? const Center(child: CupertinoActivityIndicator())
                    : PageView(
                        controller: controller.pageController,
                        onPageChanged: controller.onTabChanged,
                        children: [
                          _buildScholarshipList(
                            context,
                            controller.bookmarkedScholarships,
                            'scholarship.saved_empty'.tr,
                            true,
                          ),
                          _buildScholarshipList(
                            context,
                            controller.likedScholarships,
                            'scholarship.liked_empty'.tr,
                            false,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => controller.onTabChanged(index),
            child: Text(
              label,
              style: TextStyle(
                color: controller.selectedTabIndex.value == index
                    ? Colors.black
                    : Colors.black54,
                fontSize: 20,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            color: controller.selectedTabIndex.value == index
                ? Colors.black
                : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildScholarshipList(
    BuildContext context,
    RxList<Map<String, dynamic>> scholarships,
    String emptyMessage,
    bool isBookmarked,
  ) {
    return Obx(
      () => RefreshIndicator(
        backgroundColor: Colors.black,
        color: Colors.white,
        onRefresh: () async {
          await controller.fetchSavedItems();
        },
        child: scholarships.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.info, size: 35, color: Colors.grey),
                    Text(
                      emptyMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'MontserratMedium',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: scholarships.length,
                itemBuilder: (context, index) {
                  final scholarshipData = scholarships[index];
                  return _buildScholarshipCard(
                    context,
                    scholarshipData,
                    isBookmarked: isBookmarked,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildScholarshipCard(
    BuildContext context,
    Map<String, dynamic> scholarshipData, {
    required bool isBookmarked,
  }) {
    final burs = scholarshipData['model'];
    final type = scholarshipData['type'] as String;
    final userData = scholarshipData['userData'] as Map<String, dynamic>?;
    final docId = scholarshipData['docId'] as String;
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailWidth = (screenWidth * 0.31).clamp(96.0, 120.0);
    final thumbnailHeight = (thumbnailWidth * 0.75).clamp(72.0, 90.0);

    return GestureDetector(
      onTap: () => _openScholarshipDetail(scholarshipData),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(
              burs: burs,
              width: thumbnailWidth,
              height: thumbnailHeight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isIndividualScholarshipType(type)
                              ? 'scholarship.applications_suffix'.trParams({
                                  'title': burs.baslik.toString(),
                                })
                              : burs.baslik,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PullDownButton(
                        itemBuilder: (context) => _buildItemActions(
                          docId: docId,
                          type: type,
                          isBookmarked: isBookmarked,
                        ),
                        buttonBuilder: (context, showMenu) => GestureDetector(
                          onTap: showMenu,
                          child: Icon(
                            AppIcons.info,
                            size: 18,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleText(userData, burs, type),
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                      color: Colors.blue.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    burs.aciklama,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Montserrat',
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail({
    required dynamic burs,
    required double width,
    required double height,
  }) {
    if (burs.img.isNotEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            memCacheHeight: 1000,
            imageUrl: burs.img,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CupertinoActivityIndicator()),
            errorWidget: (context, url, error) => const Icon(
              Icons.error,
              color: Colors.red,
              size: 40,
            ),
          ),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image,
        color: Colors.grey,
        size: 40,
      ),
    );
  }
}
