part of 'my_statistic_view.dart';

extension _MyStatisticViewContentPart on _MyStatisticViewState {
  Widget _buildMyStatisticContent() {
    final currentUser = userService.currentUserRx.value;
    final avatarUrl = currentUser?.avatarUrl ?? '';
    final firstName = currentUser?.firstName ?? '';
    final lastName = currentUser?.lastName ?? '';
    final nickname = currentUser?.nickname ?? '';

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: CupertinoActivityIndicator(
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "$firstName $lastName",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          RozetContent(
                            size: 15,
                            userID: _currentUid,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nickname,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'statistics.you'.tr,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'statistics.notice'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => _buildStatItem(
            controller.profileVisitsApprox.value,
            'statistics.profile_visits_30d'.tr,
            0,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _buildStatItem(
                  controller.postViews30d.value,
                  'statistics.post_views'.tr,
                  1,
                ),
              ),
            ),
            8.pw,
            Expanded(
              child: Obx(
                () => _buildStatItem(
                  controller.posts30d.value,
                  'statistics.post_count'.tr,
                  2,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _buildStatItem(
                  controller.stories30d.value,
                  'statistics.story_count'.tr,
                  6,
                ),
              ),
            ),
            8.pw,
            Expanded(
              child: Obx(
                () => _buildStatItem(
                  controller.followerGrowth30d.value,
                  'statistics.follower_growth'.tr,
                  8,
                ),
              ),
            ),
          ],
        ),
        10.ph,
        const AdmobKare(
          suggestionPlacementId: 'profile',
        ),
        10.ph,
      ],
    );
  }

  Widget _buildStatItem(num value, String title, int colorIndex) {
    final bgColor = _MyStatisticViewState
        ._statColors[colorIndex % _MyStatisticViewState._statColors.length];
    final displayText = NumberFormatter.format(value.toInt());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            children: [
              Text(
                displayText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
