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

  Future<void> subscribe(String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final normalizedPostId = postId.trim();
    if (uid == null || normalizedPostId.isEmpty) return;

    await _firestore
        .collection('Posts')
        .doc(normalizedPostId)
        .collection('izBirakSubscribers')
        .doc(uid)
        .set({
      'userID': uid,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
}
