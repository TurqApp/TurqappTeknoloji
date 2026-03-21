import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Themes/app_colors.dart';

class ClickableTextController extends GetxController {
  static const double defaultCaptionFontSize = 13;
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

  static List<TextSpan> buildSpans({
    required String text,
    required TextStyle plainStyle,
    required TextStyle urlStyle,
    required TextStyle hashtagStyle,
    required TextStyle mentionStyle,
    void Function(String url)? onUrlTap,
    void Function(String hashtag)? onHashtagTap,
    void Function(String mention)? onMentionTap,
    void Function(String plain)? onPlainTextTap,
  }) {
    final List<TextSpan> result = [];
    final pattern = RegExp(
      r'(\[([^\]]+)\]\(([^)\s]+)\))|((?:https?:\/\/)[^\s]+)|(@[^\s@#]+)|(#[^\s#@]+)',
      caseSensitive: false,
      unicode: true,
    );

    int lastEnd = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > lastEnd) {
        final plain = text.substring(lastEnd, m.start);
        result.add(
          TextSpan(
            text: plain,
            style: plainStyle,
            recognizer: onPlainTextTap == null
                ? null
                : (TapGestureRecognizer()
                  ..onTap = () => onPlainTextTap.call(plain.trim())),
          ),
        );
      }

      final match = m.group(0)!;
      final markdownLabel = m.group(2);
      final markdownTarget = m.group(3);

      if (markdownLabel != null && markdownTarget != null) {
        result.add(TextSpan(
          text: markdownLabel,
          style: urlStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onUrlTap?.call(markdownTarget),
        ));
      } else if (match.startsWith('http')) {
        result.add(TextSpan(
          text: match,
          style: urlStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onUrlTap?.call(match),
        ));
      } else if (match.startsWith('#')) {
        result.add(TextSpan(
          text: match,
          style: hashtagStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onHashtagTap?.call(match.substring(1)),
        ));
      } else if (match.startsWith('@')) {
        bool validBoundary = true;
        if (m.start > 0) {
          final prevChar = text[m.start - 1];
          if (!RegExp(r'\s').hasMatch(prevChar)) {
            validBoundary = false;
          }
        }
        if (validBoundary) {
          result.add(TextSpan(
            text: match,
            style: mentionStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => onMentionTap?.call(match.substring(1)),
          ));
        } else {
          result.add(TextSpan(
            text: match,
            style: plainStyle,
            recognizer: onPlainTextTap == null
                ? null
                : (TapGestureRecognizer()
                  ..onTap = () => onPlainTextTap.call(match.trim())),
          ));
        }
      }

      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      final plain = text.substring(lastEnd);
      result.add(TextSpan(
        text: plain,
        style: plainStyle,
        recognizer: onPlainTextTap == null
            ? null
            : (TapGestureRecognizer()
              ..onTap = () => onPlainTextTap.call(plain.trim())),
      ));
    }

    return result;
  }

  void _buildSpans() {
    for (final span in spans) {
      span.recognizer?.dispose();
    }
    spans.assignAll(
      buildSpans(
        text: text,
        plainStyle: _plainStyle(),
        urlStyle: _urlStyle(),
        hashtagStyle: _hashtagStyle(),
        mentionStyle: _mentionStyle(),
        onUrlTap: onUrlTap,
        onHashtagTap: onHashtagTap,
        onMentionTap: onMentionTap,
        onPlainTextTap: onPlainTextTap,
      ),
    );
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
        fontSize: fontSize ?? defaultCaptionFontSize,
        color: fontColor ?? Colors.black,
        fontFamily: "Montserrat",
        height: 1.4,
      );

  TextStyle _urlStyle() => TextStyle(
        fontSize: fontSize ?? defaultCaptionFontSize,
        color: interactiveColor ?? urlColor ?? Colors.blue,
        fontFamily: "Montserrat",
        height: 1.4,
      );

  TextStyle _hashtagStyle() => TextStyle(
        fontSize: fontSize ?? defaultCaptionFontSize,
        color: interactiveColor ?? hashtagColor ?? Colors.blue,
        fontFamily: "Montserrat",
        height: 1.4,
      );

  TextStyle _mentionStyle() => TextStyle(
        fontSize: fontSize ?? defaultCaptionFontSize,
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

class ClickableTextContent extends StatefulWidget {
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
  final bool toggleExpandOnTextTap;
  final Color? expandButtonColor;
  final double? expandButtonFontSize;

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
    this.toggleExpandOnTextTap = false,
    this.expandButtonColor,
    this.expandButtonFontSize,
  });

  @override
  State<ClickableTextContent> createState() => _ClickableTextContentState();
}

