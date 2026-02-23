import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClickableTextController extends GetxController {
  final String text;
  final void Function(String url)? onUrlTap;
  final void Function(String hashtag)? onHashtagTap;
  final void Function(String mention)? onMentionTap;
  final void Function(String plain)? onPlainTextTap;

  final double? fontSize;
  final Color? fontColor;
  final Color? urlColor;
  final Color? mentionColor;
  final Color? hashtagColor;
  final Color? interactiveColor; // YENİ

  final bool startWith7line;

  var expanded = false.obs;
  var showExpandButton = false.obs;
  final spans = <TextSpan>[].obs;

  ClickableTextController({
    required this.text,
    this.onUrlTap,
    this.onHashtagTap,
    this.onMentionTap,
    this.onPlainTextTap,
    this.fontSize,
    this.fontColor,
    this.urlColor,
    this.hashtagColor,
    this.mentionColor,
    this.startWith7line = false,
    this.interactiveColor, // YENİ
  });

  @override
  void onInit() {
    super.onInit();
    _buildSpans();
  }

  void _buildSpans() {
    for (final span in spans) {
      span.recognizer?.dispose();
    }

    final List<TextSpan> result = [];
    final pattern = RegExp(
      r'(https?:\/\/[^\s]+)|(@[^\s@#]+)|(#[^\s#@]+)',
      caseSensitive: false,
      unicode: true,
    );

    int lastEnd = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > lastEnd) {
        final plain = text.substring(lastEnd, m.start);
        result.add(TextSpan(
          text: plain,
          style: _plainStyle(),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onPlainTextTap?.call(plain.trim()),
        ));
      }

      final match = m.group(0)!;

      if (match.startsWith('http')) {
        result.add(TextSpan(
          text: match,
          style: _urlStyle(),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onUrlTap?.call(match),
        ));
      } else if (match.startsWith('#')) {
        result.add(TextSpan(
          text: match,
          style: _hashtagStyle(),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onHashtagTap?.call(match.substring(1)),
        ));
      } else if (match.startsWith('@')) {
        // Mentions: sadece '@' işaretinden önce boşluk veya satır başı varsa tıkla/renkli yap
        bool validBoundary = true;
        if (m.start > 0) {
          final prevChar = text[m.start - 1];
          // Öncesi boşluk değilse (ör. e‑posta 'abc@domain' gibi) mention sayma
          if (!RegExp(r'\s').hasMatch(prevChar)) {
            validBoundary = false;
          }
        }
        if (validBoundary) {
          result.add(TextSpan(
            text: match,
            style: _mentionStyle(),
            recognizer: TapGestureRecognizer()
              ..onTap = () => onMentionTap?.call(match.substring(1)),
          ));
        } else {
          // Normal metin olarak ekle
          result.add(TextSpan(
            text: match,
            style: _plainStyle(),
            recognizer: TapGestureRecognizer()
              ..onTap = () => onPlainTextTap?.call(match.trim()),
          ));
        }
      }

      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      final plain = text.substring(lastEnd);
      result.add(TextSpan(
        text: plain,
        style: _plainStyle(),
        recognizer: TapGestureRecognizer()
          ..onTap = () => onPlainTextTap?.call(plain.trim()),
      ));
    }

    spans.assignAll(result);
  }

  void toggleExpand() {
    expanded.value = !expanded.value;
  }

  void checkIfExceeds(BoxConstraints constraints, TextStyle style) {
    final fullTextPainter = TextPainter(
      text: TextSpan(style: style, children: spans),
      maxLines: null,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: constraints.maxWidth);

    final previewLines = startWith7line ? 7 : 2;
    final previewPainter = TextPainter(
      text: TextSpan(style: style, children: spans),
      maxLines: previewLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: constraints.maxWidth);

    showExpandButton.value = fullTextPainter.height > previewPainter.height + 2;
  }

  TextStyle _plainStyle() => TextStyle(
        fontSize: fontSize ?? 15,
        color: fontColor ?? Colors.black,
        fontFamily: "Montserrat",
        height: 1.4,
      );

  TextStyle _urlStyle() => TextStyle(
        fontSize: fontSize ?? 15,
        color: interactiveColor ?? urlColor ?? Colors.blue,
        fontFamily: "Montserrat",
        height: 1.4,
      );

  TextStyle _hashtagStyle() => TextStyle(
        fontSize: fontSize ?? 15,
        color: interactiveColor ?? hashtagColor ?? Colors.blue,
        fontFamily: "Montserrat",
        height: 1.4,
      );

  TextStyle _mentionStyle() => TextStyle(
        fontSize: fontSize ?? 15,
        color: interactiveColor ?? mentionColor ?? Colors.blue,
        fontFamily: "Montserrat",
        height: 1.4,
      );

  @override
  void onClose() {
    for (final span in spans) {
      span.recognizer?.dispose();
    }
    super.onClose();
  }
}

