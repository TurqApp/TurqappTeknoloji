import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';
import '../../Themes/app_fonts.dart';

class HashtagTextVideoPostController extends GetxController {
  final String text;
  final String? nickname;
  final Color color;
  final void Function(bool) volume; // callback

  HashtagTextVideoPostController({
    required this.text,
    this.nickname,
    required this.color,
    required this.volume,
  });

  final expanded = false.obs;
  final showExpandButton = false.obs;
  final spans = <TextSpan>[].obs;

  // Interactive elements (hashtags, mentions, URLs, and the expand/collapse link)
  // should always appear blue to match the desired UX in fullscreen.
  Color get interactiveColor => Colors.blueAccent;

  @override
  void onInit() {
    super.onInit();
    _buildSpans();
  }

  @override
  void onClose() {
    for (final span in spans) {
      span.recognizer?.dispose();
    }
    super.onClose();
  }

  void _buildSpans() {
    for (final span in spans) {
      span.recognizer?.dispose();
    }
    final List<TextSpan> result = [];
    final hashtagRegex = RegExp(r'\B#([\wğüşöçıİĞÜŞÖÇ]+)', unicode: true);
    final urlRegex = RegExp(r'((http|https):\/\/|www\.)\S+');
    final mentionRegex = RegExp(r'@[\w.]+', unicode: true);

    // nickname varsa başa ekle
    if (nickname != null && nickname!.isNotEmpty) {
      result.add(TextSpan(
        text: '$nickname ',
        style: TextStyle(
          color: color == Colors.black ? Colors.black : Colors.indigo,
          fontSize: 13,
          fontFamily: AppFontFamilies.mbold,
        ),
      ));
    }

    int lastEnd = 0;
    final combined = RegExp(
      '${hashtagRegex.pattern}|${urlRegex.pattern}|${mentionRegex.pattern}',
      unicode: true,
      caseSensitive: false,
    );

    for (final m in combined.allMatches(text)) {
      if (m.start > lastEnd) {
        result.add(TextSpan(
          text: text.substring(lastEnd, m.start),
          style: TextStyle(
            color: color,
            height: 1.5,
            fontSize: 13,
            fontFamily: AppFontFamilies.mregular,
          ),
        ));
      }

      final match = m.group(0)!;
      // Tüm hashtag, url, mentionlar tek renk!
      if (hashtagRegex.hasMatch(match)) {
        result.add(TextSpan(
          text: match,
          style: _interactiveStyle(),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              volume(false);
              Get.to(() => TagPosts(tag: match))?.then((_) => volume(true));
            },
        ));
      } else if (urlRegex.hasMatch(match)) {
        result.add(TextSpan(
          text: match,
          style: _interactiveStyle(),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // İstersen buraya url launch ekle
            },
        ));
      } else if (mentionRegex.hasMatch(match)) {
        result.add(TextSpan(
          text: match,
          style: _interactiveStyle(),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // İstersen buraya mention fonksiyonu ekle
            },
        ));
      }

      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      result.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          color: color,
          height: 1.5,
          fontSize: 13,
          fontFamily: AppFontFamilies.mregular,
        ),
      ));
    }

    spans.assignAll(result);
  }

  TextStyle _interactiveStyle() => TextStyle(
        color: interactiveColor,
        height: 1.5,
        fontSize: 13,
        fontFamily: AppFontFamilies.mregular,
      );

  void toggleExpand() {
    expanded.toggle();
    _buildSpans();
  }

  void checkOverflow(TextPainter tp) {
    showExpandButton.value = tp.didExceedMaxLines;
  }
}

class HashtagTextVideoPost extends StatelessWidget {
  final String text;
  final String? nickname;
  final Color color;
  final void Function(bool) volume;

  const HashtagTextVideoPost({
    super.key,
    required this.text,
    required this.volume,
    this.nickname,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Include color/nickname in tag to avoid reusing a controller with stale styles
    String colorKey(Color c) => c.toARGB32().toRadixString(16);
    final tag =
        'htvp_${text.hashCode}_${colorKey(color)}_${nickname?.hashCode ?? 0}';
    final ctrl = Get.put(
      HashtagTextVideoPostController(
        text: text,
        nickname: nickname,
        color: color,
        volume: volume,
      ),
      tag: tag,
    );

    final baseStyle = TextStyle(
      color: color,
      height: 1.5,
      fontSize: 13,
      fontFamily: AppFontFamilies.mregular,
    );

    return LayoutBuilder(builder: (ctx, constraints) {
      final tp = TextPainter(
        text: TextSpan(style: baseStyle, children: ctrl.spans),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<HashtagTextVideoPostController>(tag: tag)) {
          ctrl.checkOverflow(tp);
        }
      });

      return Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                key: ValueKey(ctrl.expanded.value),
                text: TextSpan(style: baseStyle, children: ctrl.spans),
                maxLines: ctrl.expanded.value ? null : 1,
                overflow: ctrl.expanded.value
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (ctrl.showExpandButton.value)
                GestureDetector(
                  onTap: ctrl.toggleExpand,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      ctrl.expanded.value
                          ? 'common.hide'.tr
                          : 'common.show_more'.tr,
                      style: baseStyle.copyWith(
                        color: ctrl.interactiveColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ));
    });
  }
}
