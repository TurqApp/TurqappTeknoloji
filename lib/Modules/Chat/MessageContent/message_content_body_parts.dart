part of 'message_content.dart';

extension MessageContentBodyParts on MessageContent {
  Widget locationBar() {
    final mediaSize = _mediaBubbleSize();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            model.userID == _currentUserId
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.showMapsSheet,
            onTapDown: _captureTapDown,
            onLongPressStart: _openMenuFromLongPressStart,
            onDoubleTap: () {
              controller.likeImage();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  child: SizedBox(
                    width: mediaSize,
                    height: mediaSize,
                    child: AbsorbPointer(
                      // Etkileşimi tamamen engeller
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                              model.lat.toDouble(), model.long.toDouble()),
                          zoom: 14,
                        ),
                        zoomControlsEnabled:
                            false, // Sağ alt zoom butonlarını kaldırır
                        myLocationButtonEnabled:
                            false, // Sağ alt konum butonunu kaldırır
                        scrollGesturesEnabled: false, // Sürükleme kapalı
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        mapToolbarEnabled:
                            false, // Sağ üstteki rota ve benzeri araçları kaldırır
                      ),
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.location_solid,
                  color: Colors.red,
                  size: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget contactInfoBar() {
    return Row(
      mainAxisAlignment: model.userID == _currentUserId
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.addContact,
          onTapDown: _captureTapDown,
          onLongPressStart: _openMenuFromLongPressStart,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Colors.blueAccent)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        shape: BoxShape.circle),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.kisiAdSoyad,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "Montserrat",
                        ),
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      TextButton(
                        onPressed: () {
                          controller.addContact();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // İç boşluk yok
                          minimumSize: Size(0, 0), // Minimum boyut 0
                          tapTargetSize: MaterialTapTargetSize
                              .shrinkWrap, // Tıklama alanını küçült
                        ),
                        child: Text(
                          "Rehbere Ekle",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                            fontFamily: "Montserrat",
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget videoBubble() {
    final mediaSize = _mediaBubbleSize();
    return Row(
      mainAxisAlignment: model.userID == _currentUserId
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openVideoPreview,
          onTapDown: _captureTapDown,
          onLongPressStart: _openMenuFromLongPressStart,
          child: Container(
            width: mediaSize,
            height: mediaSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (model.videoThumbnail.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: model.videoThumbnail,
                      cacheManager: TurqImageCacheManager.instance,
                      fit: BoxFit.cover,
                      width: mediaSize,
                      height: mediaSize,
                    )
                  else
                    Container(color: Colors.grey[800]),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: const Icon(
                      CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _mediaTimeOverlay(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget audioBubble() {
    return Row(
      mainAxisAlignment: model.userID == _currentUserId
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _captureTapDown,
          onLongPressStart: _openMenuFromLongPressStart,
          child: _AudioPlayerWidget(
            audioUrl: model.sesliMesaj,
            durationMs: model.audioDurationMs,
            isMine: model.userID == _currentUserId,
          ),
        ),
      ],
    );
  }

  Widget timeBar() {
    if (model.video.isNotEmpty ||
        model.imgs.isNotEmpty ||
        model.postID.isNotEmpty ||
        model.metin.isNotEmpty ||
        model.isUnsent) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (model.reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _reactionBadges(),
          ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(
            mainAxisAlignment:
                model.userID == _currentUserId
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.end,
            children: [
              Text(
                _formatHourMinute(model.timeStamp),
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 10,
                  fontFamily: "Montserrat",
                ),
              ),
              if (model.userID == _currentUserId) ...[
                const SizedBox(width: 3),
                _buildStatusTicks(
                  readColor: const Color(0xFF53BDEB),
                  defaultColor: Colors.black54,
                  size: 12,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatHourMinute(num ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _mediaTimeOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (model.userID == _currentUserId) ...[
            _buildStatusTicks(),
            const SizedBox(width: 4),
          ],
          Text(
            _formatHourMinute(model.timeStamp),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: "Montserrat",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTicks({
    Color? readColor,
    Color? defaultColor,
    double size = 10,
  }) {
    final status = model.status;
    final bool isRead = status == "read" || (status.isEmpty && model.isRead);
    final Color tickColor =
        isRead ? const Color(0xFF53BDEB) : (defaultColor ?? Colors.black38);

    return Icon(
      CupertinoIcons.checkmark,
      color: tickColor,
      size: size,
    );
  }

  Widget _reactionBadges() {
    final entries = model.reactions.entries
        .where((e) => e.value.isNotEmpty)
        .take(5)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: entries
          .map(
            (e) => Container(
              margin: const EdgeInsets.only(right: 5),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                "${e.key} ${e.value.length}",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontFamily: "Montserrat",
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _openMentionProfile(String mention) async {
    final nick = normalizeHandleInput(mention);
    if (nick.isEmpty) return;
    final uid = await UsernameLookupRepository.ensure().findUidForHandle(nick);
    if (uid == null || uid.isEmpty) return;
    Get.to(() => SocialProfile(userID: uid));
  }

  List<InlineSpan> _buildInteractiveSpans(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final tokenRegex = RegExp(
      r'((?:https?:\/\/|www\.)\S+|#[\wğüşöçıİĞÜŞÖÇ]+|@[\w.]+)',
      unicode: true,
      caseSensitive: false,
    );

    var cursor = 0;
    for (final m in tokenRegex.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, m.start), style: baseStyle),
        );
      }

      final token = m.group(0)!;
      if (token.startsWith('#')) {
        final clean = token.replaceFirst('#', '');
        spans.add(
          TextSpan(
            text: token,
            style: baseStyle.copyWith(color: Colors.blueAccent),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (clean.isNotEmpty) {
                  Get.to(() => TagPosts(tag: clean));
                }
              },
          ),
        );
      } else if (token.startsWith('@')) {
        spans.add(
          TextSpan(
            text: token,
            style: baseStyle.copyWith(color: Colors.blueAccent),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _openMentionProfile(token);
              },
          ),
        );
      } else {
        var normalized = token.startsWith('http') ? token : 'https://$token';
        normalized = normalized
            .replaceAll(RegExp("^[\\s<>'\"()]+"), '')
            .replaceAll(RegExp("[\\s<>'\"),.!?:;]+\$"), '');
        spans.add(
          TextSpan(
            text: token,
            style: baseStyle.copyWith(
              color: Colors.blueAccent,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                RedirectionLink().goToLink(normalized);
              },
          ),
        );
      }
      cursor = m.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }
    return spans;
  }

  Widget _buildMessageText() {
    final baseStyle = TextStyle(
      color: model.isUnsent ? Colors.black38 : Colors.black,
      fontSize: 13,
      fontStyle: model.isUnsent ? FontStyle.italic : FontStyle.normal,
      fontFamily: "Montserrat",
      height: 1.5,
      decoration:
          model.lat != 0 ? TextDecoration.underline : TextDecoration.none,
      decorationColor: Colors.white,
      decorationThickness: 1.5,
    );

    if (model.isUnsent) {
      return Text('chat.unsent_message'.tr, style: baseStyle);
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: _buildInteractiveSpans(model.metin, baseStyle),
      ),
    );
  }

  void _openReactionPicker() {
    const emojis = ["👍", "❤️", "😂", "😮", "😢", "😡"];
    Get.bottomSheet(
      SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: emojis
                .map(
                  (emoji) => GestureDetector(
                    onTap: () async {
                      Get.back();
                      await chatController.toggleReaction(model, emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _openQuickReactionMenuAt(Offset globalPosition) async {
    const quickEmojis = ["👍", "❤️", "😂", "😮", "😢", "🙏", "👏"];
    final popupContext =
        Get.overlayContext ?? Get.key.currentContext ?? Get.context;
    if (popupContext == null) return;
    final screenSize = MediaQuery.of(popupContext).size;

    const emojiWidth = 234.0;
    const emojiHeight = 46.0;
    const menuWidth = 214.0;
    const menuHeight = 334.0;

    final double left = (globalPosition.dx - 16)
        .clamp(12.0, screenSize.width - emojiWidth - 12);
    final double menuLeft =
        (globalPosition.dx - 16).clamp(12.0, screenSize.width - menuWidth - 12);

    double top = globalPosition.dy - emojiHeight - 8;
    double bottom = top + emojiHeight + 8 + menuHeight;
    if (bottom > screenSize.height - 16) {
      top -= (bottom - (screenSize.height - 16));
    }
    if (top < 20) {
      top = 20;
    }
    debugPrint(
      "chat_menu_pos tap=(${globalPosition.dx.toStringAsFixed(1)},${globalPosition.dy.toStringAsFixed(1)}) "
      "emojiLeft=${left.toStringAsFixed(1)} menuLeft=${menuLeft.toStringAsFixed(1)} top=${top.toStringAsFixed(1)}",
    );

    await showGeneralDialog(
      context: popupContext,
      barrierDismissible: true,
      barrierLabel: "close",
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 110),
      pageBuilder: (context, _, __) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: Container(
                  width: emojiWidth,
                  height: emojiHeight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ...quickEmojis.map(
                          (emoji) => GestureDetector(
                            onTap: () async {
                              Navigator.of(context).pop();
                              await chatController.toggleReaction(model, emoji);
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            _openReactionPicker();
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              CupertinoIcons.plus,
                              color: Colors.black54,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: menuLeft,
                top: top + emojiHeight + 8,
                child: Container(
                  width: menuWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _menuAction(
                        icon: CupertinoIcons.arrowshape_turn_up_left,
                        title: 'chat.reply'.tr,
                        onTap: () {
                          Navigator.of(context).pop();
                          chatController.startReply(model);
                        },
                      ),
                      _menuAction(
                        icon: CupertinoIcons.doc_on_doc,
                        title: 'common.copy'.tr,
                        onTap: () {
                          final text = model.metin.trim();
                          final copyValue = text.isNotEmpty
                              ? text
                              : (model.video.isNotEmpty
                                  ? model.video
                                  : (model.imgs.isNotEmpty
                                      ? model.imgs.first
                                      : ""));
                          if (copyValue.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: copyValue));
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      _menuAction(
                        icon: model.isStarred
                            ? CupertinoIcons.star_fill
                            : CupertinoIcons.star,
                        title: model.isStarred
                            ? 'chat.remove_star'.tr
                            : 'chat.add_star'.tr,
                        onTap: () {
                          Navigator.of(context).pop();
                          chatController.toggleStarMessage(model);
                        },
                      ),
                      _menuAction(
                        icon: CupertinoIcons.trash,
                        title: 'common.delete'.tr,
                        isDestructive: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          controller.deleteMessage();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Colors.black87;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontFamily: "Montserrat",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
