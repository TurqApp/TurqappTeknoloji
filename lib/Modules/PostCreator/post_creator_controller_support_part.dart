part of 'post_creator_controller.dart';

int get _maxVideoBytesForStorageRule =>
    UploadValidationService.currentMaxVideoSizeBytes;
const int _maxScheduledWindowDays = 90;
int _lastModerationSnackbarAtMs = 0;

final PostRepository _postRepository = PostRepository.ensure();
final agendaController = AgendaController.ensure();
final ErrorHandlingService _errorService = ErrorHandlingService.ensure();
final NetworkAwarenessService _networkService =
    NetworkAwarenessService.ensure();
final UploadQueueService _uploadQueueService = UploadQueueService.ensure();
final DraftService _draftService = DraftService.ensure();

String get _currentUid => CurrentUserService.instance.effectiveUserId;

extension PostCreatorControllerSupportPart on PostCreatorController {
  DateTime get maxIzBirakDate =>
      DateTime.now().add(const Duration(days: _maxScheduledWindowDays));

  Future<void> prepareForRoute({
    required String routeId,
    required bool sharedAsPost,
    required bool editMode,
  }) =>
      _PostCreatorControllerRouteX(this)._prepareForRoute(
        routeId: routeId,
        sharedAsPost: sharedAsPost,
        editMode: editMode,
      );

  Future<void> resetComposerState() =>
      _PostCreatorControllerRouteX(this)._resetComposerState();

  void uploadAllPostsInBackground() =>
      _PostCreatorControllerUiX(this)._uploadAllPostsInBackground();

  Future<void> showCommentOptions() =>
      _PostCreatorControllerUiX(this)._showCommentOptions();
}
