import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Models/posts_model.dart';

class TopTagsRepository extends GetxService {
  final FirebaseFirestore _db;
  static const int _defaultTrendWindowHours = 24;
  static const int _defaultTrendThreshold = 1;
  static const Duration _ttl = Duration(minutes: 30);
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

  Future<void> _store(List<HashtagModel> items) async {
    _memory = items.toList(growable: false);
    _memoryAt = DateTime.now();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey,
      jsonEncode({
        't': _memoryAt!.millisecondsSinceEpoch,
        'items': items
            .map((item) => <String, dynamic>{
                  'hashtag': item.hashtag,
                  'count': item.count,
                  'hasHashtag': item.hasHashtag,
                  'lastSeenTs': item.lastSeenTs,
                })
            .toList(growable: false),
      }),
    );
  }

  List<HashtagModel>? _readMemory({required int limit}) {
    final items = _memory;
    final at = _memoryAt;
    if (items == null || at == null) return null;
    if (DateTime.now().difference(at) > _ttl) return null;
    return items.take(limit).toList(growable: false);
  }

  Future<List<HashtagModel>?> _readPrefs({required int limit}) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      final items = (decoded['items'] as List?) ?? const [];
      return items
          .map((e) => e as Map)
          .map(
            (e) => HashtagModel(
              hashtag: (e['hashtag'] ?? '').toString(),
              count: ((e['count'] ?? 0) as num).toInt(),
              hasHashtag: e['hasHashtag'] == true,
              lastSeenTs: ((e['lastSeenTs'] ?? 0) as num?)?.toInt(),
            ),
          )
          .take(limit)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
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

  Future<List<PostsModel>> fetchImagePostsPage({
    int limit = 15,
    bool reset = false,
  }) async {
    if (reset) {
      _feedMemory.clear();
      _lastFeedDoc = null;
    }

    Query<Map<String, dynamic>> query = _db
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('img', isNotEqualTo: [])
        .where('flood', isEqualTo: false)
        .orderBy('timeStamp', descending: true)
        .limit(limit);

    if (_lastFeedDoc != null) {
      query = query.startAfterDocument(_lastFeedDoc!);
    }

    final snap = await query.get();
    if (snap.docs.isNotEmpty) {
      _lastFeedDoc = snap.docs.last;
      for (final doc in snap.docs) {
        final model = PostsModel.fromFirestore(doc);
        if (model.deletedPost == true) continue;
        _feedMemory.add(model);
      }
    }
    return List<PostsModel>.from(_feedMemory);
  }
}
