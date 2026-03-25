part of 'clickable_text_content.dart';

extension ClickableTextControllerHelpersPart on ClickableTextController {
  void _buildSpans() {
    _disposeClickableTextRecognizers(spans);
    spans.assignAll(
      ClickableTextController.buildSpans(
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
