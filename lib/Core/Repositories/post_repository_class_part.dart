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
  static PostRepository? maybeFind() => _maybeFindPostRepository();
  static PostRepository ensure() => _ensurePostRepository();
}
