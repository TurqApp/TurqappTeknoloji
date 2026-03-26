part of 'hashtag_text_post.dart';

HashtagTextVideoPostController ensureHashtagTextVideoPostController({
  required String text,
  String? nickname,
  required Color color,
  required void Function(bool) volume,
  String? tag,
  bool permanent = false,
}) =>
    _ensureHashtagTextVideoPostController(
      text: text,
      nickname: nickname,
      color: color,
      volume: volume,
      tag: tag,
      permanent: permanent,
    );
HashtagTextVideoPostController? maybeFindHashtagTextVideoPostController(
        {String? tag}) =>
    _maybeFindHashtagTextVideoPostController(tag: tag);
