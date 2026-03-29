part of 'profile_view.dart';

extension _ProfileViewTabsPart on _ProfileViewState {
  Widget counters() {
    final items = <Widget>[
      _buildCounterTile(
        value: NumberFormatter.format(_myTotalPosts),
        label: "profile.posts".tr,
        onTap: () => controller.setPostSelection(0),
      ),
      _buildCounterTile(
        value: NumberFormatter.format(controller.followerCount.value),
        label: "profile.followers".tr,
        onTap: () {
          _suspendProfileFeedForRoute();
          Get.to(
            () => FollowingFollowers(
              selection: 0,
              userId: _myUserId,
              nickname: _myIosSafeNickname,
            ),
          )?.then((_) {
            _resumeProfileFeedAfterRoute();
          });
        },
        semanticsLabel: IntegrationTestKeys.profileFollowersCounter,
        valueKey: const ValueKey(IntegrationTestKeys.profileFollowersCounter),
      ),
      _buildCounterTile(
        value: NumberFormatter.format(controller.followingCount.value),
        label: "profile.following".tr,
        onTap: () {
          _suspendProfileFeedForRoute();
          Get.to(
            () => FollowingFollowers(
              selection: 1,
              userId: _myUserId,
              nickname: _myIosSafeNickname,
            ),
          )?.then((_) {
            _resumeProfileFeedAfterRoute();
          });
        },
        semanticsLabel: IntegrationTestKeys.profileFollowingCounter,
        valueKey: const ValueKey(IntegrationTestKeys.profileFollowingCounter),
      ),
      _buildCounterTile(
        value: NumberFormatter.format(_myTotalLikes),
        label: "profile.likes".tr,
      ),
      _buildCounterTile(
        value: NumberFormatter.format(_myTotalMarket),
        label: "profile.listings".tr,
        onTap: () => controller.setPostSelection(4),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children:
            items.map((item) => Expanded(child: item)).toList(growable: false),
      ),
    );
  }

  Widget _buildCounterTile({
    required String value,
    required String label,
    VoidCallback? onTap,
    String? semanticsLabel,
    Key? valueKey,
  }) {
    Widget tile = Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontFamily: "MontserratBold",
            ),
          ),
          Text(
            label,
            key: valueKey,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontFamily: "MontserratMedium",
              height: 1.0,
            ),
          ),
        ],
      ),
    );

    if (semanticsLabel != null) {
      tile = Semantics(
        label: semanticsLabel,
        button: onTap != null,
        child: tile,
      );
    }

    if (onTap == null) return tile;

    return GestureDetector(
      onTap: onTap,
      child: tile,
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
                  controller.setPostSelection(0);
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
                  controller.setPostSelection(3);
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
                  controller.setPostSelection(1);
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
                  controller.setPostSelection(2);
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
                  controller.setPostSelection(5);
                },
                child: _buildPostSelectionIcon(
                  icon: Icons.access_time_outlined,
                  selected: controller.postSelection.value == 5,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(4);
                  unawaited(_loadMarketItems(force: true));
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
}
