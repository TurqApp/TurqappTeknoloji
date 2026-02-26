import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Models/hashtag_model.dart';

class TopTagsRepository {
  final FirebaseFirestore _db;
  static const Duration _window = Duration(hours: 24);

  TopTagsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<List<HashtagModel>> fetchTrendingTags({
    int resultLimit = 30,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = nowMs - _window.inMilliseconds;

    final snap = await _db
        .collection("tags")
        .orderBy("count", descending: true)
        .limit(200)
        .get();

    final list = snap.docs
        .map((doc) {
          final data = doc.data();
          final rawTag = doc.id.toString().trim();
          final lastSeenTs =
              ((data["lastSeenTs"] as num?)?.toInt()) ??
              ((data["lastSeenAt"] as num?)?.toInt()) ??
              0;
          return HashtagModel(
            hashtag: rawTag.replaceFirst("#", ""),
            count: ((data["count"] ?? data["counter"] ?? 0) as num),
            hasHashtag:
                rawTag.startsWith("#") || (((data["hashtagCount"] ?? 0) as num) > 0),
            lastSeenTs: lastSeenTs,
          );
        })
        .where((e) => e.hashtag.isNotEmpty && e.count > 0)
        .where((e) => (e.lastSeenTs ?? 0) >= cutoffMs)
        .toList()
      ..sort((a, b) {
        final countCmp = b.count.compareTo(a.count);
        if (countCmp != 0) return countCmp;
        return (b.lastSeenTs ?? 0).compareTo(a.lastSeenTs ?? 0);
      });
    return list.take(resultLimit).toList();
  }
}
