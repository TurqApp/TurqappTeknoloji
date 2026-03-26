part of 'post_repository.dart';

abstract class _PostRepositoryBase extends GetxService {
  _PostRepositoryBase({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required PostInteractionService interactionService,
    required PostCountManager countManager,
  })  : _firestore = firestore,
        _auth = auth,
        _interactionService = interactionService,
        _countManager = countManager,
        _state = _PostRepositoryFieldsState();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PostInteractionService _interactionService;
  final PostCountManager _countManager;
  final _PostRepositoryFieldsState _state;
}
