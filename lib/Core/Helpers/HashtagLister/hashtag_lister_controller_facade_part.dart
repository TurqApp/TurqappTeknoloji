part of 'hashtag_lister_controller.dart';

HashtagListerController ensureHashtagListerController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindHashtagListerController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    HashtagListerController(),
    tag: tag,
    permanent: permanent,
  );
}

HashtagListerController? maybeFindHashtagListerController({String? tag}) {
  final isRegistered = Get.isRegistered<HashtagListerController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<HashtagListerController>(tag: tag);
}
