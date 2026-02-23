import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class MyStatisticController extends GetxController {
  final isLoading = true.obs;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  // Core stats
  final totalPostViews = 0.obs;
  final totalStoryViews = 0.obs;
  final totalPosts = 0.obs;
  final followerCount = 0.obs;
  // 30-day stats
  final postViews30d = 0.obs;
  final posts30d = 0.obs;
  final stories30d = 0.obs;

  // Growth metrics (last 30 days)
  final followerGrowth30d = 0.obs;
  final followerGrowthPrev30d = 0.obs;
  final followerGrowthPct = 0.0.obs; // percent vs previous period

  // Post view rate vs followers (avg views per post / followers)
  final postViewRatePct = 0.0.obs;

  // Approx profile visits (story views in last 30d)
  final profileVisitsApprox = 0.obs;

  // Controls
  final int postBatchSize = 20; // progressive aggregation

  @override
  void onInit() {
    super.onInit();
    _loadAll();
    _bindUserDocCounters();
  }

  @override
  Future<void> refresh() async {
    await _loadAll();
  }

  @override
  void onClose() {
    _userDocSub?.cancel();
    super.onClose();
  }

  void _bindUserDocCounters() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      try {
        totalPosts.value = (doc.data()?['counterOfPosts'] ?? 0) as int;
        followerCount.value = (doc.data()?['counterOfFollowers'] ?? 0) as int;
      } catch (_) {}
    });
  }

  Future<void> _loadAll() async {
    isLoading.value = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _reset();
        return;
      }
      await Future.wait([
        _loadFollowerCounts(uid),
        _loadPostCountsAndViews(uid),
        _loadStoryViewsAndVisits(uid),
      ]);
      _computeDerived();
    } catch (e) {
      // Keep partial results; just log
      print('MyStatisticController load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _reset() {
    totalPostViews.value = 0;
    totalStoryViews.value = 0;
    totalPosts.value = 0;
    followerCount.value = 0;
    postViews30d.value = 0;
    posts30d.value = 0;
    stories30d.value = 0;
    followerGrowth30d.value = 0;
    followerGrowthPrev30d.value = 0;
    followerGrowthPct.value = 0.0;
    postViewRatePct.value = 0.0;
    profileVisitsApprox.value = 0;
  }

  Future<void> _loadFollowerCounts(String uid) async {
    try {
      final now = DateTime.now();
      final tsNow = Timestamp.fromDate(now);
      final ts30 = Timestamp.fromDate(now.subtract(const Duration(days: 30)));
      final ts60 = Timestamp.fromDate(now.subtract(const Duration(days: 60)));

      // Total followers
      final totalAgg = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Takipciler')
          .count()
          .get();
      followerCount.value = totalAgg.count ?? 0;

      // Growth last 30 days (requires timestamp on follower docs)
      final last30Agg = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Takipciler')
          .where('timeStamp', isGreaterThanOrEqualTo: ts30)
          .where('timeStamp', isLessThanOrEqualTo: tsNow)
          .count()
          .get();
      followerGrowth30d.value = last30Agg.count ?? 0;

      final prev30Agg = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Takipciler')
          .where('timeStamp', isGreaterThanOrEqualTo: ts60)
          .where('timeStamp', isLessThan: ts30)
          .count()
          .get();
      followerGrowthPrev30d.value = prev30Agg.count ?? 0;
    } catch (e) {
      print('Follower counts error: $e');
      // still show what we have
    }
  }

  Future<void> _loadPostCountsAndViews(String uid) async {
    try {
      // Count posts (visible, not deleted/archived)
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;
      final ts30 = Timestamp.fromDate(now.subtract(const Duration(days: 30)));

      final postsSnap = await FirebaseFirestore.instance
          .collection('Posts')
          .where('userID', isEqualTo: uid)
          .get();
      // In-memory filter to avoid index issues and tolerate missing fields
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> postDocs =
          postsSnap.docs.where((d) {
        final data = d.data();
        final arsiv = data['arsiv'] == true;
        final deleted = data['deletedPost'] == true;
        final ts = data['timeStamp'];
        final tsOk = ts is int ? ts <= nowMs : true;
        return !arsiv && !deleted && tsOk;
      }).toList();
      totalPosts.value = postDocs.length;

      // Posts created in last 30 days (filter in-memory to tolerate missing fields)
      try {
        final startMs = ts30.millisecondsSinceEpoch;
        int recent = 0;
        for (final d in postDocs) {
          final t = d.data()['timeStamp'];
          if (t is int && t >= startMs && t <= nowMs) recent++;
        }
        posts30d.value = recent;
      } catch (e) {
        posts30d.value = 0;
      }

      // Progressive sum of views across user posts
      int sum = 0;
      int sum30 = 0;
      // Process in small batches to avoid overwhelming Firestore
      for (int i = 0; i < postDocs.length; i += postBatchSize) {
        final batch =
            postDocs.sublist(i, (i + postBatchSize).clamp(0, postDocs.length));
        final Iterable<Future<int>> futures = batch.map((d) async {
          try {
            final agg = await d.reference.collection('viewers').count().get();
            return agg.count ?? 0;
          } catch (e) {
            // Fallback: manual count (bounded)
            try {
              final snap = await d.reference
                  .collection('viewers')
                  .limit(10000)
                  .get();
              return snap.size;
            } catch (_) {
              return 0;
            }
          }
        });
        final List<int> partial = await Future.wait<int>(futures);
        sum += partial.fold<int>(0, (a, b) => a + b);
        totalPostViews.value = sum; // update progressively

        // 30-day views for the same batch
        final Iterable<Future<int>> futures30 = batch.map((d) async {
          try {
            final agg = await d.reference
                .collection('viewers')
                .where('timeStamp', isGreaterThanOrEqualTo: ts30.millisecondsSinceEpoch)
                .count()
                .get();
            return agg.count ?? 0;
          } catch (e) {
            // Fallback: manual get
            try {
              final snap = await d.reference
                  .collection('viewers')
                  .where('timeStamp', isGreaterThanOrEqualTo: ts30.millisecondsSinceEpoch)
                  .limit(10000)
                  .get();
              return snap.size;
            } catch (_) {
              return 0;
            }
          }
        });
        final List<int> partial30 = await Future.wait<int>(futures30);
        sum30 += partial30.fold<int>(0, (a, b) => a + b);
        postViews30d.value = sum30;
      }
    } catch (e) {
      print('Post counts/views error: $e');
    }
  }

  Future<void> _loadStoryViewsAndVisits(String uid) async {
    try {
      // Last 30 days stories (approx profile visits)
      final now = DateTime.now();
      final ts30 = Timestamp.fromDate(now.subtract(const Duration(days: 30)));

      final storiesSnap = await FirebaseFirestore.instance
          .collection('stories')
          .where('userId', isEqualTo: uid)
          .get();

      // Filter in-memory to tolerate createdAt as int or Timestamp
      final nowDt = DateTime.now();
      final threshold = nowDt.subtract(const Duration(days: 30));
      final recentStories = storiesSnap.docs.where((d) {
        final data = d.data();
        final v = data['createdAt'];
        DateTime created;
        if (v is int) {
          created = DateTime.fromMillisecondsSinceEpoch(v);
        } else if (v is Timestamp) {
          created = v.toDate();
        } else {
          return false;
        }
        return created.isAfter(threshold);
      }).toList();

      stories30d.value = recentStories.length;
      int visits = 0;
      for (final d in recentStories) {
        try {
          final agg = await d.reference.collection('Viewers').count().get();
          visits += agg.count ?? 0;
        } catch (_) {}
      }
      // Replace approximate with actual profile visits if available
      try {
        final actualVisitsAgg = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('ProfileVisits')
            .where('timeStamp', isGreaterThanOrEqualTo: ts30.millisecondsSinceEpoch)
            .count()
            .get();
        profileVisitsApprox.value = actualVisitsAgg.count ?? 0;
      } catch (_) {
        profileVisitsApprox.value = visits; // fallback to story-based approx
      }

      // Total story views lifetime (optional)
      final storiesAllSnap = await FirebaseFirestore.instance
          .collection('stories')
          .where('userId', isEqualTo: uid)
          .get();
      int totalStory = 0;
      for (final d in storiesAllSnap.docs) {
        try {
          final agg = await d.reference.collection('Viewers').count().get();
          totalStory += agg.count ?? 0;
        } catch (_) {}
      }
      totalStoryViews.value = totalStory;
    } catch (e) {
      print('Story views error: $e');
    }
  }

  void _computeDerived() {
    // Follower growth percent vs previous 30 days
    final prev = followerGrowthPrev30d.value;
    final curr = followerGrowth30d.value;
    if (prev > 0) {
      followerGrowthPct.value = ((curr - prev) / prev) * 100.0;
    } else {
      followerGrowthPct.value = curr > 0 ? 100.0 : 0.0;
    }

    // Post view rate: avg views per post relative to followers
    final posts = totalPosts.value;
    final followers = followerCount.value;
    if (posts > 0 && followers > 0) {
      final avgViews = totalPostViews.value / posts;
      final pct = (avgViews / followers) * 100.0;
      postViewRatePct.value = pct.clamp(0.0, 9999.0);
    } else {
      postViewRatePct.value = 0.0;
    }
  }
}
