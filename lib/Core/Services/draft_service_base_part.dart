part of 'draft_service_library.dart';

abstract class _DraftServiceBase extends GetxController {
  final _state = _DraftServiceState();

  @override
  void onInit() {
    super.onInit();
    _handleDraftServiceInit(this as DraftService);
  }

  @override
  void onClose() {
    _handleDraftServiceClose(this as DraftService);
    super.onClose();
  }
}
