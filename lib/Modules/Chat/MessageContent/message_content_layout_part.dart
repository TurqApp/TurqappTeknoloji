part of 'message_content.dart';

extension MessageContentLayoutPart on MessageContent {
  Widget messageBubble() {
    final isMine = model.userID == _currentUserId;
    final bubbleColor = isMine ? const Color(0xFFE7FFDB) : Colors.white;
    final hasReactions =
        model.reactions.entries.where((e) => e.value.isNotEmpty).isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: hasReactions ? 14 : 0),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              onTapDown: _captureTapDown,
              onDoubleTap: () {
                controller.likeImage();
              },
              onLongPressStart: _openMenuFromLongPressStart,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: Get.width * 0.78,
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMine ? 18 : 4),
                        topRight: Radius.circular(isMine ? 4 : 18),
                        bottomLeft: const Radius.circular(18),
                        bottomRight: const Radius.circular(18),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        )
                      ],
                    ),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (model.replyMessageId.trim().isNotEmpty ||
                              model.replyText.trim().isNotEmpty)
                            _buildReplyCard(),
                          if (model.isForwarded)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons
                                        .arrowshape_turn_up_right_fill,
                                    size: 11,
                                    color: Colors.black45,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'chat.forwarded_title'.tr,
                                    style: TextStyle(
                                      color: Colors.black45,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: "Montserrat",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(child: _buildMessageText()),
                              const SizedBox(width: 6),
                              _buildMessageMetaRow(isMine),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (model.begeniler.contains(_currentUserId))
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.hand_thumbsup_fill,
                          color: Colors.blueAccent,
                          size: 13,
                        ),
                      ),
                    ),
                  if (model.reactions.entries
                      .where((e) => e.value.isNotEmpty)
                      .isNotEmpty)
                    Positioned(
                      bottom: -14,
                      right: 4,
                      child: _reactionBadges(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget imageList() {
    final mediaSize = _mediaBubbleSize();
    return Row(
      mainAxisAlignment: model.userID == _currentUserId
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Obx(() {
          return Column(
            crossAxisAlignment: model.userID == _currentUserId
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (controller.showAllImages.value == false)
                Padding(
                  padding: EdgeInsets.only(right: 0),
                  child: Stack(
                    children: [
                      if (model.imgs.length > 1)
                        Transform.translate(
                          offset: Offset(10, -0),
                          child: Transform.rotate(
                            angle: 3 * 3.1415926535 / 180,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: PinchZoom(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: mediaSize,
                                    height: mediaSize,
                                    child: CachedNetworkImage(
                                      imageUrl: model.imgs[1],
                                      cacheManager:
                                          TurqImageCacheManager.instance,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (model.imgs.length > 2)
                        Transform.translate(
                          offset: Offset(-10, 0),
                          child: Transform.rotate(
                            angle: -3 * 3.1415926535 / 180,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: PinchZoom(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: mediaSize,
                                    height: mediaSize,
                                    child: CachedNetworkImage(
                                      imageUrl: model.imgs[2],
                                      cacheManager:
                                          TurqImageCacheManager.instance,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openImagePreview(0),
                        onTapDown: _captureTapDown,
                        onLongPressStart: _openMenuFromLongPressStart,
                        onDoubleTap: () {
                          controller.likeImage();
                        },
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: PinchZoom(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: mediaSize,
                                    height: mediaSize,
                                    child: CachedNetworkImage(
                                      imageUrl: model.imgs[0],
                                      cacheManager:
                                          TurqImageCacheManager.instance,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (model.begeniler.contains(_currentUserId))
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.hand_thumbsup_fill,
                                    color: Colors.blueAccent,
                                    size: 13,
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: _mediaTimeOverlay(),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              else
                Column(
                  children: List.generate(model.imgs.length, (index) {
                    final img = model.imgs[index];
                    final isLast = index == model.imgs.length - 1;
                    return Column(
                      crossAxisAlignment: model.userID == _currentUserId
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openImagePreview(index),
                          onTapDown: _captureTapDown,
                          onLongPressStart: _openMenuFromLongPressStart,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 15),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: PinchZoom(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: mediaSize,
                                    height: mediaSize,
                                    child: CachedNetworkImage(
                                      imageUrl: img,
                                      cacheManager:
                                          TurqImageCacheManager.instance,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isLast)
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: TextButton(
                              onPressed: () {
                                controller.showAllImages.value = false;
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 5,
                                ),
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'chat.hide_photos'.tr,
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                            ),
                          )
                      ],
                    );
                  }),
                )
            ],
          );
        })
      ],
    );
  }
}
