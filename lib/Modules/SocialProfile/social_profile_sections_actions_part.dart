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
    return ListView(
      controller: _scrollControllerForSelection(4),
      children: [header(), EmptyRow(text: 'profile.no_listings'.tr)],
    );
  }
}
