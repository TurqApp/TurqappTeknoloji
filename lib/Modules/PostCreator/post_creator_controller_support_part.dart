part of 'post_creator_controller.dart';

int get _maxVideoBytesForStorageRule =>
    UploadValidationService.currentMaxVideoSizeBytes;
const int _maxScheduledWindowDays = 90;
int _lastModerationSnackbarAtMs = 0;

final PostRepository _postRepository = PostRepository.ensure();
final ProfileRepository _profileRepository = ensureProfileRepository();
final ProfilePostsSnapshotRepository _profileSnapshotRepository =
    ProfilePostsSnapshotRepository.ensure();
final agendaController = ensureAgendaController();
final ErrorHandlingService _errorService = ensureErrorHandlingService();
const NetworkRuntimeService _networkRuntimeService = NetworkRuntimeService();
const UploadQueueRuntimeService _uploadQueueRuntimeService =
    UploadQueueRuntimeService();
final DraftService _draftService = ensureDraftService();

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

  Future<void> persistUploadedPostsToHomeFeed(
    List<PostsModel> posts,
  ) async {
    final normalizedPosts = posts
        .where((post) => post.docID.trim().isNotEmpty)
        .toList(growable: false);
    if (normalizedPosts.isEmpty) return;

    final userId = _currentUid.trim();
    if (userId.isEmpty) return;

    final repository = ensureFeedSnapshotRepository();
    final snapshot = await repository.bootstrapHome(
      userId: userId,
      limit: 40,
    );
    final merged = <String, PostsModel>{
      for (final post in normalizedPosts) post.docID: post,
    };
    for (final existing in snapshot.data ?? const <PostsModel>[]) {
      merged.putIfAbsent(existing.docID, () => existing);
    }

    final ordered = merged.values.toList(growable: false)
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    await repository.persistHomeSnapshot(
      userId: userId,
      posts: ordered,
      limit: 40,
      source: CachedResourceSource.memory,
    );
  }
}
