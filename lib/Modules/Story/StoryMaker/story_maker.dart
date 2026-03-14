import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/icon_buttons.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'story_maker_controller.dart';
import 'story_sticker_sheet.dart';
import 'story_video.dart';
import 'text_editor_sheet.dart';

class StoryMaker extends StatelessWidget {
  static const Map<String, String> _mediaLookLabels = <String, String>{
    'original': 'Orijinal',
    'clear': 'Temiz',
    'cinema': 'Sinematik',
    'vibe': 'Canlı',
  };
  static const Map<String, IconData> _mediaLookIcons = <String, IconData>{
    'original': CupertinoIcons.circle,
    'clear': CupertinoIcons.sparkles,
    'cinema': CupertinoIcons.film,
    'vibe': CupertinoIcons.sun_max,
  };

  final String initialMediaUrl;
  final bool initialMediaIsVideo;
  final double initialMediaAspectRatio;
  final String initialSourceUserId;
  final String initialSourceDisplayName;
  final controller = Get.put(StoryMakerController());

  StoryMaker({
    super.key,
    this.initialMediaUrl = '',
    this.initialMediaIsVideo = false,
    this.initialMediaAspectRatio = 9 / 16,
    this.initialSourceUserId = '',
    this.initialSourceDisplayName = '',
  });

