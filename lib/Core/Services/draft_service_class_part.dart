part of 'draft_service.dart';

class DraftService extends GetxController {
  final _state = _DraftServiceState();

  static const String _draftsKeyPrefix = 'post_drafts';
  static const String _autoSaveKey = 'auto_save_enabled';
  static const int _maxDrafts = 20;

  @override
  void onInit() {
    super.onInit();
    _handleDraftServiceInit(this);
  }

  @override
  void onClose() {
    _handleDraftServiceClose(this);
    super.onClose();
  }
}
