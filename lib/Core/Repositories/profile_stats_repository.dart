import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';

class _CachedProfileStats {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  const _CachedProfileStats({
    required this.data,
    required this.cachedAt,
  });
}

class ProfileStatsRepository extends GetxService {
  static const Duration _ttl = Duration(minutes: 20);
  static const String _prefsPrefix = 'profile_stats_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedProfileStats> _memory = {};
  final FollowRepository _followRepository = FollowRepository.ensure();

  static ProfileStatsRepository? maybeFind() {
    if (!Get.isRegistered<ProfileStatsRepository>()) return null;
    return Get.find<ProfileStatsRepository>();
  }

  static ProfileStatsRepository _ensureService() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileStatsRepository(), permanent: true);
  }

  static ProfileStatsRepository ensure() {
    return _ensureService();
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<Map<String, dynamic>?> getStats(
    String uid, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (uid.isEmpty) return null;
    final key = _cacheKey(uid);

    if (preferCache) {
      final memory = _getFromMemory(key);
      if (memory != null) return memory;
      final disk = await _getFromPrefsEntry(key);
      if (disk != null) {
        _memory[key] = _CachedProfileStats(
          data: Map<String, dynamic>.from(disk.data),
          cachedAt: disk.cachedAt,
        );
        return Map<String, dynamic>.from(disk.data);
      }
    }

    if (cacheOnly) return null;

    return null;
  }

  Future<void> setStats(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    final key = _cacheKey(uid);
    final cachedAt = DateTime.now();
    final cloned = Map<String, dynamic>.from(data);
    _memory[key] = _CachedProfileStats(
      data: cloned,
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(key),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'd': cloned,
      }),
    );
  }

  Future<void> invalidate(String uid) async {
    if (uid.isEmpty) return;
    final key = _cacheKey(uid);
    _memory.remove(key);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(key));
  }

  Map<String, dynamic>? _getFromMemory(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _ttl) return null;
    return Map<String, dynamic>.from(entry.data);
  }

  Future<_CachedProfileStats?> _getFromPrefsEntry(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final data = (decoded['d'] as Map?)?.cast<String, dynamic>();
      if (ts <= 0 || data == null) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      return _CachedProfileStats(
        data: Map<String, dynamic>.from(data),
        cachedAt: cachedAt,
      );
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(String uid) => 'stats:$uid';

  String _prefsKey(String key) => '$_prefsPrefix:$key';

  Future<Map<String, int>> fetchFollowerGrowth(String uid) async {
    if (uid.isEmpty) {
      return const <String, int>{
        'followerGrowth30d': 0,
        'followerGrowthPrev30d': 0,
      };
    }
    final now = DateTime.now();
    final tsNow = now.millisecondsSinceEpoch;
    final ts30 = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final ts60 = now.subtract(const Duration(days: 60)).millisecondsSinceEpoch;

    final last30Count = await _followRepository.countFollowersInRange(
      uid,
      fromInclusive: ts30,
      toInclusive: tsNow,
    );
    final prev30Count = await _followRepository.countFollowersInRange(
      uid,
      fromInclusive: ts60,
      toExclusive: ts30,
    );

    return <String, int>{
      'followerGrowth30d': last30Count,
      'followerGrowthPrev30d': prev30Count,
    };
  }

  Future<Map<String, int>> fetchPostStats(String uid) async {
    if (uid.isEmpty) {
      return const <String, int>{
        'totalPosts': 0,
        'posts30d': 0,
        'totalPostViews': 0,
        'postViews30d': 0,
      };
    }

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final ts30 = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;

    final postsSnap = await FirebaseFirestore.instance
        .collection('Posts')
        .where('userID', isEqualTo: uid)
        .get();
    final postDocs = postsSnap.docs.where((d) {
      final data = d.data();
      final arsiv = data['arsiv'] == true;
      final deleted = data['deletedPost'] == true;
      final ts = data['timeStamp'];
      final tsOk = ts is int ? ts <= nowMs : true;
      return !arsiv && !deleted && tsOk;
    }).toList(growable: false);

    var posts30d = 0;
    for (final d in postDocs) {
      final t = d.data()['timeStamp'];
      if (t is int && t >= ts30 && t <= nowMs) posts30d++;
    }

    var totalPostViews = 0;
    var postViews30d = 0;
    for (final d in postDocs) {
      final data = d.data();
      final viewCount = _extractPostViewCount(data);
      totalPostViews += viewCount;

      final ts = data['timeStamp'];
      if (ts is int && ts >= ts30 && ts <= nowMs) {
        postViews30d += viewCount;
      }
    }

    return <String, int>{
      'totalPosts': postDocs.length,
      'posts30d': posts30d,
      'totalPostViews': totalPostViews,
      'postViews30d': postViews30d,
    };
  }

  Future<Map<String, int>> fetchStoryStats(String uid) async {
    if (uid.isEmpty) {
      return const <String, int>{
        'stories30d': 0,
        'profileVisitsApprox': 0,
        'totalStoryViews': 0,
      };
    }
    final now = DateTime.now();
    final ts30 = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final threshold = now.subtract(const Duration(days: 30));

    final storiesSnap = await FirebaseFirestore.instance
        .collection('stories')
        .where('userId', isEqualTo: uid)
        .get();

    final recentStories = storiesSnap.docs.where((d) {
      final data = d.data();
      final v = data['createdDate'];
      DateTime? created;
      if (v is int) {
        created = DateTime.fromMillisecondsSinceEpoch(v);
      } else if (v is Timestamp) {
        created = v.toDate();
      }
      return created != null && created.isAfter(threshold);
    }).toList(growable: false);

    var visits = 0;
    for (final d in recentStories) {
      try {
        final agg = await d.reference.collection('Viewers').count().get();
        visits += agg.count ?? 0;
      } catch (_) {}
    }

    try {
      final actualVisitsAgg = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('ProfileVisits')
          .where('timeStamp', isGreaterThanOrEqualTo: ts30)
          .count()
          .get();
      visits = actualVisitsAgg.count ?? 0;
    } catch (_) {}

    var totalStoryViews = 0;
    for (final d in storiesSnap.docs) {
      try {
        final agg = await d.reference.collection('Viewers').count().get();
        totalStoryViews += agg.count ?? 0;
      } catch (_) {}
    }

    return <String, int>{
      'stories30d': recentStories.length,
      'profileVisitsApprox': visits,
      'totalStoryViews': totalStoryViews,
    };
  }

  int _extractPostViewCount(Map<String, dynamic> data) {
    final stats = data['stats'];
    if (stats is Map) {
      final raw = stats['statsCount'];
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? 0;
    }
    final direct = data['viewCount'];
    if (direct is num) return direct.toInt();
    if (direct is String) return int.tryParse(direct) ?? 0;
    return 0;
  }
}
