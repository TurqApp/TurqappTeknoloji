part of 'social_profile.dart';

extension _SocialProfileSectionsActionsPart on _SocialProfileState {
  Widget counters() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              _changePostSelection(0);
            },
            child: Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      controller.displayCounterValue(
                        viewerUserId: widget.userID,
                        value: controller.totalPosts.toInt(),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    Text(
                      'profile.posts'.tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              _setCenteredIndex(-1);
              Get.to(
                () => FollowingFollowers(
                  selection: 0,
                  userId: widget.userID,
                  nickname: controller.nickname.value,
                ),
              )?.then((_) {
                controller.resumeCenteredPost();
              });
            },
            child: Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      controller.displayCounterValue(
                        viewerUserId: widget.userID,
                        value: controller.totalFollower.toInt(),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    Text(
                      'profile.followers'.tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              _setCenteredIndex(-1);
              Get.to(
                () => FollowingFollowers(
                  selection: 1,
                  userId: widget.userID,
                  nickname: controller.nickname.value,
                ),
              )?.then((_) {
                controller.resumeCenteredPost();
              });
            },
            child: Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      controller.displayCounterValue(
                        viewerUserId: widget.userID,
                        value: controller.totalFollowing.toInt(),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    Text(
                      'profile.following'.tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    controller.displayCounterValue(
                      viewerUserId: widget.userID,
                      value: controller.totalLikes.value.toInt(),
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  Text(
                    'profile.likes'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              _changePostSelection(4);
            },
            child: Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      controller.displayCounterValue(
                        viewerUserId: widget.userID,
                        value: controller.totalMarket.toInt(),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    Text(
                      'profile.listings'.tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget postButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.translate(
          offset: const Offset(3, 0),
          child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(0);
                },
                child: _buildPostSelectionIcon(
                  icon: Icons.tag,
                  selected: controller.postSelection.value == 0,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(3);
                },
                child: _buildPostSelectionIcon(
                  icon: Icons.repeat,
                  selected: controller.postSelection.value == 3,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(1);
                },
                child: _buildPostSelectionIcon(
                  icon: Icons.play_circle_outline,
                  selected: controller.postSelection.value == 1,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(2);
                },
                child: _buildPostSelectionIcon(
                  icon: Icons.photo_outlined,
                  selected: controller.postSelection.value == 2,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(5);
                },
                child: _buildPostSelectionIcon(
                  icon: Icons.access_time,
                  selected: controller.postSelection.value == 5,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(4);
                },
                child: _buildPostSelectionIcon(
                  icon: Icons.shopping_bag_outlined,
                  selected: controller.postSelection.value == 4,
                ),
              ),
            ),
          ],
        ),
        ),
      ],
    );
  }

  Widget _buildPostSelectionIcon({
    required IconData icon,
    required bool selected,
  }) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        height: 30,
        child: Center(
          child: Icon(
            icon,
            color: selected ? Colors.pink : Colors.black,
            size: selected ? 30 : 25,
          ),
        ),
      ),
    );
  }

  Widget buildMarkets(BuildContext context) {
    if (!_marketLoading &&
        _marketItems.isEmpty &&
        widget.userID.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _marketLoading) return;
        unawaited(_loadMarketItems(force: false));
      });
    }
    return CustomScrollView(
      controller: _scrollControllerForSelection(4),
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (_marketLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 28),
              child: Center(child: CupertinoActivityIndicator()),
            ),
          )
        else if (_marketItems.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: EmptyRow(text: 'profile.no_listings'.tr),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 0.48,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMarketGridCard(_marketItems[index]),
                childCount: _marketItems.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMarketGridCard(MarketItemModel item) {
    final statusColor = _marketStatusColor(item.status);
    return GestureDetector(
      onTap: () async {
        _suspendCenteredPostForRoute();
        await Get.to(() => MarketDetailView(item: item));
        await _loadMarketItems(force: true);
        _resumeCenteredPostAfterRoute();
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.78,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.coverImageUrl.trim().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.coverImageUrl,
                          cacheManager: TurqImageCacheManager.instance,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          memCacheHeight: 400,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.withAlpha(30),
                          ),
                          errorWidget: (context, url, error) =>
                              _marketImageFallback(),
                        )
                      : _marketImageFallback(),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _marketStatusLabel(item.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatMarketMoney(item.price)} ${marketCurrencyLabel(item.currency)}',
                    style: const TextStyle(
                      color: Color(0xFF8B0000),
                      fontSize: 19,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.locationText.isEmpty
                        ? 'profile.location_missing'.tr
                        : item.locationText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 30,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        _suspendCenteredPostForRoute();
                        await Get.to(() => MarketDetailView(item: item));
                        await _loadMarketItems(force: true);
                        _resumeCenteredPostAfterRoute();
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'profile.review'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _marketImageFallback() {
    return Container(
      color: Colors.grey.withAlpha(25),
      alignment: Alignment.center,
      child: Icon(
        CupertinoIcons.photo,
        color: Colors.grey.withAlpha(170),
        size: 26,
      ),
    );
  }

  Color _marketStatusColor(String status) {
    switch (status) {
      case 'sold':
        return const Color(0xFFB91C1C);
      case 'reserved':
        return const Color(0xFF1D4ED8);
      case 'draft':
        return const Color(0xFF7C3AED);
      case 'archived':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF111827);
    }
  }

  String _marketStatusLabel(String status) {
    switch (status) {
      case 'sold':
        return 'profile.status_sold'.tr;
      case 'reserved':
      case 'draft':
      case 'archived':
        return 'profile.status_passive'.tr;
      default:
        return 'profile.status_active'.tr;
    }
  }

  String _formatMarketMoney(double value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      final reverseIndex = rounded.length - i;
      buffer.write(rounded[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}
