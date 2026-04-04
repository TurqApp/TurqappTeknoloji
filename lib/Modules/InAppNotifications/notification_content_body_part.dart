part of 'notification_content.dart';

extension NotificationContentBodyPart on _NotificationContentState {
  Widget _buildNotificationCard(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          Container(
            key: ValueKey(IntegrationTestKeys.notificationItem(model.docID)),
            margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: model.isRead ? Colors.white : const Color(0xFFF4F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A000000)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 8),
                Expanded(child: _buildBody()),
                if (_hasMediaPreview) ...[
                  const SizedBox(width: 8),
                  _buildMediaPreview(),
                ],
                if (model.postType == kNotificationPostTypeUser)
                  _buildFollowButton(),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _handleAvatarTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withAlpha(50)),
            ),
            child: CachedUserAvatar(
              userId: controller.userID,
              imageUrl: controller.avatarUrl.value,
              radius: 20,
            ),
          ),
          if (!model.isRead)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return GestureDetector(
      key: ValueKey(IntegrationTestKeys.notificationItemOpen(model.docID)),
      onTap: _handleNotificationTap,
      child: Container(
        color: Colors.white.withAlpha(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 3,
              runSpacing: 1,
              children: [
                Text(
                  controller.nickname.value,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily:
                        model.isRead ? "MontserratSemiBold" : "MontserratBold",
                  ),
                ),
                RozetContent(size: 14, userID: controller.userID),
                Text(
                  _buildPrimaryText(),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: model.isRead
                        ? "MontserratMedium"
                        : "MontserratSemiBold",
                    height: 1.15,
                  ),
                ),
                Text(
                  "· ${timeAgoMetin(model.timeStamp)}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontFamily: "Montserrat",
                  ),
                ),
              ],
            ),
            if (model.title.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  model.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontFamily: "Montserrat",
                  ),
                ),
              ),
            if (controller.targetHint.value.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.arrow_turn_down_right,
                      size: 12,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        controller.targetHint.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                          fontFamily: "MontserratMedium",
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

  bool get _hasMediaPreview =>
      _mediaPreviewUrls.isNotEmpty;

  Widget _buildMediaPreview() {
    final previewUrls = _mediaPreviewUrls;
    if (previewUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _handleNotificationTap,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: SizedBox(
          width: 44,
          height: 56,
          child: CacheFirstNetworkImage(
            imageUrl: previewUrls.first,
            candidateUrls: previewUrls.skip(1).toList(growable: false),
            cacheManager: TurqImageCacheManager.instance,
            fit: BoxFit.cover,
            fallback: const ColoredBox(color: Color(0xFFF5F6F8)),
            memCacheWidth: 88,
            memCacheHeight: 112,
            key: ValueKey(previewUrls.join('|')),
          ),
        ),
      ),
    );
  }
}
