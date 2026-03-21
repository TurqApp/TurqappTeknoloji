part of 'scholarships_view.dart';

extension ScholarshipsViewActionsPart on _ScholarshipsViewState {
  Widget _buildUserHeader(String type, Map<String, dynamic>? userData,
      Map<String, dynamic>? firmaData) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildUserInfo(type, userData, firmaData)),
          if (_shouldShowFollowButton(userData)) ...[
            8.pw,
            _buildFollowButton(userData),
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfo(String type, Map<String, dynamic>? userData,
      Map<String, dynamic>? firmaData) {
    final userId = userData?['userID']?.toString() ?? '';
    return GestureDetector(
      onTap: _getUserTapHandler(type, userData),
      child: Row(
        children: [
          _buildUserAvatar(type, userData, firmaData),
          6.pw,
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _truncateLabel(
                      _getUserDisplayName(type, userData, firmaData),
                      maxChars: 30,
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                if (isIndividualScholarshipType(type) &&
                    userId.isNotEmpty) ...[
                  4.pw,
                  RozetContent(
                    size: 13,
                    userID: userId,
                    leftSpacing: 0,
                    rozetValue: userData?['rozet']?.toString(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String type, Map<String, dynamic>? userData,
      Map<String, dynamic>? firmaData) {
    final imageUrl = (userData?['avatarUrl'] ?? '').toString();
    return CircleAvatar(
      radius: 15,
      child: imageUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => CupertinoActivityIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            )
          : Icon(Icons.person, size: 20),
    );
  }

  VoidCallback? _getUserTapHandler(
      String type, Map<String, dynamic>? userData) {
    final uid = userData?['userID']?.toString() ?? '';
    if (uid != CurrentUserService.instance.userId) {
      return () {
        Get.to(() => SocialProfile(userID: uid));
      };
    }
    return null;
  }

  String _getUserDisplayName(String type, Map<String, dynamic>? userData,
      Map<String, dynamic>? firmaData) {
    final nick = (userData?['displayName'] ??
            userData?['username'] ??
            userData?['nickname'])
        ?.toString();
    if (nick != null && nick.isNotEmpty) return nick;
    final first = userData?['firstName']?.toString() ?? '';
    final last = userData?['lastName']?.toString() ?? '';
    final full = ('$first $last').trim();
    return full.isNotEmpty ? full : 'common.user'.tr;
  }

  String _truncateLabel(String value, {required int maxChars}) {
    final trimmed = value.trim();
    if (trimmed.length <= maxChars) {
      return trimmed;
    }
    final cutIndex = trimmed.lastIndexOf(' ', maxChars);
    final safeIndex = cutIndex > 0 ? cutIndex : maxChars;
    return '${trimmed.substring(0, safeIndex).trimRight()}...';
  }

  bool _shouldShowFollowButton(Map<String, dynamic>? userData) {
    final currentUid = CurrentUserService.instance.userId;
    return userData?['userID']?.toString() != currentUid;
  }

  Widget _buildFollowButton(Map<String, dynamic>? userData) {
    final userId = userData?['userID']?.toString() ?? '';
    return Obx(
      () {
        final isLoading = controller.followLoading[userId] ?? false;
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 86),
          child: ScaleTap(
            enabled: !isLoading,
            onPressed: isLoading ? null : () => _handleFollowTap(userData),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getFollowButtonColor(userData),
                border: Border.all(width: 1, color: Colors.black),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getFollowButtonTextColor(userData),
                        ),
                      ),
                    )
                  : Text(
                      _getFollowButtonText(userData),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        color: _getFollowButtonTextColor(userData),
                        fontSize: 12,
                        fontFamily: "MontserratBold",
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Color _getFollowButtonColor(Map<String, dynamic>? userData) {
    final isFollowing =
        controller.followedUsers[userData?['userID']?.toString() ?? ''] ??
            false;
    return isFollowing ? Colors.white : Colors.black;
  }

  String _getFollowButtonText(Map<String, dynamic>? userData) {
    final isFollowing =
        controller.followedUsers[userData?['userID']?.toString() ?? ''] ??
            false;
    return isFollowing ? 'following.following'.tr : 'following.follow'.tr;
  }

  Color _getFollowButtonTextColor(Map<String, dynamic>? userData) {
    final isFollowing =
        controller.followedUsers[userData?['userID']?.toString() ?? ''] ??
            false;
    return isFollowing ? Colors.black : Colors.white;
  }

  Future<void> _handleFollowTap(Map<String, dynamic>? userData) async {
    final followedId = userData?['userID']?.toString() ?? '';
    if (followedId.isEmpty) return;
    await controller.toggleFollow(followedId);
    controller.allScholarships.refresh();
    controller.visibleScholarships.refresh();
  }

  Widget _buildScholarshipImage(int index, String type, dynamic burs,
      Map<String, dynamic> scholarshipData) {
    return GestureDetector(
      onTap: () =>
          Get.to(() => ScholarshipDetailView(), arguments: scholarshipData),
      onDoubleTap: () => controller.toggleLike(scholarshipData['docId'], type),
      child: _hasMultipleImages(type, burs)
          ? _buildMultipleImagesView(index, burs)
          : _buildSingleImageView(burs),
    );
  }

  bool _hasMultipleImages(String type, dynamic burs) {
    return isIndividualScholarshipType(type) &&
        burs is IndividualScholarshipsModel &&
        burs.img2.isNotEmpty;
  }

  Widget _buildMultipleImagesView(int index, IndividualScholarshipsModel burs) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            itemCount: 2,
            itemBuilder: (context, pageIndex) {
              final imageUrl = pageIndex == 0 ? burs.img : burs.img2;
              return _buildNetworkImage(imageUrl);
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

  Widget _buildSingleImageView(dynamic burs) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: _buildNetworkImage(burs.img),
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
          '(${ 'scholarship.closed'.tr})',
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
    return Column(
      children: [
        5.ph,
        Obx(
          () => GestureDetector(
            onTap: () => controller.toggleExpanded(index),
            child: Text(
              controller.isExpandedList[index].value
                  ? 'common.show_less'.tr
                  : 'common.show_more'.tr,
              style: TextStyle(
                fontSize: 13,
                fontFamily: "Montserrat",
                color: Colors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ],
    );
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
            CurrentUserService.instance.userId;

    return GestureDetector(
      onTap: () =>
          Get.to(() => ScholarshipDetailView(), arguments: scholarshipData),
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
    if (isIndividualScholarshipType(type)) {
      return 'pasaj.job_finder.apply'.tr;
    }
    return 'common.details'.tr;
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
                  Get.delete<CreateScholarshipController>(force: true);
                  Get.to(CreateScholarshipView())?.then((_) async {
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
                  Get.to(MyScholarshipView())?.then((_) async {
                    await controller.fetchScholarships();
                    await controller.refreshTotalCount();
                  });
                },
              ),
              PullDownMenuItem(
                title: 'common.saved'.tr,
                icon: CupertinoIcons.bookmark,
                onTap: () => Get.to(() => SavedItemsView()),
              ),
              PullDownMenuItem(
                title: 'common.applications'.tr,
                icon: CupertinoIcons.doc_plaintext,
                onTap: () => Get.to(() => ApplicationsView()),
              ),
              PullDownMenuItem(
                title: 'explore.tab.for_you'.tr,
                icon: CupertinoIcons.star,
                onTap: () => Get.to(PersonalizedView()),
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
