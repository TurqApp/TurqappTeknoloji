part of 'short_content_controller.dart';

extension ShortContentControllerRuntimePart on ShortContentController {
  void _handleRuntimeInit() {
    _initializeStats();
    getGizleArsivSikayetEdildi();
    avatarUrl.value = model.authorAvatarUrl.trim();
    nickname.value = model.authorNickname.trim();
    fullName.value = model.authorDisplayName.trim();
    fetchUserData(model.userID);

    Future.microtask(() {
      if (isClosed) return;
      _shortInteractionService.recordView(model.docID);
      _loadUserInteractionStatus();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      _bindPostStatsListener();
    });
  }

  void _handleRuntimeClose() {
    _deleteFadeTimer?.cancel();
    _deleteRemoveTimer?.cancel();
    _interactionWorker?.dispose();
    _postDataWorker?.dispose();
    _shortPostRepository.releasePost(model.docID);
    _postDocSub?.cancel();
  }
}
