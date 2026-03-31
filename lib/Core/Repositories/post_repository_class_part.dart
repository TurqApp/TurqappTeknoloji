part of 'post_repository.dart';

class PostRepository extends _PostRepositoryBase {
  PostRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PostInteractionService? interactionService,
    PostCountManager? countManager,
  }) : super(
          firestore: _resolvePostRepositoryFirestore(firestore),
          auth: _resolvePostRepositoryAuth(auth),
          interactionService:
              _resolvePostRepositoryInteractionService(interactionService),
          countManager: _resolvePostRepositoryCountManager(countManager),
        );

  @override
  void onInit() {
    super.onInit();
    _bindInvalidationEvents();
  }

  @override
  void onClose() {
    _disposeInvalidationEvents();
    super.onClose();
  }

  static PostRepository? maybeFind() => _maybeFindPostRepository();
  static PostRepository ensure() => _ensurePostRepository();
}
