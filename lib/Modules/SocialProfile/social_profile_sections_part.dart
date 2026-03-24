part of 'social_profile.dart';

extension _SocialProfileSectionsPart on _SocialProfileState {
  Widget _buildLinksAndHighlightsRow() {
    final tag = 'highlights_${widget.userID}';
    final hlController = StoryHighlightsController.maybeFind(tag: tag);
    if (hlController == null) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      final mixedItems = <Map<String, dynamic>>[];
      for (final social in controller.socialMediaList) {
        mixedItems.add({
          'type': 'link',
          'createdAt': int.tryParse(social.docID) ?? 0,
          'data': social,
        });
      }
      for (final hl in hlController.highlights) {
        mixedItems.add({
          'type': 'highlight',
          'createdAt': hl.createdAt.millisecondsSinceEpoch,
          'data': hl,
        });
      }
      if (mixedItems.isEmpty) return const SizedBox.shrink();
      mixedItems.sort(
          (a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));

      return Padding(
        padding: const EdgeInsets.only(top: 7, bottom: 4),
        child: SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: mixedItems.length,
            itemBuilder: (context, index) {
              final item = mixedItems[index];
              if (item['type'] == 'link') {
                final social = item['data'] as SocialMediaModel;
                return Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: SizedBox(
                    width: 70,
                    child: GestureDetector(
                      onTap: () {
                        confirmAndLaunchExternalUrl(Uri.parse(social.url));
                      },
                      child: SocialMediaContent(model: social),
                    ),
                  ),
                );
              }
              final hl = item['data'] as StoryHighlightModel;
              return Padding(
                padding: const EdgeInsets.only(right: 18),
                child: StoryHighlightCircle(
                  highlight: hl,
                  onTap: () => HighlightStoryViewerService.openHighlight(
                    userId: widget.userID,
                    highlight: hl,
                  ),
                  onLongPress: () {
                    final myUid = _myUserId;
                    if (widget.userID == myUid) {
                      noYesAlert(
                        title: 'profile.remove_highlight_title'.tr,
                        message: 'profile.remove_highlight_body'.tr,
                        cancelText: 'common.cancel'.tr,
                        yesText: 'profile.remove_highlight_confirm'.tr,
                        onYesPressed: () {
                          hlController.deleteHighlight(hl.id);
                        },
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      );
    });
  }

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
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(0);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.tag,
                        color: controller.postSelection.value == 0
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 0 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(3);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.repeat,
                        color: controller.postSelection.value == 3
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 3 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(1);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: controller.postSelection.value == 1
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 1 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(2);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        color: controller.postSelection.value == 2
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 2 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _changePostSelection(5);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: controller.postSelection.value == 5
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 5 ? 30 : 25,
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
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: controller.postSelection.value == 4
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 4 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildMarkets(BuildContext context) {
    return ListView(
      controller: _scrollControllerForSelection(4),
      children: [header(), EmptyRow(text: 'profile.no_listings'.tr)],
    );
  }
}
