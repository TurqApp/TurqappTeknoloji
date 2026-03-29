part of 'profile_stats_repository.dart';

extension ProfileStatsRepositoryMetricsPart on ProfileStatsRepository {
  bool _asProfileStatsBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = (value ?? '').toString().trim().toLowerCase();
    return raw == 'true' || raw == '1';
  }

  int _asProfileStatsInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

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
      final arsiv = _asProfileStatsBool(data['arsiv']);
      final deleted = _asProfileStatsBool(data['deletedPost']);
      final ts = _asProfileStatsInt(data['timeStamp']);
      final tsOk = ts <= 0 || ts <= nowMs;
      return !arsiv && !deleted && tsOk;
    }).toList(growable: false);

    var posts30d = 0;
    for (final d in postDocs) {
      final t = _asProfileStatsInt(d.data()['timeStamp']);
      if (t >= ts30 && t <= nowMs) posts30d++;
    }

    var totalPostViews = 0;
    var postViews30d = 0;
    for (final d in postDocs) {
      final data = d.data();
      final viewCount = _extractPostViewCount(data);
      totalPostViews += viewCount;

      final ts = _asProfileStatsInt(data['timeStamp']);
      if (ts >= ts30 && ts <= nowMs) {
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
