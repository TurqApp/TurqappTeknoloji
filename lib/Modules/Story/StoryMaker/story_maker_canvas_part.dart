part of 'story_maker.dart';

extension _StoryMakerCanvasPart on _StoryMakerState {
  Widget mediaLookTools() {
    return Obx(() {
      final media = controller.currentBackgroundMediaElement;
      if (media == null) return const SizedBox.shrink();
      final presets = storyMakerSupportedMediaLookPresets;
      return Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            ...presets.asMap().entries.map((entry) {
              final index = entry.key;
              final preset = entry.value;
              final isSelected = media.mediaLookPreset == preset;
              final labelKey = _mediaLookLabels[preset];
              final label = labelKey != null ? labelKey.tr : preset;
              final icon = _mediaLookIcons[preset] ?? CupertinoIcons.circle;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == presets.length - 1 ? 0 : 8,
                  ),
                  child: GestureDetector(
                    onTap: () => controller.setCurrentMediaLookPreset(preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white10,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 12,
                                fontFamily: isSelected
                                    ? "MontserratBold"
                                    : "MontserratMedium",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget playground() {
    return Obx(() {
      final sorted = [...controller.elements];
      sorted.sort((a, b) => a.zIndex.compareTo(b.zIndex));
      final mediaLayer = sorted.where(_isBackgroundMedia).toList();
      final overlayLayer = sorted.where((e) => !_isBackgroundMedia(e)).toList();

      return Container(
        color: controller.color.value,
        child: InteractiveViewer(
          panEnabled: false,
          scaleEnabled: false,
          child: Stack(
            children: [
              ...mediaLayer.map(_buildInteractiveElement),
              ...overlayLayer.map(_buildInteractiveElement),
              if (controller.isDragging.value)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildTrashBin(),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  bool _isBackgroundMedia(StoryElement e) {
    return e.type == StoryElementType.image || e.type == StoryElementType.video;
  }

  bool _isRemotePath(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority;
  }

  Widget _buildInteractiveElement(StoryElement e) {
    return Positioned(
      left: e.position.dx,
      top: e.position.dy,
      child: GestureDetector(
        onTapDown: (_) => controller.bringToFront(e),
        onDoubleTap: () async {
          if (e.type == StoryElementType.text) {
            final res = await showModalBottomSheet<TextEditorResult>(
              context: Get.context!,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const TextEditorSheet(),
            );
            if (res != null && res.text.trim().isNotEmpty) {
              controller.editTextElement(
                element: e,
                text: res.text.trim(),
                textColor: res.textColor,
                textBgColor: res.textBgColor,
                hasTextBg: res.hasTextBg,
                textAlign: res.textAlign,
                fontWeight: res.fontWeight,
                italic: res.italic,
                underline: res.underline,
                shadowBlur: res.shadowBlur,
                shadowOpacity: res.shadowOpacity,
                fontFamily: res.fontFamily,
                hasOutline: res.hasOutline,
                outlineColor: res.outlineColor,
              );
            }
          } else {
            controller.removeElement(e);
          }
        },
        onScaleStart: (details) {
          e.initialFocalPoint = details.focalPoint;
          e.initialPosition = e.position;
          e.initialWidth = e.width;
          e.initialHeight = e.height;
          e.initialRotation = e.rotation;
          e.initialFontSize = e.fontSize;
          controller.isDragging.value = true;
          controller.draggedElement = e;
        },
        onScaleUpdate: (details) {
          final screenWidth = Get.width;
          final screenHeight = Get.height;
          final dx = details.focalPoint.dx - e.initialFocalPoint!.dx;
          final dy = details.focalPoint.dy - e.initialFocalPoint!.dy;

          final newX = (e.initialPosition!.dx + dx)
              .clamp(-e.width * 0.5, screenWidth - e.width * 0.5);
          final newY = (e.initialPosition!.dy + dy)
              .clamp(-e.height * 0.5, screenHeight - e.height * 0.5);
          e.position = Offset(newX, newY);

          final scale = details.scale.clamp(0.3, 3.0);
          e.width = e.initialWidth! * scale;
          e.height = e.initialHeight! * scale;
          e.rotation = e.initialRotation! + details.rotation;

          if (e.type == StoryElementType.text) {
            e.fontSize = (e.initialFontSize! * scale).clamp(12.0, 120.0);
          }

          final trashBinCenterY = screenHeight - 20 - 50;
          final trashBinCenterX = screenWidth / 2;
          const trashBinRadius = 60;
          final fingerX = details.focalPoint.dx;
          final fingerY = details.focalPoint.dy;

          controller.lastFingerPosition = Offset(fingerX, fingerY);

          final distanceToTrash =
              ((fingerX - trashBinCenterX) * (fingerX - trashBinCenterX) +
                  (fingerY - trashBinCenterY) * (fingerY - trashBinCenterY));
          final isOverTrash =
              distanceToTrash < (trashBinRadius * trashBinRadius);

          if (!controller.isElementOverTrash.value && isOverTrash) {
            HapticFeedback.mediumImpact();
            controller.isElementOverTrash.value = true;
          } else if (controller.isElementOverTrash.value && !isOverTrash) {
            controller.isElementOverTrash.value = false;
          }

          controller.elements.refresh();
        },
        onScaleEnd: (details) {
          controller.isDragging.value = false;
          final shouldDelete = controller.isElementOverTrash.value;
          if (shouldDelete) {
            HapticFeedback.heavyImpact();
            controller.removeElement(e);
          }

          controller.isElementOverTrash.value = false;
          controller.draggedElement = null;
          controller.lastFingerPosition = null;
        },
        child: Transform.rotate(
          angle: e.rotation,
          alignment: Alignment.center,
          child: SizedBox(
            width: e.width,
            height: e.height,
            child: _buildElement(e),
          ),
        ),
      ),
    );
  }

  Widget _buildElement(StoryElement e) {
    switch (e.type) {
      case StoryElementType.image:
        if (_isRemotePath(e.content)) {
          return CachedNetworkImage(
            imageUrl: e.content,
            cacheManager: TurqImageCacheManager.instance,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (_, __) => Container(
              color: Colors.white12,
              child: const Center(
                child: CupertinoActivityIndicator(color: Colors.white),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Colors.white12,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white70),
              ),
            ),
          );
        }
        return Image.file(File(e.content), fit: BoxFit.cover);
      case StoryElementType.gif:
        return CachedNetworkImage(
          imageUrl: e.content,
          cacheManager: TurqImageCacheManager.instance,
          fit: BoxFit.contain,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (_, __) => Container(
            color: Colors.white12,
            child: const Center(
              child: CupertinoActivityIndicator(color: Colors.white),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.white12,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white70),
            ),
          ),
        );
      case StoryElementType.video:
        return Stack(
          children: [
            Positioned.fill(
              child: StoryVideo(path: e.content, isMuted: e.isMuted),
            ),
            Positioned(
              top: 20,
              right: 15,
              child: GestureDetector(
                onTap: () => controller.toggleVideoMute(e),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 1),
                  ),
                  child: Icon(
                    e.isMuted
                        ? CupertinoIcons.volume_off
                        : CupertinoIcons.volume_up,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      case StoryElementType.text:
        final align = switch (e.textAlign) {
          'left' => TextAlign.left,
          'right' => TextAlign.right,
          _ => TextAlign.center,
        };
        final fw = e.fontWeight == 'bold' ? FontWeight.bold : FontWeight.w500;
        final fs = e.italic ? FontStyle.italic : FontStyle.normal;
        final deco =
            e.underline ? TextDecoration.underline : TextDecoration.none;
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: e.hasTextBg
              ? BoxDecoration(
                  color: Color(e.textBgColor),
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          child: Text(
            e.content,
            textAlign: align,
            style: TextStyle(
              color: Color(e.textColor),
              fontSize: e.fontSize,
              fontWeight: fw,
              fontStyle: fs,
              decoration: deco,
              fontFamily: "MontserratMedium",
              height: 1.2,
              shadows: e.hasTextBg
                  ? null
                  : [
                      Shadow(
                        blurRadius: e.shadowBlur,
                        color: Colors.black.withValues(alpha: e.shadowOpacity),
                        offset: const Offset(1, 1),
                      ),
                    ],
            ),
            maxLines: null,
            overflow: TextOverflow.visible,
          ),
        );
      case StoryElementType.drawing:
        return Image.file(
          File(e.content),
          fit: BoxFit.cover,
        );
      case StoryElementType.sticker:
        final isSourceBadge = e.stickerType == 'source_profile';
        return Container(
          alignment: isSourceBadge ? Alignment.centerLeft : Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: isSourceBadge ? 12 : 14,
            vertical: isSourceBadge ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: isSourceBadge
                ? Color(e.textBgColor)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(isSourceBadge ? 10 : 999),
            border: isSourceBadge
                ? null
                : Border.all(color: Colors.black12, width: 1),
          ),
          child: Text(
            e.content,
            textAlign: isSourceBadge ? TextAlign.left : TextAlign.center,
            maxLines: isSourceBadge ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSourceBadge ? Color(e.textColor) : Colors.black,
              fontSize: isSourceBadge ? e.fontSize : 15,
              fontFamily: isSourceBadge ? e.fontFamily : 'MontserratMedium',
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  Widget _buildTrashBin() {
    return Obx(() {
      final isOverTrash = controller.isElementOverTrash.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isOverTrash ? 110 : 90,
        height: isOverTrash ? 110 : 90,
        decoration: BoxDecoration(
          color: isOverTrash
              ? Colors.red.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: isOverTrash ? Colors.red[300]! : Colors.white,
            width: 2,
          ),
          boxShadow: isOverTrash
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Icon(
          CupertinoIcons.delete,
          color: Colors.white,
          size: isOverTrash ? 42 : 36,
        ),
      );
    });
  }
}
