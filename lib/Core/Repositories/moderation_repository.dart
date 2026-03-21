import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ModerationFlaggedPost {
  final String id;
  final Map<String, dynamic> data;

  const ModerationFlaggedPost({
    required this.id,
    required this.data,
  });
}

class ModerationRepository extends GetxService {
  static ModerationRepository _ensureService() {
    if (Get.isRegistered<ModerationRepository>()) {
      return Get.find<ModerationRepository>();
    }
    return Get.put(ModerationRepository(), permanent: true);
  }

  static ModerationRepository ensure() => _ensureService();

  Stream<List<ModerationFlaggedPost>> watchFlaggedPosts({
    required int threshold,
    int limit = 200,
  }) {
    final safeThreshold = threshold.clamp(1, 1000);
    return FirebaseFirestore.instance
        .collection('Posts')
        .where('moderation.flagCount', isGreaterThanOrEqualTo: safeThreshold)
        .orderBy('moderation.flagCount', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => ModerationFlaggedPost(
                  id: doc.id,
                  data: Map<String, dynamic>.from(doc.data()),
                ),
              )
              .toList(growable: false),
        );
  }
}
