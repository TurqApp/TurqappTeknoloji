import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Models/hashtag_model.dart';

class TopTagsRepository {
  final FirebaseFirestore _db;

  TopTagsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<List<HashtagModel>> fetchTrendingTags({
    int resultLimit = 30,
  }) async {
    final snap = await _db
        .collection("tags")
        .orderBy("count", descending: true)
        .limit(resultLimit)
        .get();

    final list = snap.docs
        .map((doc) {
          final data = doc.data();
          final rawTag = doc.id.toString().trim();
          return HashtagModel(
            hashtag: rawTag.replaceFirst("#", ""),
            count: ((data["count"] ?? data["counter"] ?? 0) as num),
            hasHashtag:
                rawTag.startsWith("#") || (((data["hashtagCount"] ?? 0) as num) > 0),
            lastSeenTs: ((data["lastSeenTs"] as num?)?.toInt()),
          );
        })
        .where((e) => e.hashtag.isNotEmpty && e.count > 0)
        .toList();
    return list;
  }
}
