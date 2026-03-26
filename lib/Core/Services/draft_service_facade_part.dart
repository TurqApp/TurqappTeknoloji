part of 'draft_service_library.dart';

DraftService ensureDraftService() {
  final existing = maybeFindDraftService();
  if (existing != null) return existing;
  return Get.put(DraftService());
}

DraftService? maybeFindDraftService() {
  final isRegistered = Get.isRegistered<DraftService>();
  if (!isRegistered) return null;
  return Get.find<DraftService>();
}

extension DraftServiceFacadePart on DraftService {
  List<PostDraft> get drafts => _drafts;
  bool get autoSaveEnabled => _autoSaveEnabled.value;
  int get autoSaveInterval => _autoSaveInterval.value;
}
