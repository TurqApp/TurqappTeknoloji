import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';
import 'package:turqappv2/Modules/Chat/MessageContent/message_content_controller.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../Core/Helpers/ImagePreview/image_preview.dart';
import '../../Agenda/TagPosts/tag_posts.dart';
import '../../Explore/explore_controller.dart';
import '../../SocialProfile/social_profile.dart';

part 'message_content_reply_parts.dart';

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
            replyText: "Fotoğraf",
            replyType: "media",
            replyTarget: mediaUrl,
          );
        },
        replyPreviewLabel: "Fotoğraf",
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
            replyText: "Video",
            replyType: "video",
            replyTarget: mediaUrl,
          );
        },
        replyPreviewLabel: "Video",
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
    final hasReactions = model.reactions.entries
        .where((e) => e.value.isNotEmpty)
        .isNotEmpty;
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
                                  "İletildi",
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
                                    width: 220,
                                    height: 220,
                                    child: CachedNetworkImage(
                                      imageUrl: model.imgs[1],
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
                                    width: 220,
                                    height: 220,
                                    child: CachedNetworkImage(
                                      imageUrl: model.imgs[2],
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
                                    width: 220,
                                    height: 220,
                                    child: CachedNetworkImage(
                                      imageUrl: model.imgs[0],
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
                                    width: 220,
                                    height: 220,
                                    child: CachedNetworkImage(
                                      imageUrl: img,
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
                                "Fotoğrafları gizle",
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

  Widget locationBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            model.userID == FirebaseAuth.instance.currentUser!.uid
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
                    width: 220,
                    height: 220,
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
      mainAxisAlignment: model.userID == FirebaseAuth.instance.currentUser!.uid
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
    return Row(
      mainAxisAlignment: model.userID == FirebaseAuth.instance.currentUser!.uid
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openVideoPreview,
          onTapDown: _captureTapDown,
          onLongPressStart: _openMenuFromLongPressStart,
          child: Container(
            width: 220,
            height: 220,
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
                      fit: BoxFit.cover,
                      width: 220,
                      height: 220,
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
      mainAxisAlignment: model.userID == FirebaseAuth.instance.currentUser!.uid
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
            isMine: model.userID == FirebaseAuth.instance.currentUser!.uid,
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
                model.userID == FirebaseAuth.instance.currentUser!.uid
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
              if (model.userID == FirebaseAuth.instance.currentUser!.uid) ...[
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
          if (model.userID == FirebaseAuth.instance.currentUser!.uid) ...[
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
    final Color tickColor = isRead
        ? const Color(0xFF53BDEB)
        : (defaultColor ?? Colors.black38);

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
    final nick = mention.trim().replaceFirst('@', '');
    if (nick.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: nick)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      Get.to(() => SocialProfile(userID: snap.docs.first.id));
    }
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
      return Text("Mesaj geri alındı", style: baseStyle);
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
                        title: "Yanıtla",
                        onTap: () {
                          Navigator.of(context).pop();
                          chatController.startReply(model);
                        },
                      ),
                      _menuAction(
                        icon: CupertinoIcons.doc_on_doc,
                        title: "Kopyala",
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
                        title:
                            model.isStarred ? "Yıldızı Kaldır" : "Yıldız Ekle",
                        onTap: () {
                          Navigator.of(context).pop();
                          chatController.toggleStarMessage(model);
                        },
                      ),
                      _menuAction(
                        icon: CupertinoIcons.trash,
                        title: "Sil",
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
            width: 148,
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
                      height: 208,
                      width: 148,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: previewUrl,
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
                    width: 148,
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

class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool enableReplyBar;
  final Future<void> Function(String text, String mediaUrl)? onSendReply;
  final String replyPreviewLabel;

  const _FullScreenVideoPlayer({
    required this.videoUrl,
    this.enableReplyBar = false,
    this.onSendReply,
    this.replyPreviewLabel = "Video",
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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.reply_thick_solid,
              color: Colors.black,
              size: 14,
            ),
            SizedBox(width: 5),
            Text(
              "Yanıtlayın",
              style: TextStyle(
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
                          const Expanded(
                            child: Text(
                              "Siz",
                              style: TextStyle(
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
                              widget.replyPreviewLabel,
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
                              decoration: const InputDecoration(
                                hintText: "Mesaj yaz",
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
    return Container(
      width: 220,
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
