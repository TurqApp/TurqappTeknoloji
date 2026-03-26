part of 'iz_birak_subscription_service.dart';

IzBirakSubscriptionService? _maybeFindIzBirakSubscriptionService() {
  final isRegistered = Get.isRegistered<IzBirakSubscriptionService>();
  if (!isRegistered) return null;
  return Get.find<IzBirakSubscriptionService>();
}

IzBirakSubscriptionService _ensureIzBirakSubscriptionService() {
  final existing = _maybeFindIzBirakSubscriptionService();
  if (existing != null) return existing;
  return Get.put(IzBirakSubscriptionService(), permanent: true);
}

bool _isIzBirakSubscribed(
  IzBirakSubscriptionService service,
  String postId,
) {
  final normalized = postId.trim();
  if (normalized.isEmpty) return false;
  if (!service.subscribedPostIds.contains(normalized)) {
    unawaited(_hydrateIzBirakSubscription(service, normalized));
  }
  return service.subscribedPostIds.contains(normalized);
}

Future<bool> _subscribeToIzBirakPost(
  IzBirakSubscriptionService service,
  String postId,
) async {
  final uid = CurrentUserService.instance.effectiveUserId;
  final normalizedPostId = postId.trim();
  if (uid.isEmpty || normalizedPostId.isEmpty) return false;
  if (service.subscribedPostIds.contains(normalizedPostId)) return true;
  if (service._loadingPostIds.contains(normalizedPostId)) return true;

  service._loadingPostIds.add(normalizedPostId);
  service.subscribedPostIds.add(normalizedPostId);
  try {
    await service._firestore
        .collection('Posts')
        .doc(normalizedPostId)
        .collection('izBirakSubscribers')
        .doc(uid)
        .set({
      'userID': uid,
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
    });
    return true;
  } catch (_) {
    service.subscribedPostIds.remove(normalizedPostId);
    return false;
  } finally {
    service._loadingPostIds.remove(normalizedPostId);
  }
}

Future<void> _hydrateIzBirakSubscription(
  IzBirakSubscriptionService service,
  String postId,
) async {
  final uid = CurrentUserService.instance.effectiveUserId;
  if (uid.isEmpty ||
      postId.isEmpty ||
      service._loadingPostIds.contains(postId)) {
    return;
  }
  service._loadingPostIds.add(postId);
  try {
    final doc = await service._firestore
        .collection('Posts')
        .doc(postId)
        .collection('izBirakSubscribers')
        .doc(uid)
        .get();
    if (doc.exists) {
      service.subscribedPostIds.add(postId);
    }
  } catch (_) {
  } finally {
    service._loadingPostIds.remove(postId);
  }
}
