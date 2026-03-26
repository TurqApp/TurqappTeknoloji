part of 'top_tags_repository_parts.dart';

TopTagsRepository? maybeFindTopTagsRepository() {
  final isRegistered = Get.isRegistered<TopTagsRepository>();
  if (!isRegistered) return null;
  return Get.find<TopTagsRepository>();
}

TopTagsRepository ensureTopTagsRepository() {
  final existing = maybeFindTopTagsRepository();
  if (existing != null) return existing;
  return Get.put(TopTagsRepository(), permanent: true);
}
