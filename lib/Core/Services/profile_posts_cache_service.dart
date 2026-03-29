import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_cache_policy.dart';
import 'package:turqappv2/Models/posts_model.dart';

class ProfilePostsCacheService {
  static const String _keyPrefix = 'profile_posts_cache_v2';
  static const int _maxItemsPerBucket = 250;

  Duration get _ttl =>
      MetadataCachePolicy.ttlFor(MetadataCacheBucket.profilePostsBucket);

  SharedPreferences? _prefs;

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(value.trim());
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

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
    final key = _bucketKey(uid, bucket);
    try {
      final prefs = await _prefsInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return const <PostsModel>[];

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await prefs.remove(key);
        return const <PostsModel>[];
      }

      final fetchedAtMs = _asInt(decoded['fetchedAt']);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (fetchedAtMs <= 0 || (nowMs - fetchedAtMs) > _ttl.inMilliseconds) {
        await prefs.remove(key);
        return const <PostsModel>[];
      }

      final items = decoded['items'];
      if (items is! List) {
        await prefs.remove(key);
        return const <PostsModel>[];
      }

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
              _cloneProfilePostPayloadMap(
                Map<String, dynamic>.from(data.cast<String, dynamic>()),
              ),
              docId,
            ),
          );
        } catch (_) {}
      }
      if (out.isEmpty && items.isNotEmpty) {
        await prefs.remove(key);
      }
      return out;
    } catch (_) {
      try {
        final prefs = await _prefsInstance();
        await prefs.remove(key);
      } catch (_) {}
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
                'data': _cloneProfilePostPayloadMap(p.toMap()),
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
        if (decoded is! Map<String, dynamic>) {
          await prefs.remove(key);
          continue;
        }
        final items = decoded['items'];
        if (items is! List) {
          await prefs.remove(key);
          continue;
        }

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

  Map<String, dynamic> _cloneProfilePostPayloadMap(
    Map<String, dynamic> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, _cloneProfilePostPayloadValue(value)),
    );
  }

  dynamic _cloneProfilePostPayloadValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneProfilePostPayloadValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneProfilePostPayloadValue).toList(growable: false);
    }
    return value;
  }
}
