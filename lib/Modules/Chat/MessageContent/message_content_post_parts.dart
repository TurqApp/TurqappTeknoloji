part of 'message_content.dart';

extension MessageContentPostParts on MessageContent {
  Widget postBody() {
    final post = controller.postModel.value;
    if (post == null) {
      return const SizedBox.shrink();
    }
    final isMine = model.userID == FirebaseAuth.instance.currentUser!.uid;
    final hasImage = post.img.isNotEmpty;
    final hasVideo = post.hasPlayableVideo || post.thumbnail.isNotEmpty;
    final previewUrl = hasImage
        ? post.img.first
        : (post.thumbnail.isNotEmpty ? post.thumbnail : "");
    final hasMedia = previewUrl.isNotEmpty || hasVideo;
    final senderNick = controller.nickname.value;
    final cardWidth = _sharedPostCardWidth();
    final mediaHeight = _sharedPostCardMediaHeight();

    return Row(
      mainAxisAlignment:
          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          onTapDown: _captureTapDown,
          onLongPressStart: _openMenuFromLongPressStart,
          child: Container(
            width: cardWidth,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5E5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasMedia)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    child: SizedBox(
                      height: mediaHeight,
                      width: cardWidth,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: previewUrl,
                            cacheManager: TurqImageCacheManager.instance,
                            fit: BoxFit.cover,
                          ),
                          if (hasVideo)
                            Center(
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.45),
                                ),
                                child: const Icon(
                                  CupertinoIcons.play_fill,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 90,
                    width: cardWidth,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      color: Color(0xFFF0F0F0),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      CupertinoIcons.photo,
                      color: Colors.black54,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMine && senderNick.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "@$senderNick'in gönderisini gönderdi",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                              fontFamily: "Montserrat",
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.postNickname.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontFamily: "Montserrat",
                              ),
                            ),
                          ),
                          if (post.userID.isNotEmpty)
                            RozetContent(size: 11, userID: post.userID),
                        ],
                      ),
                      if (post.metin.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            post.metin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontFamily: "Montserrat",
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            _formatHourMinute(model.timeStamp),
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                              fontFamily: "Montserrat",
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 2),
                            _buildStatusTicks(
                              readColor: const Color(0xFF53BDEB),
                              defaultColor: Colors.black54,
                              size: 10,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: outerRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImageContent(images),
    );
  }

  void _openReplyTargetMedia() {
    final target = model.replyMessageId.trim();
    if (target.isEmpty) return;

    if (!target.startsWith("http")) {
      chatController.jumpToMessageByRawId(target);
      return;
    }

    if (model.replyType == "video") {
      Get.to(
        () => _FullScreenVideoPlayer(
          videoUrl: target,
          enableReplyBar: true,
          onSendReply: (text, mediaUrl) async {
            await chatController.sendExternalReplyText(
              text,
              replyText: "Video",
              replyType: "video",
              replyTarget: mediaUrl,
            );
          },
          replyPreviewLabel: "Video",
        ),
      );
      return;
    }

    if (model.replyType == "media") {
      final images = <String>[];
      final seen = <String>{};
      for (final msg in chatController.messages) {
        if (msg.video.isNotEmpty || msg.imgs.isEmpty) continue;
        for (final url in msg.imgs) {
          final clean = url.trim();
          if (clean.isEmpty || seen.contains(clean)) continue;
          seen.add(clean);
          images.add(clean);
        }
      }
      if (images.isEmpty) return;
      var startIndex = images.indexOf(target);
      if (startIndex < 0) {
        images.insert(0, target);
        startIndex = 0;
      }
      Get.to(() => ImagePreview(
            imgs: images,
            startIndex: startIndex,
            enableReplyBar: true,
            onSendReply: (text, mediaUrl) async {
              await chatController.sendExternalReplyText(
                text,
                replyText: "Fotoğraf",
                replyType: "media",
                replyTarget: mediaUrl,
              );
            },
            replyPreviewLabel: "Fotoğraf",
          ));
    }
  }

  Widget _buildImageContent(List<String> images) {
    final pmodel = controller.postModel.value!;
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: pmodel.aspectRatio.toDouble(),
          child: _buildImage(images[0], radius: BorderRadius.circular(12)),
        );

      case 2:
        return AspectRatio(
          aspectRatio: 1,
          child: Row(
            children: [
              Expanded(
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              SizedBox(width: 1), // spacing
              Expanded(
                child: _buildImage(
                  images[1],
                  radius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );

      case 3:
        return AspectRatio(
          aspectRatio: 1,
          child: Row(
            children: [
              Expanded(
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              SizedBox(
                width: 1,
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _buildImage(
                        images[1],
                        radius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 1,
                    ),
                    Expanded(
                      child: _buildImage(
                        images[2],
                        radius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 4:
      default:
        return buildFourImageGrid(pmodel.img);
    }
  }

  Widget buildFourImageGrid(List<String> images) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemBuilder: (context, index) {
        final radius = _getGridRadius(index);
        return _buildImage(images[index], radius: radius);
      },
    );
  }

  Widget _buildImage(String url, {required BorderRadius radius}) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200], // Arka plan sabit
        child: CachedNetworkImage(
          imageUrl: url,
          cacheManager: TurqImageCacheManager.instance,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => const CupertinoActivityIndicator(),
        ),
      ),
    );
  }

  BorderRadius _getGridRadius(int index) {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(12));
      case 1:
        return const BorderRadius.only(topRight: Radius.circular(12));
      case 2:
        return const BorderRadius.only(bottomLeft: Radius.circular(12));
      case 3:
        return const BorderRadius.only(bottomRight: Radius.circular(12));
      default:
        return BorderRadius.zero;
    }
  }
}
