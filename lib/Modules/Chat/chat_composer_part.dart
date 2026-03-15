part of 'chat.dart';

extension ChatComposerPart on ChatView {
  Widget buildInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              if (!controller.isSelectionMode.value) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: controller.selectedMessageIds.isEmpty
                          ? null
                          : controller.deleteSelectedMessages,
                      icon:
                          const Icon(CupertinoIcons.trash, color: Colors.black),
                    ),
                    const Spacer(),
                    Text(
                      "${controller.selectedMessageIds.length} Mesaj Seçildi",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              );
            }),
            Obx(() {
              if (!controller.isRecording.value) {
                return const SizedBox.shrink();
              }
              return _buildRecordingRow();
            }),
            Obx(() {
              if (controller.isSelectionMode.value ||
                  controller.isRecording.value) {
                return const SizedBox.shrink();
              }
              final editing = controller.editingMessage.value;
              final replying = controller.replyingTo.value;
              final selectedGifUrl = controller.selectedGifUrl.value.trim();
              if (editing == null &&
                  replying == null &&
                  selectedGifUrl.isEmpty) {
                return const SizedBox.shrink();
              }
              late final bool previewIsVideo;
              late final bool previewIsImage;
              late final bool previewIsAudio;
              late final bool previewIsLocation;
              late final bool previewIsPost;
              late final bool previewIsContact;
              late final bool previewIsGif;
              late final String previewThumb;
              late final String previewLabel;
              late final String previewText;

              if (selectedGifUrl.isNotEmpty &&
                  editing == null &&
                  replying == null) {
                previewIsVideo = false;
                previewIsImage = false;
                previewIsAudio = false;
                previewIsLocation = false;
                previewIsPost = false;
                previewIsContact = false;
                previewIsGif = true;
                previewThumb = selectedGifUrl;
                previewLabel = "GIF";
                previewText = "Gönderilmeye hazır";
              } else if (editing != null) {
                previewIsVideo = false;
                previewIsImage = false;
                previewIsAudio = false;
                previewIsLocation = false;
                previewIsPost = false;
                previewIsContact = false;
                previewIsGif = false;
                previewThumb = "";
                previewLabel = "Mesaj düzenleniyor";
                previewText = editing.metin;
              } else {
                final replyModel = replying!;
                previewIsVideo = replyModel.video.isNotEmpty;
                previewIsImage =
                    replyModel.video.isEmpty && replyModel.imgs.isNotEmpty;
                previewIsAudio = replyModel.sesliMesaj.isNotEmpty;
                previewIsLocation = replyModel.lat != 0 || replyModel.long != 0;
                previewIsPost = replyModel.postID.trim().isNotEmpty;
                previewIsContact = replyModel.kisiAdSoyad.trim().isNotEmpty;
                previewIsGif = false;
                previewThumb = previewIsImage
                    ? replyModel.imgs.first
                    : (previewIsVideo ? replyModel.videoThumbnail : "");
                previewLabel = previewIsVideo
                    ? "Video"
                    : previewIsImage
                        ? "Fotoğraf"
                        : previewIsAudio
                            ? "Ses"
                            : previewIsLocation
                                ? "Konum"
                                : previewIsPost
                                    ? "Gönderi"
                                    : previewIsContact
                                        ? "Kişi"
                                        : "Yanıt";
                previewText = replyModel.metin.trim().isNotEmpty
                    ? replyModel.metin
                    : previewLabel;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (previewThumb.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CachedNetworkImage(
                              imageUrl: previewThumb,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    else if (previewIsGif)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.gif_box_outlined,
                          color: Colors.black54,
                          size: 16,
                        ),
                      )
                    else if (previewIsVideo)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Colors.black54,
                          size: 16,
                        ),
                      )
                    else if (previewIsAudio)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.mic_fill,
                          color: Colors.black54,
                          size: 16,
                        ),
                      )
                    else if (previewIsLocation)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.location_fill,
                          color: Colors.black54,
                          size: 16,
                        ),
                      )
                    else if (previewIsPost)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.doc_fill,
                          color: Colors.black54,
                          size: 16,
                        ),
                      )
                    else if (previewIsContact)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.person_crop_circle_fill,
                          color: Colors.black54,
                          size: 16,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            previewLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                              fontFamily: "MontserratSemiBold",
                            ),
                          ),
                          Text(
                            previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.clearComposerAction,
                      child: const Icon(CupertinoIcons.xmark, size: 16),
                    ),
                  ],
                ),
              );
            }),
            Obx(
              () => Offstage(
                offstage: controller.isSelectionMode.value ||
                    controller.isRecording.value,
                child: _ChatTextField(
                  key: const ValueKey('chat_text_field'),
                  focusNode: controller.focus,
                  textController: controller.textEditingController,
                  controller: controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: controller.cancelVoiceRecording,
          child: Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(50),
            ),
            child:
                const Icon(CupertinoIcons.xmark, color: Colors.black, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Obx(() {
            final secs = controller.recordingDuration.value;
            final m = (secs ~/ 60).toString().padLeft(1, '0');
            final s = (secs % 60).toString().padLeft(2, '0');
            return Text(
              "Kayıt yapılıyor... $m:$s",
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontFamily: "MontserratMedium",
              ),
            );
          }),
        ),
        GestureDetector(
          onTap: controller.stopVoiceRecording,
          child: Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}
