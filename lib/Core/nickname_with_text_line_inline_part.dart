part of 'nickname_with_text_line.dart';

extension NicknameWithTextLineInlinePart on _NicknameWithTextLineState {
  Widget _buildCollapsedTextWithInlineButton(
    List<TextSpan> spans,
    TextStyle defaultStyle,
    BoxConstraints constraints,
  ) {
    final buttonText = 'common.show_more'.tr;
    final buttonStyle = _NicknameWithTextLineState._buttonStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(style: defaultStyle, children: spans),
          maxLines: widget.collapsedMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: GestureDetector(
            onTap: () => _setExpanded(true),
            child: Text(buttonText, style: buttonStyle),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedTextWithInlineButton(
    List<TextSpan> spans,
    TextStyle defaultStyle,
    BoxConstraints constraints,
  ) {
    final buttonText = 'common.show_less'.tr;
    final buttonStyle = _NicknameWithTextLineState._buttonStyle;
    return _buildInlineTextWithButton(
      spans,
      buttonText,
      buttonStyle,
      defaultStyle,
      constraints,
      false,
    );
  }

  Widget _buildInlineTextWithButton(
    List<TextSpan> spans,
    String buttonText,
    TextStyle buttonStyle,
    TextStyle defaultStyle,
    BoxConstraints constraints,
    bool isCollapsed,
  ) {
    final fullText = spans.map((span) => span.text ?? '').join();

    if (isCollapsed) {
      final firstLineText =
          _getFirstLineText(fullText, defaultStyle, constraints);
      final buttonSpan = TextSpan(text: " $buttonText", style: buttonStyle);
      final combinedPainter = TextPainter(
        text: TextSpan(
          style: defaultStyle,
          children: [
            TextSpan(text: firstLineText),
            buttonSpan,
          ],
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: constraints.maxWidth);

      if (!combinedPainter.didExceedMaxLines) {
        return GestureDetector(
          onTap: () => _setExpanded(true),
          child: RichText(
            text: TextSpan(
              style: defaultStyle,
              children: [
                TextSpan(text: firstLineText),
                TextSpan(text: " $buttonText", style: buttonStyle),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: defaultStyle,
              children: [TextSpan(text: firstLineText)],
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: GestureDetector(
              onTap: () => _setExpanded(true),
              child: Text(buttonText, style: buttonStyle),
            ),
          ),
        ],
      );
    }

    final buttonSpan = TextSpan(text: " $buttonText", style: buttonStyle);
    final combinedSpans = [...spans, buttonSpan];
    final testPainter = TextPainter(
      text: TextSpan(style: defaultStyle, children: combinedSpans),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: constraints.maxWidth);

    final lines = testPainter.computeLineMetrics();
    if (lines.isNotEmpty && lines.last.width <= constraints.maxWidth) {
      return GestureDetector(
        onTap: () => _setExpanded(false),
        child: RichText(
          text: TextSpan(
            style: defaultStyle,
            children: [
              ...spans,
              TextSpan(text: " $buttonText", style: buttonStyle),
            ],
          ),
          overflow: TextOverflow.visible,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(style: defaultStyle, children: spans),
          overflow: TextOverflow.visible,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: GestureDetector(
            onTap: () => _setExpanded(false),
            child: Text(buttonText, style: buttonStyle),
          ),
        ),
      ],
    );
  }

  String _getFirstLineText(
    String fullText,
    TextStyle defaultStyle,
    BoxConstraints constraints,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: fullText, style: defaultStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: constraints.maxWidth);

    if (!painter.didExceedMaxLines) {
      return fullText;
    }

    final textPainter = TextPainter(
      text: TextSpan(text: fullText, style: defaultStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: constraints.maxWidth);

    final position = textPainter.getPositionForOffset(
      Offset(constraints.maxWidth, textPainter.size.height / 2),
    );

    if (position.offset > 0 && position.offset < fullText.length) {
      var truncatedText = fullText.substring(0, position.offset);
      final lastSpaceIndex = truncatedText.lastIndexOf(' ');

      if (lastSpaceIndex > 0 && lastSpaceIndex < truncatedText.length - 10) {
        truncatedText = truncatedText.substring(0, lastSpaceIndex);
      }

      return truncatedText.trimRight();
    }

    return fullText;
  }
}
