part of 'post_repository.dart';

class PostRepository extends GetxService {
  PostRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PostInteractionService? interactionService,
    PostCountManager? countManager,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _interactionService =
            interactionService ?? ensurePostInteractionService(),
        _countManager = countManager ?? PostCountManager.instance,
        _state = _PostRepositoryFieldsState();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PostInteractionService _interactionService;
  final PostCountManager _countManager;
  final _PostRepositoryFieldsState _state;

  static PostRepository? maybeFind() => _maybeFindPostRepository();

  static PostRepository ensure() => _ensurePostRepository();
}
