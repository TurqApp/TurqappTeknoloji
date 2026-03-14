import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_cache_policy.dart';
import 'package:turqappv2/Models/posts_model.dart';

class ProfilePostsCacheService {
  static const String _keyPrefix = 'profile_posts_cache_v1';
  static const int _maxItemsPerBucket = 250;

  Duration get _ttl =>
      MetadataCachePolicy.ttlFor(MetadataCacheBucket.profilePostsBucket);

  SharedPreferences? _prefs;

  Future<SharedPreferences> _prefsInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _bucketKey(String uid, String bucket) {
    return '$_keyPrefix::$uid::$bucket';
  }

  Future<List<PostsModel>> readBucket({
    required String uid,
    required String bucket,
  }) async {
    if (uid.isEmpty || bucket.isEmpty) return const <PostsModel>[];
    try {
      final prefs = await _prefsInstance();
      final raw = prefs.getString(_bucketKey(uid, bucket));
      if (raw == null || raw.trim().isEmpty) return const <PostsModel>[];

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const <PostsModel>[];

      final fetchedAtMs = (decoded['fetchedAt'] as num?)?.toInt() ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (fetchedAtMs <= 0 || (nowMs - fetchedAtMs) > _ttl.inMilliseconds) {
        return const <PostsModel>[];
      }

      final items = decoded['items'];
      if (items is! List) return const <PostsModel>[];

      final out = <PostsModel>[];
      for (final item in items) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final docId = (map['docID'] ?? '').toString().trim();
        final data = map['data'];
        if (docId.isEmpty || data is! Map) continue;
        try {
          out.add(
            PostsModel.fromMap(
              Map<String, dynamic>.from(data.cast<String, dynamic>()),
              docId,
            ),
          );
        } catch (_) {}
      }
      return out;
    } catch (_) {
      return const <PostsModel>[];
    }
  }

  Future<void> writeBucket({
    required String uid,
    required String bucket,
    required List<PostsModel> posts,
  }) async {
    if (uid.isEmpty || bucket.isEmpty) return;
    try {
      final prefs = await _prefsInstance();
      final capped = posts.take(_maxItemsPerBucket).toList(growable: false);
      final payload = <String, dynamic>{
        'fetchedAt': DateTime.now().millisecondsSinceEpoch,
        'items': capped
            .map(
              (p) => <String, dynamic>{
                'docID': p.docID,
                'data': p.toMap(),
              },
            )
            .toList(growable: false),
      };
      await prefs.setString(_bucketKey(uid, bucket), jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> clearUser(String uid) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await _prefsInstance();
      for (final bucket in const <String>[
        'all',
        'photos',
        'videos',
        'reshares',
        'scheduled',
      ]) {
        await prefs.remove(_bucketKey(uid, bucket));
      }
    } catch (_) {}
  }

  Future<void> removePost({
    required String uid,
    required String docId,
  }) async {
    if (uid.isEmpty || docId.isEmpty) return;
    try {
      final prefs = await _prefsInstance();
      for (final bucket in const <String>[
        'all',
        'photos',
        'videos',
        'reshares',
        'scheduled',
        'archive',
      ]) {
        final key = _bucketKey(uid, bucket);
        final raw = prefs.getString(key);
        if (raw == null || raw.trim().isEmpty) continue;

        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        final items = decoded['items'];
        if (items is! List) continue;

        final filtered = items.where((item) {
          if (item is! Map) return false;
          return (item['docID'] ?? '').toString().trim() != docId;
        }).toList(growable: false);

        if (filtered.length == items.length) continue;

        if (filtered.isEmpty) {
          await prefs.remove(key);
          continue;
        }

        decoded['items'] = filtered;
        await prefs.setString(key, jsonEncode(decoded));
      }
    } catch (_) {}
  }
}
