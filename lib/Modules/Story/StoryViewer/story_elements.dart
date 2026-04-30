import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/Repositories/username_lookup_repository.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import '../StoryMaker/story_maker_controller.dart';

class StoryImageWidget extends StatelessWidget {
  final StoryElement element;

  const StoryImageWidget({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      width: element.width,
      height: element.height,
      child: Transform.rotate(
        angle: element.rotation,
        child: CachedNetworkImage(
          cacheManager: TurqImageCacheManager.instance,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          imageUrl: element.content,
          fit: BoxFit.contain, // Cover yerine contain - aspect ratio korunur
          placeholder: (context, url) => Container(
            color: Colors.grey.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.withValues(alpha: 0.3),
            child: const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class StoryGifWidget extends StatelessWidget {
  final StoryElement element;
  const StoryGifWidget({required this.element, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      width: element.width,
      height: element.height,
      child: Transform.rotate(
        angle: element.rotation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: element.content,
            cacheManager: TurqImageCacheManager.instance,
            fit: BoxFit.contain, // Cover yerine contain - aspect ratio korunur
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholderFadeInDuration: Duration.zero,
            placeholder: (context, _) {
              return Container(
                color: Colors.grey.withValues(alpha: 0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                      SizedBox(height: 8),
                      Text("chat.gif".tr,
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.withValues(alpha: 0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(height: 4),
                    Text("story.gif_load_failed".tr,
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StoryTextWidget extends StatelessWidget {
  final StoryElement element;
  const StoryTextWidget({required this.element, super.key});

  static final _mentionRegex = RegExp(r'@(\w+)');

  bool get _hasMentions => _mentionRegex.hasMatch(element.content);

  List<InlineSpan> _buildMentionSpans(TextStyle baseStyle) {
    final text = element.content;
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _mentionRegex.allMatches(text)) {
      // Text before mention
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      // Mention text (blue + tappable)
      final username = match.group(1)!;
      spans.add(TextSpan(
        text: match.group(0),
        style: baseStyle.copyWith(color: Colors.blue),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            // Find user by canonical username/display mapping first, then fallback.
            final targetUid =
                await UsernameLookupRepository.ensure().findUidForHandle(
              username,
            );
            if ((targetUid ?? '').isNotEmpty) {
              await const ProfileNavigationService()
                  .openSocialProfile(targetUid!);
            }
          },
      ));
      lastEnd = match.end;
    }
    // Remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isSourceBadge = element.stickerType == 'source_profile';
    final align = () {
      switch (isSourceBadge ? 'left' : element.textAlign) {
        case 'left':
          return TextAlign.left;
        case 'right':
          return TextAlign.right;
        case 'center':
        default:
          return TextAlign.center;
      }
    }();
    final fw = element.fontWeight == 'bold' ? FontWeight.bold : FontWeight.w500;
    final fs = element.italic ? FontStyle.italic : FontStyle.normal;
    final deco =
        element.underline ? TextDecoration.underline : TextDecoration.none;
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      width: element.width,
      height: element.height,
      child: Transform.rotate(
        angle: element.rotation,
        child: GestureDetector(
          onTap: () async {
            if (element.stickerType == 'link' &&
                element.stickerData.isNotEmpty) {
              final uri = Uri.tryParse(element.stickerData.trim());
              if (uri != null) {
                await confirmAndLaunchExternalUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              }
            }
          },
          child: Container(
            width: element.width,
            height: element.height,
            alignment: isSourceBadge ? Alignment.centerLeft : Alignment.center,
            decoration: (element.hasTextBg || isSourceBadge)
                ? BoxDecoration(
                    color: Color(element.textBgColor),
                    borderRadius:
                        BorderRadius.circular(isSourceBadge ? 10 : 10),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: element.hasOutline
                ? Stack(
                    children: [
                      // Outline (stroke) layer
                      Text(
                        element.content,
                        textAlign: align,
                        style: TextStyle(
                          fontSize: element.fontSize,
                          fontWeight: fw,
                          fontStyle: fs,
                          decoration: deco,
                          fontFamily: element.fontFamily,
                          height: 1.2,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 2.0
                            ..color = Color(element.outlineColor),
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                      // Fill layer
                      Text(
                        element.content,
                        textAlign: align,
                        style: TextStyle(
                          color: Color(element.textColor),
                          fontSize: element.fontSize,
                          fontWeight: fw,
                          fontStyle: fs,
                          decoration: deco,
                          fontFamily: element.fontFamily,
                          height: 1.2,
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  )
                : () {
                    final baseStyle = TextStyle(
                      color: Color(element.textColor),
                      fontSize: element.fontSize,
                      fontWeight: fw,
                      fontStyle: fs,
                      decoration: deco,
                      fontFamily: element.fontFamily,
                      height: 1.2,
                      shadows: !element.hasTextBg
                          ? [
                              Shadow(
                                blurRadius: element.shadowBlur,
                                color: Colors.black
                                    .withValues(alpha: element.shadowOpacity),
                                offset: const Offset(1, 1),
                              ),
                            ]
                          : null,
                    );
                    if (_hasMentions) {
                      return RichText(
                        textAlign: align,
                        text: TextSpan(
                          children: _buildMentionSpans(baseStyle),
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      );
                    }
                    return Text(
                      element.content,
                      textAlign: align,
                      style: baseStyle,
                      maxLines: isSourceBadge ? 1 : null,
                      overflow: isSourceBadge
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                    );
                  }(),
          ),
        ),
      ),
    );
  }
}
