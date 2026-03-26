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
            interactionService ?? PostInteractionService.ensure(),
        _countManager = countManager ?? PostCountManager.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PostInteractionService _interactionService;
  final PostCountManager _countManager;
  final TypesensePostService _typesensePostService =
      TypesensePostService.instance;
  final Map<String, PostRepositoryState> _states =
      <String, PostRepositoryState>{};
  final Map<String, List<PostSharersModel>> _postSharersMemory =
      <String, List<PostSharersModel>>{};
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  static PostRepository? maybeFind() => _maybeFindPostRepository();

  static PostRepository ensure() => _ensurePostRepository();
}
