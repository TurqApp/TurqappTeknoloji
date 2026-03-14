import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class IzBirakSubscriptionService extends GetxService {
  static IzBirakSubscriptionService ensure() {
    if (Get.isRegistered<IzBirakSubscriptionService>()) {
      return Get.find<IzBirakSubscriptionService>();
    }
    return Get.put(IzBirakSubscriptionService(), permanent: true);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxSet<String> subscribedPostIds = <String>{}.obs;
  final Set<String> _loadingPostIds = <String>{};

  bool isSubscribed(String postId) {
    final normalized = postId.trim();
    if (normalized.isEmpty) return false;
    if (!subscribedPostIds.contains(normalized)) {
      unawaited(_hydrateSubscription(normalized));
    }
    return subscribedPostIds.contains(normalized);
  }

  Future<bool> subscribe(String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final normalizedPostId = postId.trim();
    if (uid == null || normalizedPostId.isEmpty) return false;
    if (subscribedPostIds.contains(normalizedPostId)) return true;
    if (_loadingPostIds.contains(normalizedPostId)) return true;

    _loadingPostIds.add(normalizedPostId);
    subscribedPostIds.add(normalizedPostId);
    try {
      await _firestore
          .collection('Posts')
          .doc(normalizedPostId)
          .collection('izBirakSubscribers')
          .doc(uid)
          .set({
        'userID': uid,
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('[IzBirakSubscription] subscribe failed post=$normalizedPostId uid=$uid error=$e');
      subscribedPostIds.remove(normalizedPostId);
      return false;
    } finally {
      _loadingPostIds.remove(normalizedPostId);
    }
  }

  Future<void> _hydrateSubscription(String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || postId.isEmpty || _loadingPostIds.contains(postId)) {
      return;
    }
    _loadingPostIds.add(postId);
    try {
      final doc = await _firestore
          .collection('Posts')
          .doc(postId)
          .collection('izBirakSubscribers')
          .doc(uid)
          .get();
      if (doc.exists) {
        subscribedPostIds.add(postId);
      }
    } catch (_) {
    } finally {
      _loadingPostIds.remove(postId);
    }
  }
}
