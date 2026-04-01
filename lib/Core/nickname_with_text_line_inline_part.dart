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
    return RichText(
      text: TextSpan(style: defaultStyle, children: spans),
      overflow: TextOverflow.visible,
    );
  }
}
