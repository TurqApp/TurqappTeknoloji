part of 'post_repository.dart';

class PostRepository extends _PostRepositoryBase {
  PostRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PostInteractionService? interactionService,
    PostCountManager? countManager,
  }) : super(
          firestore: firestore ?? FirebaseFirestore.instance,
          auth: auth ?? FirebaseAuth.instance,
          interactionService:
              interactionService ?? ensurePostInteractionService(),
          countManager: countManager ?? PostCountManager.instance,
        );

  static PostRepository? maybeFind() => _maybeFindPostRepository();

  static PostRepository ensure() => _ensurePostRepository();
}