class _ClickableTextContentState extends State<ClickableTextContent> {
  late String _controllerTag;
  late ClickableTextController controller;
  bool _ownsController = false;

  String _colorKey(Color? c) => c?.toARGB32().toRadixString(16) ?? 'n';

  String _buildControllerTag() {
    final signature = 'click_${widget.text.hashCode}_'
        '${_colorKey(widget.fontColor)}_'
        '${_colorKey(widget.urlColor)}_'
        '${_colorKey(widget.mentionColor)}_'
        '${_colorKey(widget.hashtagColor)}_'
        '${_colorKey(widget.interactiveColor)}_'
        '${widget.startWith7line ? '7' : '2'}_'
        '${widget.toggleExpandOnTextTap ? 'tap' : 'btn'}_'
        '${identityHashCode(widget.onUrlTap)}_'
        '${identityHashCode(widget.onHashtagTap)}_'
        '${identityHashCode(widget.onMentionTap)}_'
        '${identityHashCode(widget.onPlainTextTap)}';
    return '${signature}_${identityHashCode(this)}';
  }

  ClickableTextController _createController() {
    return ClickableTextController(
      text: widget.text,
      onUrlTap: widget.onUrlTap,
      onHashtagTap: widget.onHashtagTap,
      onMentionTap: widget.onMentionTap,
      onPlainTextTap: widget.onPlainTextTap,
      fontSize: widget.fontSize,
      fontColor: widget.fontColor,
      urlColor: widget.urlColor,
      mentionColor: widget.mentionColor,
      hashtagColor: widget.hashtagColor,
      startWith7line: widget.startWith7line,
      interactiveColor: widget.interactiveColor,
    );
  }

  void _bindController() {
    if (Get.isRegistered<ClickableTextController>(tag: _controllerTag)) {
      controller = Get.find<ClickableTextController>(tag: _controllerTag);
      _ownsController = false;
    } else {
      controller = Get.put(_createController(), tag: _controllerTag);
      _ownsController = true;
    }
  }

  void _disposeOwnedController() {
    if (_ownsController &&
        Get.isRegistered<ClickableTextController>(tag: _controllerTag) &&
        identical(
          Get.find<ClickableTextController>(tag: _controllerTag),
          controller,
        )) {
      Get.delete<ClickableTextController>(tag: _controllerTag);
    }
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = _buildControllerTag();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant ClickableTextContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextTag = _buildControllerTag();
    if (nextTag == _controllerTag) return;
    _disposeOwnedController();
    _controllerTag = nextTag;
    _bindController();
  }

  @override
  void dispose() {
    _disposeOwnedController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: widget.fontSize ?? 15,
      color: widget.fontColor ?? Colors.black,
      fontFamily: "Montserrat",
      height: 1.4,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (Get.isRegistered<ClickableTextController>(tag: _controllerTag)) {
            controller.checkIfExceeds(constraints, baseStyle);
          }
        });

        return Obx(() {
          final collapsed = !controller.expanded.value;
          final maxLines =
              collapsed ? (controller.startWith7line ? 7 : 2) : null;
          final showOverlay = widget.showEllipsisOverlay &&
              collapsed &&
              controller.showExpandButton.value;
          Widget textBody = showOverlay
              // Yerleşim problemi olmadan, 7. satırın sonunda yerinde
              // gözükecek şekilde RichText'in kendi ellipsis'ini kullan
              ? RichText(
                  key: ValueKey(controller.expanded.value),
                  text: TextSpan(
                    style: baseStyle,
                    children: controller.spans,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                )
              : RichText(
                  key: ValueKey(controller.expanded.value),
                  text: TextSpan(style: baseStyle, children: controller.spans),
                  maxLines: maxLines,
                  overflow:
                      collapsed ? TextOverflow.ellipsis : TextOverflow.visible,
                );

          if (widget.toggleExpandOnTextTap &&
              controller.showExpandButton.value) {
            textBody = GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: controller.toggleExpand,
              child: textBody,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textBody,
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
                        ? 'common.show_less'.tr
                        : 'common.show_more'.tr,
                    style: TextStyle(
                      fontSize: widget.expandButtonFontSize ??
                          ((widget.fontSize ?? 15) - 1),
                      color: widget.expandButtonColor ??
                          widget.interactiveColor ??
                          widget.urlColor ??
                          AppColors.primaryColor,
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
