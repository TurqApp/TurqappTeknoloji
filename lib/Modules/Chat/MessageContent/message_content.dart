import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';
import 'package:turqappv2/Modules/Chat/MessageContent/message_content_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/Core/Repositories/username_lookup_repository.dart';
import '../../../Core/Helpers/ImagePreview/image_preview.dart';
import '../../Agenda/TagPosts/tag_posts.dart';
import '../../Explore/explore_controller.dart';
import '../../SocialProfile/social_profile.dart';

part 'message_content_reply_parts.dart';
part 'message_content_body_parts.dart';
part 'message_content_post_parts.dart';
part 'message_content_layout_part.dart';
part 'message_content_media_part.dart';
part 'message_content_text_part.dart';

class MessageContent extends StatelessWidget {
  final String mainID;
  final MessageModel model;
  final bool isLastMessage;
  final String? dateSeparatorText;
  MessageContent(
      {super.key,
      required this.mainID,
      required this.model,
      required this.isLastMessage,
      this.dateSeparatorText});
  late final MessageContentController controller;
  late final ChatController chatController;
  final ExploreController? explore = ExploreController.maybeFind();
  final ValueNotifier<Offset?> _lastLongPressGlobal =
      ValueNotifier<Offset?>(null);
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  double _mediaBubbleSize() {
    return (Get.width * 0.58).clamp(180.0, 220.0).toDouble();
  }

  double _sharedPostCardWidth() {
    return (Get.width * 0.40).clamp(132.0, 148.0).toDouble();
  }

  double _sharedPostCardMediaHeight() {
    return (_sharedPostCardWidth() * 1.405).clamp(184.0, 208.0).toDouble();
  }

  void _captureTapDown(TapDownDetails details) {
    _lastLongPressGlobal.value = details.globalPosition;
  }

  Future<void> _openMenuFromLongPressStart(
      LongPressStartDetails details) async {
    _lastLongPressGlobal.value = details.globalPosition;
    await _openMessageLongPressMenu();
  }

  Future<void> _openImagePreview(int index) async {
    if (model.imgs.isEmpty) return;
    Get.to(
      () => ImagePreview(
        imgs: model.imgs,
        startIndex: index.clamp(0, model.imgs.length - 1),
        enableReplyBar: true,
        onSendReply: (text, mediaUrl) async {
          await chatController.sendExternalReplyText(
            text,
            replyText: 'chat.photo'.tr,
            replyType: "media",
            replyTarget: mediaUrl,
          );
        },
        replyPreviewLabel: 'chat.photo'.tr,
      ),
    );
  }

  Future<void> _openVideoPreview() async {
    if (model.video.isEmpty) return;
    Get.to(
      () => _FullScreenVideoPlayer(
        videoUrl: model.video,
        enableReplyBar: true,
        onSendReply: (text, mediaUrl) async {
          await chatController.sendExternalReplyText(
            text,
            replyText: 'chat.video'.tr,
            replyType: "video",
            replyTarget: mediaUrl,
          );
        },
        replyPreviewLabel: 'chat.video'.tr,
      ),
    );
  }

  Future<void> _openMessageLongPressMenu() async {
    final fallback = Offset(Get.width - 40, Get.height * 0.35);
    final pos = _lastLongPressGlobal.value ?? fallback;
    debugPrint("message_long_press -> ${pos.dx}, ${pos.dy}");
    await _openQuickReactionMenuAt(pos);
  }

  @override
  Widget build(BuildContext context) {
    controller = ensureMessageContentController(
      model: model,
      mainID: mainID,
      tag: model.docID,
    );
    chatController = ensureChatController(
      chatID: mainID,
      userID: model.userID,
      tag: mainID,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
      child: Column(
        mainAxisAlignment: model.userID == _currentUserId
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (dateSeparatorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    dateSeparatorText!,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontFamily: "Montserrat",
                    ),
                  ),
                ),
              ),
            ),
          if (model.lat != 0) locationBar(),
          if (model.video.isNotEmpty) videoBubble(),
          if (model.imgs.isNotEmpty && model.video.isEmpty) imageList(),
          if (model.sesliMesaj.isNotEmpty) audioBubble(),
          if (model.metin != "" || model.isUnsent) messageBubble(),
          if (model.kisiAdSoyad != "") contactInfoBar(),
          Obx(() {
            return postBody();
          }),
          timeBar(),
        ],
      ),
    );
  }
}
