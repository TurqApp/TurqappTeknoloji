part of 'scholarships_view.dart';

extension ScholarshipsViewActionsPart on _ScholarshipsViewState {
  Widget _buildScholarshipImage(int index, String type, dynamic burs,
      Map<String, dynamic> scholarshipData) {
    return GestureDetector(
      onDoubleTap: () => controller.toggleLike(scholarshipData['docId'], type),
      child: _hasMultipleImages(type, burs)
          ? _buildMultipleImagesView(index, burs, scholarshipData)
          : _buildSingleImageView(burs, scholarshipData),
    );
  }

  Future<void> _openScholarshipDetail(
    Map<String, dynamic> scholarshipData,
  ) async {
    await ScholarshipNavigationService.openDetail(scholarshipData);
  }

  Future<void> _openScholarshipWebsite(String website) async {
    final url = Uri.parse(ensureUrlHasScheme(website));
    if (await canLaunchUrl(url)) {
      await confirmAndLaunchExternalUrl(url);
      return;
    }
    AppSnackbar(
      'common.error'.tr,
      'scholarship.website_open_failed'.tr,
    );
  }

  bool _hasMultipleImages(String type, dynamic burs) {
    return false;
  }

  Widget _buildMultipleImagesView(
    int index,
    IndividualScholarshipsModel burs,
    Map<String, dynamic> scholarshipData,
  ) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            itemCount: 2,
            itemBuilder: (context, pageIndex) {
              final imageUrl = pageIndex == 0 ? burs.img : burs.img2;
              return _buildInteractiveScholarshipImage(
                burs: burs,
                scholarshipData: scholarshipData,
                imageUrl: imageUrl,
              );
            },
            onPageChanged: (pageIndex) =>
                controller.updatePageIndex(index, pageIndex),
          ),
        ),
        8.ph,
        _buildPageIndicators(index),
      ],
    );
  }

  Widget _buildSingleImageView(
    dynamic burs,
    Map<String, dynamic> scholarshipData,
  ) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: _buildInteractiveScholarshipImage(
        burs: burs,
        scholarshipData: scholarshipData,
        imageUrl: burs.img,
      ),
    );
  }

  Widget _buildInteractiveScholarshipImage({
    required dynamic burs,
    required Map<String, dynamic> scholarshipData,
    required String imageUrl,
  }) {
    final website =
        burs is IndividualScholarshipsModel ? burs.website.trim() : '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openScholarshipDetail(scholarshipData),
              child: _buildNetworkImage(imageUrl),
            ),
            if (website.isNotEmpty)
              Positioned(
                left: width * 0.045,
                right: width * 0.12,
                bottom: math.max(0.0, height * 0.015 - 3),
                height: height * 0.11,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openScholarshipWebsite(website),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    final safeUrl = imageUrl.trim();
    if (safeUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return CachedNetworkImage(
      imageUrl: safeUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          const Center(child: CupertinoActivityIndicator()),
      errorWidget: (context, url, error) =>
          const Icon(Icons.error, color: Colors.red, size: 40),
    );
  }

  Widget _buildPageIndicators(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (dotIndex) {
        return Obx(
          () => Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (controller.pageIndices[index]?.value ?? 0) == dotIndex
                  ? Colors.black
                  : Colors.grey,
            ),
          ),
        );
      }),
    );
  }

  bool _isTextLongerThanTwoLines(String text, BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: "Montserrat",
          color: Colors.black,
        ),
      ),
      maxLines: 2,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 30);

    return textPainter.didExceedMaxLines;
  }

  Widget _buildScholarshipContent(
    int index,
    String type,
    dynamic burs,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? firmaData,
    int daysDiff,
    Map<String, dynamic> scholarshipData,
    String docId,
  ) {
    final displayDescription = _getDisplayDescription(type, burs);
    final canExpandDescription =
        displayDescription == burs.aciklama && displayDescription.isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          10.ph,
          _buildScholarshipTitle(index, type, burs, daysDiff),
          5.ph,
          _buildScholarshipDescription(index, type, burs),
          if (isIndividualScholarshipType(type) &&
              canExpandDescription &&
              (_isTextLongerThanTwoLines(displayDescription, Get.context!) ||
                  _isTextLongerThanTwoLines(
                    'scholarship.applications_suffix'.trParams({
                      'title': burs.baslik.toString(),
                    }),
                    Get.context!,
                  )))
            _buildExpandButton(index),
          10.ph,
          _buildActionRow(type, userData, scholarshipData, docId),
          15.ph,
        ],
      ),
    );
  }

  Widget _buildScholarshipTitle(
    int index,
    String type,
    dynamic burs,
    int daysDiff,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: isIndividualScholarshipType(type)
              ? GestureDetector(
                  onTap: () => controller.toggleExpanded(index),
                  child: Obx(
                    () => Text(
                      'scholarship.applications_suffix'.trParams({
                        'title': burs.baslik.toString(),
                      }),
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                        color: Colors.black,
                      ),
                      overflow: controller.isExpandedList[index].value
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      maxLines:
                          controller.isExpandedList[index].value ? null : 2,
                    ),
                  ),
                )
              : Text(
                  burs.baslik,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: "MontserratBold",
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
        ),
        _buildDeadlineIndicator(daysDiff),
      ],
    );
  }

  Widget _buildDeadlineIndicator(int daysDiff) {
    if (daysDiff < 0) {
      return Padding(
        padding: EdgeInsets.only(left: 8),
        child: Text(
          '(${'scholarship.closed'.tr})',
          style: TextStyle(
            fontSize: 14,
            fontFamily: "MontserratBold",
            color: Colors.red,
          ),
        ),
      );
    }

    if (daysDiff == 0) {
      return Padding(
        padding: EdgeInsets.only(left: 8),
        child: Text(
          'common.last_day'.tr,
          style: TextStyle(
            fontSize: 14,
            fontFamily: "MontserratBold",
            color: Colors.red,
          ),
        ),
      );
    }

    if (daysDiff > 0 && daysDiff <= 6) {
      return Padding(
        padding: EdgeInsets.only(left: 8),
        child: Text(
          '(Son ${daysDiff + 1} gün)',
          style: TextStyle(
            fontSize: 14,
            fontFamily: "MontserratBold",
            color: Colors.red,
          ),
        ),
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildScholarshipDescription(int index, String type, dynamic burs) {
    if (isIndividualScholarshipType(type)) {
      final description = _getDisplayDescription(type, burs);
      final canExpand = description == burs.aciklama && description.isNotEmpty;
      final baseStyle = TextStyle(
        fontSize: 13,
        fontFamily: "Montserrat",
        color: Colors.black,
      );
      if (!canExpand) {
        return Text.rich(
          ScholarshipRichText.build(
            description,
            baseStyle: baseStyle,
          ),
          style: baseStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      }
      return Obx(
        () => GestureDetector(
          onTap: () => controller.toggleExpanded(index),
          child: Text.rich(
            ScholarshipRichText.build(
              description,
              baseStyle: baseStyle,
            ),
            style: baseStyle,
            maxLines: controller.isExpandedList[index].value ? null : 2,
            overflow: controller.isExpandedList[index].value
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
        ),
      );
    } else {
      final baseStyle = TextStyle(
        fontSize: 13,
        fontFamily: "Montserrat",
        color: Colors.black,
      );
      return Text.rich(
        ScholarshipRichText.build(
          _getDisplayDescription(type, burs),
          baseStyle: baseStyle,
        ),
        style: baseStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  String _getDisplayDescription(String type, dynamic burs) {
    if (isIndividualScholarshipType(type) &&
        burs is IndividualScholarshipsModel) {
      final summary = burs.shortDescription.trim();
      if (summary.isNotEmpty) return summary;
      return burs.aciklama;
    }
    return burs.aciklama ?? '';
  }

  Widget _buildExpandButton(int index) {
    return Obx(() {
      if (controller.isExpandedList[index].value) {
        return const SizedBox.shrink();
      }
      return Column(
        children: [
          5.ph,
          GestureDetector(
            onTap: () => controller.toggleExpanded(index),
            child: Text(
              'common.show_more'.tr,
              style: TextStyle(
                fontSize: 13,
                fontFamily: "Montserrat",
                color: Colors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildActionRow(
    String type,
    Map<String, dynamic>? userData,
    Map<String, dynamic> scholarshipData,
    String docId,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildMainActionButton(type, userData, scholarshipData),
        ),
        const SizedBox(width: 8),
        _buildInteractionButtons(scholarshipData, docId, type),
      ],
    );
  }

  Widget _buildMainActionButton(
    String type,
    Map<String, dynamic>? userData,
    Map<String, dynamic> scholarshipData,
  ) {
    final isOwnScholarship = isIndividualScholarshipType(type) &&
        userData?['userID']?.toString() ==
            CurrentUserService.instance.effectiveUserId;

    return GestureDetector(
      onTap: () => ScholarshipNavigationService.openDetail(scholarshipData),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOwnScholarship ? Colors.red.shade800 : Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _getMainActionButtonText(type, isOwnScholarship),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getMainActionButtonText(String type, bool isOwnScholarship) {
    if (isOwnScholarship) return 'common.view'.tr;
    return 'pasaj.market.inspect'.tr;
  }

  Widget _buildInteractionButtons(
      Map<String, dynamic> scholarshipData, String docId, String type) {
    return Wrap(
      spacing: 8,
      children: [
        _buildLikeButton(scholarshipData, docId, type),
        _buildShareButton(scholarshipData),
        _buildBookmarkButton(scholarshipData, docId, type),
      ],
    );
  }

  Widget _buildLikeButton(
      Map<String, dynamic> scholarshipData, String docId, String type) {
    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EducationActionIconButton(
            onTap: () => controller.toggleLike(docId, type),
            icon: (controller.likedScholarships[docId] ?? false)
                ? CupertinoIcons.hand_thumbsup_fill
                : CupertinoIcons.hand_thumbsup,
            iconSize: 18,
            iconColor: controller.likedScholarships[docId] ?? false
                ? Colors.blue
                : Colors.black87,
          ),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Text(
              NumberFormatter.format(scholarshipData['likesCount'].toInt()),
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Montserrat",
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkButton(
      Map<String, dynamic> scholarshipData, String docId, String type) {
    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EducationActionIconButton(
            onTap: () => controller.toggleBookmark(docId, type),
            icon: (controller.bookmarkedScholarships[docId] ?? false)
                ? CupertinoIcons.bookmark_fill
                : CupertinoIcons.bookmark,
            iconSize: 18,
            iconColor: controller.bookmarkedScholarships[docId] ?? false
                ? Colors.orange
                : Colors.black87,
          ),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Text(
              NumberFormatter.format(scholarshipData['bookmarksCount'].toInt()),
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Montserrat",
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(Map<String, dynamic> scholarshipData) {
    return EducationShareIconButton(
      onTap: () {
        controller.shareScholarshipExternally(scholarshipData);
      },
    );
  }

  Widget _buildScrollToTopButton() {
    return ScrollTotopButton(
      scrollController: _scrollController,
      visibilityThreshold: 350,
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Obx(
      () => Positioned(
        bottom: 20,
        right: 20,
        child: Visibility(
          visible: controller.scrollOffset.value <= 350,
          child: ActionButton(
            context: context,
            permissionScope: ActionButtonPermissionScope.scholarships,
            menuItems: [
              PullDownMenuItem(
                title: 'scholarship.create_title'.tr,
                icon: CupertinoIcons.add_circled,
                onTap: () async {
                  final allowed = await ensureCurrentUserRozetPermission(
                    minimumRozet: 'sari',
                    featureName: 'scholarship.create_title'.tr,
                  );
                  if (!allowed) return;
                  ScholarshipNavigationService.openCreate(
                    resetController: true,
                  ).then((_) async {
                    await controller.fetchScholarships();
                    await controller.refreshTotalCount();
                  });
                },
              ),
              PullDownMenuItem(
                title: 'scholarship.my_listings'.tr,
                icon: CupertinoIcons.doc_text,
                onTap: () async {
                  final allowed = await ensureCurrentUserRozetPermission(
                    minimumRozet: 'sari',
                    featureName: 'scholarship.my_listings'.tr,
                  );
                  if (!allowed) return;
                  ScholarshipNavigationService.openMyScholarships()
                      .then((_) async {
                    await controller.fetchScholarships();
                    await controller.refreshTotalCount();
                  });
                },
              ),
              PullDownMenuItem(
                title: 'common.saved'.tr,
                icon: CupertinoIcons.bookmark,
                onTap: ScholarshipNavigationService.openSavedItems,
              ),
              PullDownMenuItem(
                title: 'common.applications'.tr,
                icon: CupertinoIcons.doc_plaintext,
                onTap: ScholarshipNavigationService.openApplications,
              ),
              PullDownMenuItem(
                title: 'explore.tab.for_you'.tr,
                icon: CupertinoIcons.star,
                onTap: ScholarshipNavigationService.openPersonalized,
              ),
              PullDownMenuItem(
                title: 'settings.title'.tr,
                icon: CupertinoIcons.gear,
                onTap: () => controller.settings(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
