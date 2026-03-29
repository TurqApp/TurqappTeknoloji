part of 'social_profile.dart';

extension _SocialProfileSectionsActionsPart on _SocialProfileState {
  Widget counters() {
    final items = <Widget>[
      _buildCounterTile(
        value: controller.displayCounterValue(
          viewerUserId: widget.userID,
          value: controller.totalPosts.toInt(),
        ),
        label: 'profile.posts'.tr,
        onTap: () => _changePostSelection(0),
      ),
      _buildCounterTile(
        value: controller.displayCounterValue(
          viewerUserId: widget.userID,
          value: controller.totalFollower.toInt(),
        ),
        label: 'profile.followers'.tr,
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
      ),
      _buildCounterTile(
        value: controller.displayCounterValue(
          viewerUserId: widget.userID,
          value: controller.totalFollowing.toInt(),
        ),
        label: 'profile.following'.tr,
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
      ),
      _buildCounterTile(
        value: controller.displayCounterValue(
          viewerUserId: widget.userID,
          value: controller.totalLikes.value.toInt(),
        ),
        label: 'profile.likes'.tr,
      ),
      _buildCounterTile(
        value: controller.displayCounterValue(
          viewerUserId: widget.userID,
          value: controller.totalMarket.toInt(),
        ),
        label: 'profile.listings'.tr,
        onTap: () => _changePostSelection(4),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compact = constraints.maxWidth < 390 || textScale > 1.2;
        final columns = compact ? 3 : items.length;
        const spacing = 8.0;
        final width = compact
            ? (constraints.maxWidth - (spacing * (columns - 1))) / columns
            : constraints.maxWidth / items.length;
        return Wrap(
          spacing: compact ? spacing : 0,
          runSpacing: compact ? spacing : 0,
          children: items
              .map((item) => SizedBox(width: width, child: item))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildCounterTile({
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    final child = Container(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: "MontserratMedium",
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) {
      return child;
    }
    return GestureDetector(
      onTap: onTap,
      child: child,
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
