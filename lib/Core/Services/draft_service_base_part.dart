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

void _handleDraftServiceInit(DraftService service) {
  service._loadDraftsFromStorage();
  service._loadSettings();
  service._authSub ??= FirebaseAuth.instance.authStateChanges().listen((_) {
    unawaited(service._loadDraftsFromStorage());
  });
}

void _handleDraftServiceClose(DraftService service) =>
    service._authSub?.cancel();
