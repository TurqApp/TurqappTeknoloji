part of 'chat.dart';

/// TextField'i tüm Obx/reactive state'ten tamamen izole eden StatefulWidget.
class _ChatTextField extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController textController;
  final ChatController controller;

  const _ChatTextField({
    super.key,
    required this.focusNode,
    required this.textController,
    required this.controller,
  });

  @override
  State<_ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<_ChatTextField> {
  final GlobalKey _plusButtonKey = GlobalKey();

  Future<void> _showAttachmentMenu() async {
    final box = _plusButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final buttonRect = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    final position = Rect.fromCenter(
      center: buttonRect.center.translate(0, -4),
      width: 2,
      height: 2,
    );

    await showPullDownMenu(
      context: context,
      position: position,
      items: [
        PullDownMenuItem(
          key: const ValueKey(IntegrationTestKeys.actionChatAttachPhotos),
          title: 'chat.attach_photos'.tr,
          icon: CupertinoIcons.photo_on_rectangle,
          onTap: widget.controller.pickImage,
        ),
        PullDownMenuItem(
          key: const ValueKey(IntegrationTestKeys.actionChatAttachVideos),
          title: 'chat.attach_videos'.tr,
          icon: AppIcons.playFilled,
          onTap: widget.controller.pickVideo,
        ),
        PullDownMenuItem(
          key: const ValueKey(IntegrationTestKeys.actionChatAttachLocation),
          title: 'chat.attach_location'.tr,
          icon: AppIcons.locationSolid,
          onTap: () {
            Get.to(
              () => LocationShareViewChat(chatID: widget.controller.chatID),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            key: const ValueKey(IntegrationTestKeys.actionChatAttach),
            onTap: _showAttachmentMenu,
            child: Semantics(
              button: true,
              label: 'Open chat attachments',
              child: Container(
                key: _plusButtonKey,
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(bottom: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: Colors.black87,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key:
                          const ValueKey(IntegrationTestKeys.inputChatComposer),
                      focusNode: widget.focusNode,
                      controller: widget.textController,
                      textCapitalization: TextCapitalization.sentences,
                      enableInteractiveSelection: true,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'chat.message_hint'.tr,
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontFamily: "Montserrat",
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => widget.controller.pickGif(context),
            child: Semantics(
              button: true,
              label: 'Open GIF picker',
              child: Container(
                key: const ValueKey(IntegrationTestKeys.actionChatGifPicker),
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(bottom: 2),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.gif_box_outlined,
                  color: Colors.black87,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: widget.controller.openCustomCameraCapture,
            child: Semantics(
              button: true,
              label: 'Open camera capture',
              child: Container(
                key: const ValueKey(IntegrationTestKeys.actionChatCamera),
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(bottom: 2),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.camera,
                  color: Colors.black87,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          _ChatTrailingButton(controller: widget.controller),
        ],
      ),
    );
  }
}

class _ChatTrailingButton extends StatelessWidget {
  final ChatController controller;

  const _ChatTrailingButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isUploading.value) {
        return Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(bottom: 2),
          alignment: Alignment.center,
          child: const CupertinoActivityIndicator(color: Colors.black),
        );
      }

      final hasContent = controller.textMesage.value != "" ||
          controller.images.isNotEmpty ||
          controller.pendingVideo.value != null ||
          controller.selectedGifUrl.value.trim().isNotEmpty ||
          controller.editingMessage.value != null;

      if (hasContent) {
        if (controller.uploadPercent.value != 0 &&
            controller.uploadPercent.value != 100) {
          return Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(bottom: 2),
            alignment: Alignment.center,
            child: const CupertinoActivityIndicator(color: Colors.black),
          );
        }
        return GestureDetector(
          onTap: () {
            if (controller.pendingVideo.value != null) {
              controller.uploadPendingVideoToStorage();
            } else if (controller.images.isNotEmpty ||
                controller.selection.value == 1) {
              controller.uploadImageToStorage();
            } else {
              controller.sendMessage(
                gif: controller.selectedGifUrl.value.trim().isEmpty
                    ? null
                    : controller.selectedGifUrl.value.trim(),
              );
            }
          },
          child: Semantics(
            button: true,
            label: 'Send chat message',
            child: Container(
              key: const ValueKey(IntegrationTestKeys.actionChatSend),
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(bottom: 2),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: controller.startVoiceRecording,
        child: Semantics(
          button: true,
          label: 'Start voice recording',
          child: Container(
            key: const ValueKey(IntegrationTestKeys.actionChatMic),
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(bottom: 2),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.mic,
              color: Colors.black87,
              size: 22,
            ),
          ),
        ),
      );
    });
  }
}

class _PendingVideoPreview extends StatefulWidget {
  final File file;

  const _PendingVideoPreview({required this.file});

  @override
  State<_PendingVideoPreview> createState() => _PendingVideoPreviewState();
}

class _PendingVideoPreviewState extends State<_PendingVideoPreview> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        _controller.play();
        setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return SizedBox(
        height: (MediaQuery.of(context).size.height * 0.26).clamp(160.0, 200.0),
        child: Center(
          child: const CupertinoActivityIndicator(color: Colors.black),
        ),
      );
    }

    final ratio = _controller.value.aspectRatio == 0
        ? (9 / 16)
        : _controller.value.aspectRatio;

    return GestureDetector(
      onTap: () {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
        setState(() {});
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width - 72;
          const maxHeight = 220.0;
          final computedHeight = availableWidth / ratio;
          final targetHeight = math.min(computedHeight, maxHeight);
          final targetWidth = targetHeight * ratio;

          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: targetWidth,
                height: targetHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(child: VideoPlayer(_controller)),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _controller.value.isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
