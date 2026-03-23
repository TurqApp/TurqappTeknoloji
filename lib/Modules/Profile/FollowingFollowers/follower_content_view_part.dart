part of 'follower_content.dart';

extension _FollowerContentViewPart on _FollowerContentState {
  Widget _buildFollowerContent(BuildContext context) {
    return Obx(() {
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
                  child: controller.avatarUrl.value != ""
                      ? CachedNetworkImage(
                          imageUrl: controller.avatarUrl.value,
                          fit: BoxFit.cover,
                          memCacheHeight: 400,
                        )
                      : Center(
                          child: CupertinoActivityIndicator(color: Colors.grey),
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
                      GestureDetector(
                        onTap: _openProfile,
                        child: Text(
                          controller.nickname.value,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      RozetContent(size: 15, userID: widget.userID),
                    ],
                  ),
                  GestureDetector(
                    onTap: _openProfile,
                    child: Text(
                      controller.fullname.value,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (controller.isLoaded.value && widget.userID != _currentUid)
              Column(
                children: [
                  _buildFollowAction(),
                ],
              )
          ],
        ),
      );
    });
  }
}
