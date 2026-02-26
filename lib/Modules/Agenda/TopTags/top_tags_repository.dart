import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Models/hashtag_model.dart';

class TopTagsRepository {
  final FirebaseFirestore _db;
  static const int _defaultTrendWindowHours = 24;
  static const int _defaultTrendThreshold = 1;

  TopTagsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<List<HashtagModel>> fetchTrendingTags({
    int resultLimit = 30,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final snap = await _db
        .collection("tags")
        .orderBy("count", descending: true)
        .limit(200)
        .get();

    final List<HashtagModel> list = [];
    for (final doc in snap.docs) {
      final data = doc.data();
      final rawTag = doc.id.toString().trim();
      final tag = rawTag.replaceFirst("#", "");
      if (tag.isEmpty) continue;

      final count = ((data["count"] ?? data["counter"] ?? 0) as num).toInt();
      final threshold =
          ((data["trendThreshold"] ?? _defaultTrendThreshold) as num).toInt();
      if (count < threshold || count <= 0) continue;

      final windowHours =
          ((data["trendWindowHours"] ?? _defaultTrendWindowHours) as num)
              .toInt();
      final windowMs = Duration(
              hours: windowHours <= 0 ? _defaultTrendWindowHours : windowHours)
          .inMilliseconds;
      final rawLastSeenTs = ((data["lastSeenTs"] as num?)?.toInt()) ??
          ((data["lastSeenAt"] as num?)?.toInt()) ??
          0;
      final effectiveLastSeenTs =
          _resolveLastSeenActivityTs(rawLastSeenTs, windowMs, nowMs);
      if (effectiveLastSeenTs <= 0) continue;
      if ((nowMs - effectiveLastSeenTs) > windowMs) continue;

      list.add(
        HashtagModel(
          hashtag: tag,
          count: count,
          hasHashtag: rawTag.startsWith("#") ||
              (((data["hashtagCount"] ?? 0) as num) > 0),
          lastSeenTs: effectiveLastSeenTs,
        ),
      );
    }

    list.sort((a, b) {
      final countCmp = b.count.compareTo(a.count);
      if (countCmp != 0) return countCmp;
      return (b.lastSeenTs ?? 0).compareTo(a.lastSeenTs ?? 0);
    });
    return list.take(resultLimit).toList();
  }

  int _resolveLastSeenActivityTs(int rawLastSeenTs, int windowMs, int nowMs) {
    if (rawLastSeenTs <= 0) return 0;
    // Backward compatibility: older data stored "expiry time" (createdAt + window).
    // If timestamp is in the future, treat it as expiry and convert to activity time.
    if (rawLastSeenTs > nowMs) {
      final converted = rawLastSeenTs - windowMs;
      return converted > 0 ? converted : rawLastSeenTs;
    }
    return rawLastSeenTs;
  }
}
