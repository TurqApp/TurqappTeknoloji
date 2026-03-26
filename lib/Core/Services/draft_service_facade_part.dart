part of 'draft_service.dart';

extension DraftServiceFacadePart on DraftService {
  List<PostDraft> get drafts => _drafts;
  bool get autoSaveEnabled => _autoSaveEnabled.value;
  int get autoSaveInterval => _autoSaveInterval.value;
}
