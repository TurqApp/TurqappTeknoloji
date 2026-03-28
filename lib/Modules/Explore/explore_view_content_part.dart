part of 'explore_view.dart';

extension _ExploreViewContentPart on _ExploreViewState {
  Widget _buildSearchHeader(BuildContext context) {
    if (IntegrationTestMode.enabled) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: _IntegrationSmokeSearchHeader(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TurqSearchBar(
                controller: controller.searchController,
                focusNode: controller.searchFocus,
                hintText: 'common.search'.tr,
                onTap: () {
                  controller.isSearchMode.value = true;
                },
                onChanged: (v) {
                  controller.onSearchChanged(v);
                },
              ),
            ),
          ),
          Obx(() {
            if (!controller.isKeyboardOpen.value) {
              return const SizedBox.shrink();
            }

            return GestureDetector(
              onTap: () {
                controller.searchFocus.unfocus();
                controller.searchController.clear();
                controller.searchText.value = "";
                controller.searchedList.clear();
                controller.searchedHashtags.clear();
                controller.searchedTags.clear();
                controller.showAllRecent.value = false;
                controller.isKeyboardOpen.value = false;
                controller.isSearchMode.value = false;
                closeKeyboard(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: Colors.black,
                    size: 17,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExploreOrSearchBody(BuildContext context) {
    return Obx(() {
      final showExploreTabs = !controller.isSearchMode.value &&
          !controller.isKeyboardOpen.value &&
          controller.searchText.value.trim().isEmpty;

      if (showExploreTabs) {
        return _buildExploreTabs(context);
      }

      return Expanded(
        child: ListView(
          children: controller.searchText.value.trim().isEmpty
              ? [
                  Obx(() {
                    final recent = controller.recentSearchUsers;
                    if (recent.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: recent
                          .map(
                            (m) => SearchUserContent(
                              model: m,
                              isSearch: false,
                            ),
                          )
                          .toList(),
                    );
                  }),
                ]
              : [
                  ...controller.searchedHashtags.map((tag) {
                    final title = "#${tag.hashtag}";
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        CupertinoIcons.number,
                        color: Colors.black87,
                        size: 20,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: "MontserratSemiBold",
                        ),
                      ),
                      onTap: () {
                        controller.suspendExplorePreview();
                        Get.to(() => TagPosts(tag: tag.hashtag))?.then((_) {
                          controller.resumeExplorePreview();
                        });
                      },
                      trailing: const Icon(
                        CupertinoIcons.arrow_turn_up_left,
                        color: Colors.black45,
                        size: 18,
                      ),
                    );
                  }),
                  ...controller.searchedTags.map((tag) {
                    final title = tag.hashtag;
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        CupertinoIcons.tag,
                        color: Colors.black87,
                        size: 20,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: "MontserratSemiBold",
                        ),
                      ),
                      onTap: () {
                        controller.suspendExplorePreview();
                        Get.to(() => TagPosts(tag: tag.hashtag))?.then((_) {
                          controller.resumeExplorePreview();
                        });
                      },
                      trailing: const Icon(
                        CupertinoIcons.arrow_turn_up_left,
                        color: Colors.black45,
                        size: 18,
                      ),
                    );
                  }),
                  ...controller.searchedList.map(
                    (u) => SearchUserContent(
                      model: u,
                      isSearch: true,
                    ),
                  ),
                ],
        ),
      );
    });
  }

  Widget _buildScrollToTopButton() {
    return Obx(() {
      return controller.showScrollToTop.value
          ? Positioned(
              bottom: 80,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  controller.floodsScroll.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.bounceIn,
                  );
                  controller.scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.bounceIn,
                  );
                  controller.exploreScroll.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.bounceIn,
                  );
                  controller.photoScroll.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.bounceIn,
                  );
                  controller.videoScroll.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.bounceIn,
                  );
                },
                child: RoadToTop(),
              ),
            )
          : const SizedBox();
    });
  }
}

class _IntegrationSmokeSearchHeader extends StatelessWidget {
  const _IntegrationSmokeSearchHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TurqSearchBar.height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: const [
          Icon(CupertinoIcons.search, color: Colors.grey, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
