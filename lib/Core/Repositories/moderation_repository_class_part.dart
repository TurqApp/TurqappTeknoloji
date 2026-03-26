part of 'moderation_repository.dart';

class ModerationRepository extends GetxService {
  static ModerationRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ModerationRepository>();
    if (!isRegistered) return null;
    return Get.find<ModerationRepository>();
  }

  static ModerationRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ModerationRepository(), permanent: true);
  }

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
