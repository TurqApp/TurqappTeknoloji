part of 'hashtag_text_post.dart';

extension HashtagTextVideoPostControllerFacadePart
    on HashtagTextVideoPostController {
  void _buildSpans() =>
      HashtagTextVideoPostControllerRuntimePart(this).buildSpans();

  void toggleExpand() {
    expanded.toggle();
    _buildSpans();
  }

  void checkOverflow(TextPainter tp) =>
      showExpandButton.value = tp.didExceedMaxLines;
}
