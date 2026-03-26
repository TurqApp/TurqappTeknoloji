part of 'top_tags_contoller.dart';

TopTagsController ensureTopTagsController() => _ensureTopTagsController();

TopTagsController? maybeFindTopTagsController() =>
    _maybeFindTopTagsController();

TopTagsController _ensureTopTagsController() {
  final existing = _maybeFindTopTagsController();
  if (existing != null) return existing;
  return Get.put(TopTagsController());
}

TopTagsController? _maybeFindTopTagsController() {
  final isRegistered = Get.isRegistered<TopTagsController>();
  if (!isRegistered) return null;
  return Get.find<TopTagsController>();
}

extension TopTagsControllerFacadePart on TopTagsController {
  void resetFeedState() {
    hasMore = true;
    agendaList.clear();
    centeredIndex.value = -1;
    currentVisibleIndex.value = -1;
  }

  String agendaInstanceTag(String docId) => 'top_tag_$docId';

  GlobalKey getAgendaKey({required String docId}) {
    return _agendaKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey(agendaInstanceTag(docId)),
    );
  }
}
