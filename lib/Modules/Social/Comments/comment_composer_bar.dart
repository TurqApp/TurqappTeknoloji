import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Themes/app_fonts.dart';

class CommentComposerBar extends StatelessWidget {
  const CommentComposerBar({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.avatarUrl,
    required this.replyingToNickname,
    required this.selectedGifUrl,
    required this.onTextChanged,
    required this.onClearReply,
    required this.onPickGif,
    required this.onClearGif,
    required this.onSend,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final String avatarUrl;
  final String replyingToNickname;
  final String selectedGifUrl;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onClearReply;
  final VoidCallback onPickGif;
  final VoidCallback onClearGif;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CachedUserAvatar(
                imageUrl: avatarUrl,
                radius: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (replyingToNickname.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'comments.replying_to'.trParams({
                              'nickname': replyingToNickname,
                            }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontFamily: 'MontserratMedium',
                              fontSize: 11,
                            ),
                          ),
                        ),
                        GestureDetector(
                          key: const ValueKey(
                            IntegrationTestKeys.actionCommentClearReply,
                          ),
                          onTap: onClearReply,
                          child: Semantics(
                            button: true,
                            label: 'Clear comment reply target',
                            child: const Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 14,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (selectedGifUrl.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: selectedGifUrl.trim(),
                            cacheManager: TurqImageCacheManager.instance,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            placeholderFadeInDuration: Duration.zero,
                            placeholder: (context, _) => Container(
                              width: 76,
                              height: 76,
                              color: const Color(0xFFF5F6F8),
                              child: const Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 76,
                              height: 76,
                              color: const Color(0xFFF5F6F8),
                              child: const Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: onClearGif,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 62),
                    child: TextField(
                      key: const ValueKey(IntegrationTestKeys.inputComment),
                      controller: textController,
                      focusNode: focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(280),
                      ],
                      decoration: InputDecoration(
                        hintText: 'comments.input_hint'.tr,
                        hintStyle: const TextStyle(
                          color: Colors.black45,
                          fontFamily: 'MontserratMedium',
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: 'MontserratMedium',
                        height: 1.35,
                      ),
                      onChanged: onTextChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            key: const ValueKey(IntegrationTestKeys.actionCommentGifPicker),
            onTap: onPickGif,
            child: Semantics(
              button: true,
              label: 'Open comment GIF picker',
              child: Container(
                width: 34,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'chat.gif'.tr,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                    fontFamily: AppFontFamilies.mbold,
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: textController,
            builder: (context, value, _) {
              final showSendButton =
                  value.text.trim().isNotEmpty ||
                  selectedGifUrl.trim().isNotEmpty;
              if (!showSendButton) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  key: const ValueKey(IntegrationTestKeys.actionCommentSend),
                  onTap: onSend,
                  child: Semantics(
                    button: true,
                    label: 'Send comment',
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