  @override
  Widget build(BuildContext context) {
    controller.applySharedPostSeedIfNeeded(
      mediaUrl: initialMediaUrl,
      isVideo: initialMediaIsVideo,
      aspectRatio: initialMediaAspectRatio,
      sourceUserId: initialSourceUserId,
      sourceDisplayName: initialSourceDisplayName,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            topBar(),
            Expanded(child: playground()),
            mediaLookTools(),
            bottomTools(context),
          ],
        ),
      ),
    );
  }

  Widget mediaLookTools() {
    return Obx(() {
      final media = controller.currentBackgroundMediaElement;
      if (media == null) return const SizedBox.shrink();
      final presets = StoryMakerController.supportedMediaLookPresets;
      return Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 8),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  CupertinoIcons.slider_horizontal_3,
                  size: 15,
                  color: Colors.white70,
                ),
                SizedBox(width: 6),
                Text(
                  'Görünüm',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: presets.map((preset) {
                  final isSelected = media.mediaLookPreset == preset;
                  final label = _mediaLookLabels[preset] ?? preset;
                  final icon = _mediaLookIcons[preset] ?? CupertinoIcons.circle;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => controller.setCurrentMediaLookPreset(preset),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 12,
                                fontFamily: isSelected
                                    ? "MontserratBold"
                                    : "MontserratMedium",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget playground() {
    return Obx(() {
      // Katmanlama:
      // 1) Arka plan medya (image/video) daima altta
      // 2) Diğer öğeler (text/sticker/gif/drawing) daima üstte
      // Her katmanda kendi içinde zIndex sırası korunur.
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
              // Background media first
              ...mediaLayer.map(_buildInteractiveElement),
              // Interactive overlays on top
              ...overlayLayer.map(_buildInteractiveElement),

              // Trash bin - sadece element sürüklenirken göster
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
          // Metin için: silmek yerine düzenleme aç (Instagram benzeri)
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
          // Boundary kontrolü
          final screenWidth = Get.width;
          final screenHeight = Get.height;

          // drag
          final dx = details.focalPoint.dx - e.initialFocalPoint!.dx;
          final dy = details.focalPoint.dy - e.initialFocalPoint!.dy;

          final newX = (e.initialPosition!.dx + dx)
              .clamp(-e.width * 0.5, screenWidth - e.width * 0.5);
          final newY = (e.initialPosition!.dy + dy)
              .clamp(-e.height * 0.5, screenHeight - e.height * 0.5);
          e.position = Offset(newX, newY);

          // scale with limits
          final scale = details.scale.clamp(0.3, 3.0);
          e.width = e.initialWidth! * scale;
          e.height = e.initialHeight! * scale;

          // rotation
          e.rotation = e.initialRotation! + details.rotation;

          // fontSize update with bounds
          if (e.type == StoryElementType.text) {
            e.fontSize = (e.initialFontSize! * scale).clamp(12.0, 120.0);
          }

          // Çöp kutusunun pozisyonunu kontrol et - parmak pozisyonunu kullan
          // Çöp kutusu bottom: 20'de konumlandırılmış, boyutu 90-110px
          final trashBinCenterY =
              screenHeight - 20 - 50; // bottom margin - yarı yükseklik
          final trashBinCenterX = screenWidth / 2;
          final trashBinRadius = 60; // Çöp kutusunun gerçek yarıçapı + margin

          // Parmağın pozisyonu
          final fingerX = details.focalPoint.dx;
          final fingerY = details.focalPoint.dy;

          // Son parmak pozisyonunu controller'da sakla
          controller.lastFingerPosition = Offset(fingerX, fingerY);

          // Parmak çöp kutusu alanında mı? (circular detection)
          final distanceToTrash =
              ((fingerX - trashBinCenterX) * (fingerX - trashBinCenterX) +
                  (fingerY - trashBinCenterY) * (fingerY - trashBinCenterY));
          final isOverTrash =
              distanceToTrash < (trashBinRadius * trashBinRadius);

          // Eğer önceden trash üzerinde değildi ama şimdi üzerindeyse haptic feedback ver
          if (!controller.isElementOverTrash.value && isOverTrash) {
            HapticFeedback.mediumImpact(); // Titreme efekti
            controller.isElementOverTrash.value = true;
          } else if (controller.isElementOverTrash.value && !isOverTrash) {
            controller.isElementOverTrash.value = false;
          }

          controller.elements.refresh();
        },
        onScaleEnd: (details) {
          controller.isDragging.value = false;
          // Bırakma anında güvenilir kriter: onScaleUpdate boyunca hesaplanan state.
          // Bu sayede son parmak pozisyonu null olduğunda da silme kaçmaz.
          final shouldDelete = controller.isElementOverTrash.value;
          if (shouldDelete) {
            // Parmak çöp kutusuna bırakıldı, sil
            HapticFeedback.heavyImpact(); // Güçlü titreme - silme başarılı
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
                        ? CupertinoIcons.speaker_slash
                        : CupertinoIcons.speaker_2,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      case StoryElementType.text:
        final align = () {
          switch (e.textAlign) {
            case 'left':
              return TextAlign.left;
            case 'right':
              return TextAlign.right;
            case 'center':
            default:
              return TextAlign.center;
          }
        }();
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

  Widget topBar() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol taraf - Back + Undo/Redo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(CupertinoIcons.arrow_left,
                    color: Colors.white, size: 24),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              Obx(() => IconButton(
                    onPressed:
                        controller.canUndo.value ? controller.undo : null,
                    icon: Icon(CupertinoIcons.arrow_uturn_left,
                        color: controller.canUndo.value
                            ? Colors.white
                            : Colors.grey,
                        size: 18),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 35, minHeight: 35),
                  )),
              Obx(() => IconButton(
                    onPressed:
                        controller.canRedo.value ? controller.redo : null,
                    icon: Icon(CupertinoIcons.arrow_uturn_right,
                        color: controller.canRedo.value
                            ? Colors.white
                            : Colors.grey,
                        size: 18),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 35, minHeight: 35),
                  )),
            ],
          ),

          Text("Hikaye Oluştur",
              style: TextStyle(
                  fontSize: 16,
                  fontFamily: "MontserratMedium",
                  color: Colors.white)),

          // Sağ taraf - Share button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onLongPress: () => controller.onScheduleStoryPressed(),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => controller.onSaveStoryPressed(),
                  child: Text("Paylas",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: "MontserratMedium")),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget bottomTools(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextButton(
              style: IconButtons.storyButtons,
              onPressed: () => controller.pickImage(),
              child: Icon(CupertinoIcons.photo, color: Colors.white, size: 25),
            ),
          ),
          Expanded(
            child: TextButton(
              style: IconButtons.storyButtons,
              onPressed: () => controller.pickVideo(),
              child: Icon(CupertinoIcons.play_circle,
                  color: Colors.white, size: 25),
            ),
          ),
          Expanded(
            child: TextButton(
              style: IconButtons.storyButtons,
              onPressed: () => showStoryStickerSheet(Get.context!, controller),
              child: const Icon(CupertinoIcons.sparkles,
                  color: Colors.white, size: 24),
            ),
          ),
          // Expanded(
          //   child: TextButton(
          //     style: IconButtons.storyButtons,
          //     onPressed: () async {
          //       final res = await showModalBottomSheet<TextEditorResult>(
          //         context: Get.context!,
          //         isScrollControlled: true,
          //         backgroundColor: Colors.transparent,
          //         builder: (ctx) => const TextEditorSheet(),
          //       );
          //       if (res != null && res.text.trim().isNotEmpty) {
          //         controller.addStyledTextElement(
          //           res.text.trim(),
          //           textColor: res.textColor,
          //           textBgColor: res.textBgColor,
          //           hasTextBg: res.hasTextBg,
          //           textAlign: res.textAlign,
          //           fontWeight: res.fontWeight,
          //           italic: res.italic,
          //           underline: res.underline,
          //           shadowBlur: res.shadowBlur,
          //           shadowOpacity: res.shadowOpacity,
          //         );
          //       }
          //     },
          //     child: Icon(CupertinoIcons.text_cursor,
          //         color: Colors.white, size: 25),
          //   ),
          // ),
          Expanded(child: Obx(() {
            return IconButton(
              icon: Icon(
                CupertinoIcons.music_note_2,
                color: controller.isMusicPlaying.value
                    ? Colors.blueAccent
                    : Colors.white,
                size: 30,
              ),
              onPressed: () {
                if (controller.isMusicPlaying.value) {
                  controller.pauseMusic();
                } else {
                  controller.selectMusic();
                }
              },
            );
          })),
          Expanded(
            child: Obx(() {
              return TextButton(
                style: IconButtons.storyButtons,
                onPressed: () => controller.changeCircleColor(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.color.value,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashBin() {
    return Obx(() {
      final isOverTrash = controller.isElementOverTrash.value;

      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
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
