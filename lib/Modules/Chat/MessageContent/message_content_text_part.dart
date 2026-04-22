part of 'message_content.dart';

extension MessageContentTextPart on MessageContent {
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
                          Future<void>.delayed(
                            Duration.zero,
                            controller.deleteMessage,
                          );
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
