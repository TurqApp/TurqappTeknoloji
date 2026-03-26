part of 'clickable_text_content.dart';

class _ClickableTextControllerConfig {
  const _ClickableTextControllerConfig({
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
    this.interactiveColor,
  });

  final String text;
  final void Function(String)? onUrlTap,
      onHashtagTap,
      onMentionTap,
      onPlainTextTap;
  final double? fontSize;
  final Color? fontColor,
      urlColor,
      mentionColor,
      hashtagColor,
      interactiveColor;
  final bool startWith7line;
}

extension _ClickableTextControllerConfigPart on ClickableTextController {
  String get text => _config.text;
  void Function(String)? get onUrlTap => _config.onUrlTap;
  void Function(String)? get onHashtagTap => _config.onHashtagTap;
  void Function(String)? get onMentionTap => _config.onMentionTap;
  void Function(String)? get onPlainTextTap => _config.onPlainTextTap;
  double? get fontSize => _config.fontSize;
  Color? get fontColor => _config.fontColor;
  Color? get urlColor => _config.urlColor;
  Color? get mentionColor => _config.mentionColor;
  Color? get hashtagColor => _config.hashtagColor;
  Color? get interactiveColor => _config.interactiveColor;
  bool get startWith7line => _config.startWith7line;
}

ClickableTextController _ensureClickableTextController({
  required String text,
  void Function(String url)? onUrlTap,
  void Function(String hashtag)? onHashtagTap,
  void Function(String mention)? onMentionTap,
  void Function(String plain)? onPlainTextTap,
  double? fontSize,
  Color? fontColor,
  Color? urlColor,
  Color? mentionColor,
  Color? hashtagColor,
  bool startWith7line = false,
  Color? interactiveColor,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindClickableTextController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ClickableTextController._(
      _ClickableTextControllerConfig(
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
        interactiveColor: interactiveColor,
      ),
    ),
    tag: tag,
    permanent: permanent,
  );
}

ClickableTextController? _maybeFindClickableTextController({String? tag}) {
  final isRegistered = Get.isRegistered<ClickableTextController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ClickableTextController>(tag: tag);
}

List<TextSpan> _buildClickableTextControllerSpans({
  required String text,
  required TextStyle plainStyle,
  required TextStyle urlStyle,
  required TextStyle hashtagStyle,
  required TextStyle mentionStyle,
  void Function(String url)? onUrlTap,
  void Function(String hashtag)? onHashtagTap,
  void Function(String mention)? onMentionTap,
  void Function(String plain)? onPlainTextTap,
}) =>
    _buildClickableTextSpans(
      text: text,
      plainStyle: plainStyle,
      urlStyle: urlStyle,
      hashtagStyle: hashtagStyle,
      mentionStyle: mentionStyle,
      onUrlTap: onUrlTap,
      onHashtagTap: onHashtagTap,
      onMentionTap: onMentionTap,
      onPlainTextTap: onPlainTextTap,
    );

void _handleClickableTextControllerInit(ClickableTextController controller) {
  controller._buildSpans();
}

void _handleClickableTextControllerClose(ClickableTextController controller) {
  _disposeClickableTextRecognizers(controller.spans);
}

extension ClickableTextControllerHelpersPart on ClickableTextController {
  void _buildSpans() {
    _disposeClickableTextRecognizers(spans);
    spans.assignAll(
      _buildClickableTextControllerSpans(
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
        fontSize: fontSize ?? ClickableTextController.defaultCaptionFontSize,
        color: fontColor ?? Colors.black,
        fontFamily: "Montserrat",
        height: 1.4,
      );

  TextStyle _urlStyle() => TextStyle(
        fontSize: fontSize ?? ClickableTextController.defaultCaptionFontSize,
        color: interactiveColor ?? urlColor ?? Colors.blue,
        fontFamily: "Montserrat",
        height: 1.4,
      );

  TextStyle _hashtagStyle() => TextStyle(
        fontSize: fontSize ?? ClickableTextController.defaultCaptionFontSize,
        color: interactiveColor ?? hashtagColor ?? Colors.blue,
        fontFamily: "Montserrat",
        height: 1.4,
      );

  TextStyle _mentionStyle() => TextStyle(
        fontSize: fontSize ?? ClickableTextController.defaultCaptionFontSize,
        color: interactiveColor ?? mentionColor ?? Colors.blue,
        fontFamily: "Montserrat",
        height: 1.4,
      );
}

List<TextSpan> _buildClickableTextSpans({
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
      result.add(
        TextSpan(
          text: markdownLabel,
          style: urlStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onUrlTap?.call(markdownTarget),
        ),
      );
    } else if (match.startsWith('http')) {
      result.add(
        TextSpan(
          text: match,
          style: urlStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onUrlTap?.call(match),
        ),
      );
    } else if (match.startsWith('#')) {
      result.add(
        TextSpan(
          text: match,
          style: hashtagStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onHashtagTap?.call(match.substring(1)),
        ),
      );
    } else if (match.startsWith('@')) {
      bool validBoundary = true;
      if (m.start > 0) {
        final prevChar = text[m.start - 1];
        if (!RegExp(r'\s').hasMatch(prevChar)) {
          validBoundary = false;
        }
      }
      if (validBoundary) {
        result.add(
          TextSpan(
            text: match,
            style: mentionStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => onMentionTap?.call(match.substring(1)),
          ),
        );
      } else {
        result.add(
          TextSpan(
            text: match,
            style: plainStyle,
            recognizer: onPlainTextTap == null
                ? null
                : (TapGestureRecognizer()
                  ..onTap = () => onPlainTextTap.call(match.trim())),
          ),
        );
      }
    }

    lastEnd = m.end;
  }

  if (lastEnd < text.length) {
    final plain = text.substring(lastEnd);
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

  return result;
}

void _disposeClickableTextRecognizers(List<TextSpan> spans) {
  for (final span in spans) {
    span.recognizer?.dispose();
  }
}
