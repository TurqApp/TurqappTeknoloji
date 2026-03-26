part of 'post_interaction_service.dart';

class PostInteractionService extends GetxController {
  PostInteractionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final UserSubcollectionRepository _userSubcollectionRepository =
      ensureUserSubcollectionRepository();

  static const Duration _cacheTTL = Duration(seconds: 30);
  final Map<String, _InteractionCacheEntry> _interactionStatusCache = {};
  final Set<String> _reportedByMe = <String>{};
  bool _permissionDeniedLogged = false;
  static const String _moderationConfigPath = 'adminConfig/moderation';
}
