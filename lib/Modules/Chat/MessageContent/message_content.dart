import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';
import 'package:turqappv2/Modules/Chat/MessageContent/message_content_controller.dart';
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
  final ExploreController? explore = Get.isRegistered<ExploreController>()
      ? Get.find<ExploreController>()
      : null;
  final ValueNotifier<Offset?> _lastLongPressGlobal =
      ValueNotifier<Offset?>(null);

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
    controller = Get.put(MessageContentController(model: model, mainID: mainID),
        tag: model.docID);
    chatController = Get.find<ChatController>(tag: mainID);
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
      child: Column(
        mainAxisAlignment:
            model.userID == FirebaseAuth.instance.currentUser!.uid
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

  Widget messageBubble() {
    final isMine = model.userID == FirebaseAuth.instance.currentUser!.uid;
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
                                      color: Colors.black45),
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
                  // Beğeni ikonu - sağ üst
                  if (model.begeniler
                      .contains(FirebaseAuth.instance.currentUser!.uid))
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
                  // Reaksiyonlar - alt
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
      mainAxisAlignment: model.userID == FirebaseAuth.instance.currentUser!.uid
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Obx(() {
          return Column(
            crossAxisAlignment:
                model.userID == FirebaseAuth.instance.currentUser!.uid
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
                            angle: 3 *
                                3.1415926535 /
                                180, // 10 derece radiana çevrildi
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
                            angle: -3 *
                                3.1415926535 /
                                180, // 10 derece radiana çevrildi
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
                            if (model.begeniler.contains(
                                FirebaseAuth.instance.currentUser!.uid))
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
                      crossAxisAlignment:
                          model.userID == FirebaseAuth.instance.currentUser!.uid
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
                                    horizontal: 15, vertical: 5),
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

class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool enableReplyBar;
  final Future<void> Function(String text, String mediaUrl)? onSendReply;
  final String replyPreviewLabel;

  const _FullScreenVideoPlayer({
    required this.videoUrl,
    this.enableReplyBar = false,
    this.onSendReply,
    this.replyPreviewLabel = "",
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  bool _replyOpen = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final onSend = widget.onSendReply;
    if (onSend == null || _sending) return;
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await onSend(text, widget.videoUrl);
      _replyController.clear();
      _replyFocus.unfocus();
      if (mounted) {
        setState(() => _replyOpen = false);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Widget _buildCollapsedReplyButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _replyOpen = true);
        Future.delayed(
          const Duration(milliseconds: 70),
          () => _replyFocus.requestFocus(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.reply_thick_solid,
              color: Colors.black,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'chat.reply_prompt'.tr,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: "Montserrat",
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Center(
            child: _initialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller),
                          if (!_controller.value.isPlaying)
                            const Icon(
                              CupertinoIcons.play_fill,
                              color: Colors.white,
                              size: 50,
                            ),
                        ],
                      ),
                    ),
                  )
                : const CupertinoActivityIndicator(color: Colors.white),
          ),
          if (widget.enableReplyBar)
            if (_replyOpen)
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF18A999),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'chat.you'.tr,
                              style: const TextStyle(
                                color: Color(0xFF18A999),
                                fontSize: 14,
                                fontFamily: "Montserrat",
                              ),
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              CupertinoIcons.videocam_fill,
                              color: Colors.black54,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 11, top: 2),
                        child: Row(
                          children: [
                            Text(
                              widget.replyPreviewLabel.isEmpty
                                  ? 'chat.video'.tr
                                  : widget.replyPreviewLabel,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontFamily: "Montserrat",
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              focusNode: _replyFocus,
                              controller: _replyController,
                              textCapitalization: TextCapitalization.sentences,
                              minLines: 1,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'chat.message_hint'.tr,
                                isDense: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_sending)
                            const CupertinoActivityIndicator(
                              color: Colors.black,
                            )
                          else
                            IconButton(
                              onPressed: _sendReply,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 34, minHeight: 34),
                              icon: const Icon(
                                CupertinoIcons.paperplane_fill,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                right: 12,
                bottom: 18,
                child: _buildCollapsedReplyButton(),
              ),
        ],
      ),
    );
  }
}

class _AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int durationMs;
  final bool isMine;

  const _AudioPlayerWidget({
    required this.audioUrl,
    required this.durationMs,
    required this.isMine,
  });

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    AudioFocusCoordinator.instance.registerAudioPlayer(_player);
    if (widget.durationMs > 0) {
      _duration = Duration(milliseconds: widget.durationMs);
    }
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
  }

  @override
  void dispose() {
    AudioFocusCoordinator.instance.unregisterAudioPlayer(_player);
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final bubbleWidth =
        (MediaQuery.of(context).size.width * 0.58).clamp(180.0, 220.0);
    return Container(
      width: bubbleWidth,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMine ? Colors.blueAccent : const Color(0xFFF2F2F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (_isPlaying) {
                await _player.pause();
              } else {
                await AudioFocusCoordinator.instance.requestAudioPlayerPlay(
                  _player,
                );
                await _player.play(UrlSource(widget.audioUrl));
              }
            },
            child: Icon(
              _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
              color: widget.isMine ? Colors.white : Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration.inMilliseconds
                      : 0,
                  backgroundColor: widget.isMine
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(
                    widget.isMine ? Colors.white : Colors.blueAccent,
                  ),
                  minHeight: 3,
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying || _position.inMilliseconds > 0
                      ? _formatDuration(_position)
                      : _formatDuration(_duration),
                  style: TextStyle(
                    color: widget.isMine ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                    fontFamily: "Montserrat",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
