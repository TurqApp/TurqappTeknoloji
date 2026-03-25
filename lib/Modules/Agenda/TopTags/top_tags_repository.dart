import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'top_tags_repository_cache_part.dart';

class TopTagsRepository extends GetxService {
  final FirebaseFirestore _db;
  static const int _defaultTrendWindowHours = 24;
  static const int _defaultTrendThreshold = 1;
  static const Duration _ttl = Duration(hours: 1);
  static const String _prefsKey = 'top_tags_repository_v1';
  List<HashtagModel>? _memory;
  DateTime? _memoryAt;
  final List<PostsModel> _feedMemory = <PostsModel>[];
  DocumentSnapshot<Map<String, dynamic>>? _lastFeedDoc;
  SharedPreferences? _prefs;

  TopTagsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static TopTagsRepository? maybeFind() {
    final isRegistered = Get.isRegistered<TopTagsRepository>();
    if (!isRegistered) return null;
    return Get.find<TopTagsRepository>();
  }

  static TopTagsRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TopTagsRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<List<HashtagModel>> fetchTrendingTags({
    int resultLimit = 30,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && preferCache) {
      final memory = _readMemory(limit: resultLimit);
      if (memory != null) return memory;
      final disk = await _readPrefs(limit: resultLimit);
      if (disk != null) {
        _memory = disk;
        _memoryAt = DateTime.now();
        return disk;
      }
    }

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
    final result = list.take(resultLimit).toList(growable: false);
    await _store(result);
    return result;
  }

  Future<void> _store(List<HashtagModel> items) =>
      _TopTagsRepositoryCacheX(this)._store(items);

  List<HashtagModel>? _readMemory({required int limit}) =>
      _TopTagsRepositoryCacheX(this)._readMemory(limit: limit);

  Future<List<HashtagModel>?> _readPrefs({required int limit}) =>
      _TopTagsRepositoryCacheX(this)._readPrefs(limit: limit);

  int _resolveLastSeenActivityTs(int rawLastSeenTs, int windowMs, int nowMs) =>
      _TopTagsRepositoryCacheX(this)
          ._resolveLastSeenActivityTs(rawLastSeenTs, windowMs, nowMs);

  Future<List<PostsModel>> fetchImagePostsPage({
    int limit = 15,
    bool reset = false,
  }) =>
      _TopTagsRepositoryCacheX(this).fetchImagePostsPage(
        limit: limit,
        reset: reset,
      );
}
