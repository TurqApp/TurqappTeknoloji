part of 'nickname_with_text_line.dart';

extension NicknameWithTextLineViewPart on _NicknameWithTextLineState {
  Widget _buildNicknameLine(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: widget.fontSize,
      fontFamily: "Montserrat",
      color: Colors.black,
      height: 1.5,
    );
    final spans = _buildTextSpans(defaultStyle);

    return Padding(
      padding: widget.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _syncExpandState(spans, constraints);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.inlineExpand && showExpandButton && !expanded)
                _buildCollapsedTextWithInlineButton(
                  spans,
                  defaultStyle,
                  constraints,
                )
              else if (widget.inlineExpand && showExpandButton && expanded)
                _buildExpandedTextWithInlineButton(
                  spans,
                  defaultStyle,
                  constraints,
                )
              else
                _buildPlainText(defaultStyle, spans),
            ],
          );
        },
      ),
    );
  }

  List<TextSpan> _buildTextSpans(TextStyle defaultStyle) {
    final spans = <TextSpan>[];
    if (widget.showNickname) {
      spans.add(
        TextSpan(
          text: '@${widget.nickname}',
          style: TextStyle(
            fontFamily: "MontserratBold",
            fontWeight: FontWeight.w700,
            fontSize: widget.fontSize,
            color: widget.nicknameColor,
          ),
          recognizer: TapGestureRecognizer()..onTap = widget.onNicknameTap,
        ),
      );
    }

    if (widget.metin.trim().isEmpty) return spans;

    final words = widget.metin.split(' ');
    for (final word in words) {
      if (word.startsWith("@")) {
        spans.add(
          TextSpan(
            text: spans.isEmpty ? word : " $word",
            style: defaultStyle.copyWith(color: Colors.blue),
            recognizer: TapGestureRecognizer()..onTap = widget.onNicknameTap,
          ),
        );
      } else if (word.startsWith("#")) {
        spans.add(
          TextSpan(
            text: spans.isEmpty ? word : " $word",
            style: defaultStyle.copyWith(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                widget.onAnyTap();
                Get.to(() => TagPosts(tag: word));
              },
          ),
        );
      } else if (hasHttpUrlScheme(word)) {
        spans.add(
          TextSpan(
            text: spans.isEmpty ? word : " $word",
            style: defaultStyle.copyWith(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                widget.onAnyTap();
                RedirectionLink().goToLink(word);
              },
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: spans.isEmpty ? word : " $word",
            style: defaultStyle,
          ),
        );
      }
    }
    return spans;
  }

  void _syncExpandState(List<TextSpan> spans, BoxConstraints constraints) {
    if (widget.inlineExpand) {
      final tp = TextPainter(
        text: TextSpan(children: spans),
        textDirection: TextDirection.ltr,
        maxLines: widget.collapsedMaxLines,
      )..layout(maxWidth: constraints.maxWidth);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && tp.didExceedMaxLines != showExpandButton) {
          setState(() {
            showExpandButton = tp.didExceedMaxLines;
          });
        }
      });
      return;
    }

    if (showExpandButton) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => showExpandButton = false);
      });
    }
  }

  Widget _buildPlainText(TextStyle defaultStyle, List<TextSpan> spans) {
    return ClipRect(
      child: (widget.showEllipsisOverlay &&
              widget.inlineExpand &&
              !expanded &&
              showExpandButton)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(style: defaultStyle, children: spans),
                  maxLines: widget.maxLinesOverride ?? widget.collapsedMaxLines,
                  overflow: TextOverflow.clip,
                ),
                const SizedBox(height: 2),
                Text(
                  '…',
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontFamily: "MontserratBold",
                    color: Colors.black54,
                  ),
                ),
              ],
            )
          : RichText(
              text: TextSpan(style: defaultStyle, children: spans),
              maxLines: widget.maxLinesOverride ??
                  (widget.inlineExpand
                      ? (expanded ? null : widget.collapsedMaxLines)
                      : null),
              overflow: widget.overflowOverride ??
                  (widget.inlineExpand
                      ? (expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis)
                      : TextOverflow.visible),
            ),
    );
  }
}
