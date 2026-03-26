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

HashtagTextVideoPostController? maybeFindHashtagTextVideoPostController({
  String? tag,
}) =>
    _maybeFindHashtagTextVideoPostController(tag: tag);

HashtagTextVideoPostController _ensureHashtagTextVideoPostController({
  required String text,
  String? nickname,
  required Color color,
  required void Function(bool) volume,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindHashtagTextVideoPostController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    HashtagTextVideoPostController(
      text: text,
      nickname: nickname,
      color: color,
      volume: volume,
    ),
    tag: tag,
    permanent: permanent,
  );
}

HashtagTextVideoPostController? _maybeFindHashtagTextVideoPostController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<HashtagTextVideoPostController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<HashtagTextVideoPostController>(tag: tag);
}
