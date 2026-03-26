part of 'draft_service_library.dart';

class DraftService extends _DraftServiceBase {
  static const String _draftsKeyPrefix = 'post_drafts';
  static const String _autoSaveKey = 'auto_save_enabled';
  static const int _maxDrafts = 20;
}
