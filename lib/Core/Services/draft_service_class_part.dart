part of 'draft_service.dart';

class DraftService extends GetxController {
  static DraftService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(DraftService());
  }

  static DraftService? maybeFind() {
    final isRegistered = Get.isRegistered<DraftService>();
    if (!isRegistered) return null;
    return Get.find<DraftService>();
  }

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