class ClickableTextContent extends StatelessWidget {
  final String text;
  final void Function(String url)? onUrlTap;
  final void Function(String hashtag)? onHashtagTap;
  final void Function(String mention)? onMentionTap;
  final void Function(String plain)? onPlainTextTap;

  final double? fontSize;
  final Color? fontColor;
  final Color? urlColor;
  final Color? mentionColor;
  final Color? hashtagColor;
  final bool startWith7line;
  final Color? interactiveColor; // YENİ
  final bool showEllipsisOverlay; // YENİ: 7 satır kısaltmada sağ-altta '…'

  const ClickableTextContent({
    super.key,
    required this.text,
    this.onUrlTap,
    this.onHashtagTap,
    this.onMentionTap,
    this.onPlainTextTap,
    this.fontSize,
    this.fontColor,
    this.urlColor,
    this.mentionColor,
    this.hashtagColor,
    this.startWith7line = false,
    this.interactiveColor, // YENİ
    this.showEllipsisOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    // Controller tag must reflect style so different contexts don't reuse
    // a controller with stale colors (e.g., fullscreen vs feed).
    String colorKey(Color? c) => c?.toARGB32().toRadixString(16) ?? 'n';
    final tag = 'click_${text.hashCode}_'
        '${colorKey(fontColor)}_'
        '${colorKey(urlColor)}_'
        '${colorKey(mentionColor)}_'
        '${colorKey(hashtagColor)}_'
        '${colorKey(interactiveColor)}_'
        '${startWith7line ? '7' : '2'}';

    final controller = Get.put(
      ClickableTextController(
        text: text,
        onUrlTap: onUrlTap,
        onHashtagTap: onHashtagTap,
        onMentionTap: onMentionTap,
        onPlainTextTap: onPlainTextTap,
        fontSize: fontSize,
        fontColor: fontColor,
        urlColor: urlColor,
        mentionColor: mentionColor,
        hashtagColor: hashtagColor,
        startWith7line: startWith7line,
        interactiveColor: interactiveColor, // YENİ
      ),
      tag: tag,
    );

    final baseStyle = TextStyle(
      fontSize: fontSize ?? 15,
      color: fontColor ?? Colors.black,
      fontFamily: "Montserrat",
      height: 1.4,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.isRegistered<ClickableTextController>(tag: tag)) {
            controller.checkIfExceeds(constraints, baseStyle);
          }
        });

        return Obx(() {
          final collapsed = !controller.expanded.value;
          final maxLines =
              collapsed ? (controller.startWith7line ? 7 : 2) : null;
          final showOverlay = showEllipsisOverlay &&
              collapsed &&
              controller.showExpandButton.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showOverlay)
                // Yerleşim problemi olmadan, 7. satırın sonunda yerinde
                // gözükecek şekilde RichText'in kendi ellipsis'ini kullan
                RichText(
                  key: ValueKey(controller.expanded.value),
                  text: TextSpan(
                    style: baseStyle,
                    children: controller.spans,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                )
              else
                RichText(
                  key: ValueKey(controller.expanded.value),
                  text: TextSpan(style: baseStyle, children: controller.spans),
                  maxLines: maxLines,
                  overflow:
                      collapsed ? TextOverflow.ellipsis : TextOverflow.visible,
                ),
              if (controller.showExpandButton.value)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: controller.toggleExpand,
                  child: Text(
                    controller.expanded.value
                        ? 'Daha az göster'
                        : 'Daha fazla göster',
                    style: TextStyle(
                      fontSize: (fontSize ?? 15) - 1,
                      color: interactiveColor ?? urlColor ?? Colors.white,
                      fontFamily: "Montserrat",
                    ),
                  ),
                ),
            ],
          );
        });
      },
    );
  }
}
