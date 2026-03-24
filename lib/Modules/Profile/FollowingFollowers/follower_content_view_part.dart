part of 'follower_content.dart';

extension _FollowerContentViewPart on _FollowerContentState {
  Widget _buildFollowerContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openProfile,
            child: ClipOval(
              child: SizedBox(
                width: 50,
                height: 50,
                child: Obx(() {
                  final avatarUrl = controller.avatarUrl.value;
                  if (avatarUrl.isEmpty) {
                    return const Center(
                      child: CupertinoActivityIndicator(color: Colors.grey),
                    );
                  }
                  return CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    memCacheHeight: 400,
                  );
                }),
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
                    GestureDetector(
                      onTap: _openProfile,
                      child: Obx(
                        () => Text(
                          controller.nickname.value,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    RozetContent(size: 15, userID: widget.userID),
                  ],
                ),
                GestureDetector(
                  onTap: _openProfile,
                  child: Obx(
                    () => Text(
                      controller.fullname.value,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (widget.userID != _currentUid)
            Obx(() {
              if (!controller.isLoaded.value) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  _buildFollowAction(),
                ],
              );
            }),
        ],
      ),
    );
  }
}
