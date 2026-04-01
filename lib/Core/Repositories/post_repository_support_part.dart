part of 'post_repository.dart';

const Duration _postRepositoryInteractionTtl = Duration(seconds: 30);
const Duration _postRepositoryStuckUploadingRepairAge = Duration(seconds: 10);
final Set<String> _postRepositoryUploadRepairInFlight = <String>{};

FirebaseFirestore _resolvePostRepositoryFirestore(
  FirebaseFirestore? firestore,
) =>
    firestore ?? FirebaseFirestore.instance;

FirebaseAuth _resolvePostRepositoryAuth(FirebaseAuth? auth) =>
    auth ?? FirebaseAuth.instance;

PostInteractionService _resolvePostRepositoryInteractionService(
  PostInteractionService? interactionService,
) =>
    interactionService ?? ensurePostInteractionService();

PostCountManager _resolvePostRepositoryCountManager(
  PostCountManager? countManager,
) =>
    countManager ?? PostCountManager.instance;

PostRepository? _maybeFindPostRepository() {
  final isRegistered = Get.isRegistered<PostRepository>();
  if (!isRegistered) return null;
  return Get.find<PostRepository>();
}

PostRepository _ensurePostRepository() {
  final existing = _maybeFindPostRepository();
  if (existing != null) return existing;
  return Get.put(PostRepository(), permanent: true);
}

bool _shouldLogPostRepositoryDiagnostics() =>
    kDebugMode && !IntegrationTestMode.enabled;

extension PostRepositorySupportPart on PostRepository {
  bool get _shouldLogDiagnostics => _shouldLogPostRepositoryDiagnostics();

  void _bindInvalidationEvents() {
    _invalidationSubscription ??= CacheInvalidationService.ensure()
        .watchType(CacheInvalidationEventType.postInteractionRollback)
        .listen(_applyPostInteractionRollbackEvent);
  }

  void _disposeInvalidationEvents() {
    _invalidationSubscription?.cancel();
    _invalidationSubscription = null;
  }

  void _seedCounts(PostRepositoryState state, PostsModel model) =>
      _performSeedCounts(state, model);

  bool _isRenderableCard(PostsModel model) => _performIsRenderableCard(model);

  PostsModel _normalizeLikelyCompletedOwnPost(PostsModel model) =>
      _performNormalizeLikelyCompletedOwnPost(model);

  bool _shouldRepairStuckUploading(PostsModel model) =>
      _performShouldRepairStuckUploading(model);

  Future<void> _repairStuckUploadingPost(PostsModel model) =>
      _performRepairStuckUploadingPost(model);

  Map<String, dynamic> _typesenseDocToPostMap(
    Map<String, dynamic> doc,
    String docId,
  ) =>
      _performTypesenseDocToPostMap(doc, docId);

  void _startPostStream(PostRepositoryState state) =>
      _performStartPostStream(state);

  void _startCommentsMembershipStream(PostRepositoryState state) =>
      _performStartCommentsMembershipStream(state);

  Future<void> _ensureInteraction(
    PostRepositoryState state, {
    bool forceRefresh = false,
  }) =>
      _performEnsureInteraction(state, forceRefresh: forceRefresh);

  void _applyCountDelta({
    required String postId,
    required bool from,
    required bool to,
    required RxInt countRx,
    required num Function() readStat,
    required void Function(num value) writeStat,
  }) =>
      _performApplyCountDelta(
        postId: postId,
        from: from,
        to: to,
        countRx: countRx,
        readStat: readStat,
        writeStat: writeStat,
      );
}
