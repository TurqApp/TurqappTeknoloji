part of 'post_interaction_service.dart';

class PostInteractionService extends GetxController {
  PostInteractionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? AppFirestore.instance;

  final FirebaseFirestore _firestore;
  final UserSubcollectionRepository _userSubcollectionRepository =
      ensureUserSubcollectionRepository();
  final Map<String, _InteractionCacheEntry> _interactionStatusCache = {};
  final Set<String> _reportedByMe = <String>{};
  bool _permissionDeniedLogged = false;
  StreamSubscription<CacheInvalidationEvent>? _invalidationSubscription;

  @override
  void onInit() {
    super.onInit();
    _invalidationSubscription = CacheInvalidationService.ensure()
        .watchType(CacheInvalidationEventType.postInteractionRollback)
        .listen(_applyPostInteractionRollbackEvent);
  }

  @override
  void onClose() {
    _invalidationSubscription?.cancel();
    super.onClose();
  }
}

PostInteractionService? maybeFindPostInteractionService() {
  final isRegistered = Get.isRegistered<PostInteractionService>();
  if (!isRegistered) return null;
  return Get.find<PostInteractionService>();
}

PostInteractionService ensurePostInteractionService() {
  final existing = maybeFindPostInteractionService();
  if (existing != null) return existing;
  return Get.put(PostInteractionService());
}
