part of 'draft_service_library.dart';

void _handleDraftServiceInit(DraftService service) {
  service._loadDraftsFromStorage();
  service._loadSettings();
  service._authSub ??= FirebaseAuth.instance.authStateChanges().listen((_) {
    unawaited(service._loadDraftsFromStorage());
  });
}

void _handleDraftServiceClose(DraftService service) =>
    service._authSub?.cancel();
