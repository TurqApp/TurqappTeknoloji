import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/startup_surface_order_service.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Models/posts_model.dart';

enum ShortMixBucket {
  fresh,
  warm,
  rescue,
}

class _ShortPresentationSignal {
  const _ShortPresentationSignal({
    required this.activelyDownloading,
    required this.readinessTier,
    required this.queuePosition,
    required this.cachedSegments,
  });

  final bool activelyDownloading;
  final int readinessTier;
  final int queuePosition;
  final int cachedSegments;
}

Future<Set<String>> loadWarmFeedVisibleVideoDocIdsForShort(
    String userId) async {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) {
    return const <String>{};
  }

  final feedRepository = maybeFindFeedSnapshotRepository();
  final scheduler = maybeFindPrefetchScheduler();
  final agendaController = maybeFindAgendaController();
  final liveFeedSurfaceDocIds = agendaController?.agendaList
          .where((post) => post.hasPlayableVideo)
          .map((post) => post.docID.trim())
          .where((docId) => docId.isNotEmpty) ??
      const Iterable<String>.empty();
  final schedulerDocIds = <String>{
    ...liveFeedSurfaceDocIds,
    ...(scheduler
            ?.currentFeedSurfaceVideoDocIds()
            .map((docId) => docId.trim())
            .where((docId) => docId.isNotEmpty) ??
        const Iterable<String>.empty()),
    ...(scheduler
            ?.currentFeedDocIds()
            .map((docId) => docId.trim())
            .where((docId) => docId.isNotEmpty) ??
        const Iterable<String>.empty()),
  };
  if (feedRepository == null) {
    return schedulerDocIds;
  }

  final resource = await feedRepository.inspectWarmHome(
    userId: normalizedUserId,
    limit: ReadBudgetRegistry.feedPersistSnapshotLimit,
  );
  final posts = resource.data ?? const <PostsModel>[];
  if (posts.isEmpty) {
    return schedulerDocIds;
  }

  return <String>{
    ...schedulerDocIds,
    ...posts
        .where((post) => post.hasPlayableVideo)
        .map((post) => post.docID.trim())
        .where((docId) => docId.isNotEmpty)
        .toSet(),
  };
}

List<PostsModel> excludeFeedVisibleShortConflicts(
  List<PostsModel> posts,
  Set<String> feedVisibleVideoDocIds, {
  bool fallbackToOriginalWhenEmpty = true,
}
) {
  if (posts.isEmpty || feedVisibleVideoDocIds.isEmpty) {
    return posts;
  }
  final filtered = posts
      .where((post) => !feedVisibleVideoDocIds.contains(post.docID.trim()))
      .toList(growable: false);
  return filtered.isEmpty && fallbackToOriginalWhenEmpty ? posts : filtered;
}

ShortMixBucket resolveShortMixBucket(PostsModel post) {
  final cacheManager = SegmentCacheManager.maybeFind();
  final entry = cacheManager?.getEntry(post.docID.trim());
  final watchProgress = entry?.watchProgress ?? 0.0;
  if (watchProgress >= 0.80) {
    return ShortMixBucket.rescue;
  }
  if (watchProgress >= 0.05) {
    return ShortMixBucket.warm;
  }
  return ShortMixBucket.fresh;
}

Map<ShortMixBucket, double> resolveShortMixWeights({
  required int freshCount,
  required int warmCount,
  required int rescueCount,
}) {
  final total = freshCount + warmCount + rescueCount;
  if (total <= 0) return const <ShortMixBucket, double>{};
  if (freshCount <= 0) {
    return rescueCount > 0
        ? const <ShortMixBucket, double>{
            ShortMixBucket.warm: 0.70,
            ShortMixBucket.rescue: 0.30,
          }
        : const <ShortMixBucket, double>{
            ShortMixBucket.warm: 1.0,
          };
  }
  final freshShare = freshCount / total;
  if (freshShare >= 0.55) {
    return const <ShortMixBucket, double>{
      ShortMixBucket.fresh: 0.70,
      ShortMixBucket.warm: 0.20,
      ShortMixBucket.rescue: 0.10,
    };
  }
  if (freshShare >= 0.30) {
    return const <ShortMixBucket, double>{
      ShortMixBucket.fresh: 0.50,
      ShortMixBucket.warm: 0.30,
      ShortMixBucket.rescue: 0.20,
    };
  }
  return const <ShortMixBucket, double>{
    ShortMixBucket.fresh: 0.35,
    ShortMixBucket.warm: 0.40,
    ShortMixBucket.rescue: 0.25,
  };
}

List<PostsModel> mixShortPresentationPosts(
  List<PostsModel> posts, {
  String sessionNamespace = 'short',
}) {
  if (posts.length < 3) return posts;

  final fresh = <PostsModel>[];
  final warm = <PostsModel>[];
  final rescue = <PostsModel>[];
  for (final post in posts) {
    switch (resolveShortMixBucket(post)) {
      case ShortMixBucket.fresh:
        fresh.add(post);
        break;
      case ShortMixBucket.warm:
        warm.add(post);
        break;
      case ShortMixBucket.rescue:
        rescue.add(post);
        break;
    }
  }

  final buckets = <ShortMixBucket, List<PostsModel>>{
    ShortMixBucket.fresh: _reorderBucketForPresentation(
      fresh,
      surfaceKey: 'short_mix_fresh',
      sessionNamespace: sessionNamespace,
    ),
    ShortMixBucket.warm: _reorderBucketForPresentation(
      warm,
      surfaceKey: 'short_mix_warm',
      sessionNamespace: sessionNamespace,
    ),
    ShortMixBucket.rescue: _reorderBucketForPresentation(
      rescue,
      surfaceKey: 'short_mix_rescue',
      sessionNamespace: sessionNamespace,
    ),
  };
  final weights = resolveShortMixWeights(
    freshCount: buckets[ShortMixBucket.fresh]!.length,
    warmCount: buckets[ShortMixBucket.warm]!.length,
    rescueCount: buckets[ShortMixBucket.rescue]!.length,
  );

  final result = <PostsModel>[];
  final taken = <ShortMixBucket, int>{
    ShortMixBucket.fresh: 0,
    ShortMixBucket.warm: 0,
    ShortMixBucket.rescue: 0,
  };
  ShortMixBucket? lastBucket;
  var streak = 0;

  while (buckets.values.any((items) => items.isNotEmpty)) {
    ShortMixBucket? selected;
    double selectedScore = -double.infinity;

    for (final bucket in ShortMixBucket.values) {
      final items = buckets[bucket]!;
      if (items.isEmpty) continue;
      final expected = (result.length + 1) * (weights[bucket] ?? 0.0);
      var score = expected - (taken[bucket] ?? 0);
      if (bucket == lastBucket && streak >= 2) {
        score -= 1000;
      }
      if (selected == null || score > selectedScore) {
        selected = bucket;
        selectedScore = score;
      }
    }

    selected ??= ShortMixBucket.values.firstWhere(
      (bucket) => buckets[bucket]!.isNotEmpty,
    );
    result.add(buckets[selected]!.removeAt(0));
    taken[selected] = (taken[selected] ?? 0) + 1;
    if (lastBucket == selected) {
      streak++;
    } else {
      lastBucket = selected;
      streak = 1;
    }
  }

  return result;
}

List<PostsModel> _reorderBucketForPresentation(
  List<PostsModel> posts, {
  required String surfaceKey,
  required String sessionNamespace,
}) {
  if (posts.length < 2) {
    return posts.toList(growable: true);
  }

  final scored = posts
      .map(
        (post) => MapEntry(
          post,
          _resolveShortPresentationSignal(post),
        ),
      )
      .toList(growable: true)
    ..sort((left, right) {
      final activeCompare = (right.value.activelyDownloading ? 1 : 0) -
          (left.value.activelyDownloading ? 1 : 0);
      if (activeCompare != 0) return activeCompare;

      final tierCompare =
          right.value.readinessTier.compareTo(left.value.readinessTier);
      if (tierCompare != 0) return tierCompare;

      final leftQueue =
          left.value.queuePosition < 0 ? 1 << 20 : left.value.queuePosition;
      final rightQueue =
          right.value.queuePosition < 0 ? 1 << 20 : right.value.queuePosition;
      final queueCompare = leftQueue.compareTo(rightQueue);
      if (queueCompare != 0) return queueCompare;

      return right.value.cachedSegments.compareTo(left.value.cachedSegments);
    });

  final ordered = <PostsModel>[];
  var start = 0;
  while (start < scored.length) {
    final current = scored[start].value;
    var end = start + 1;
    while (end < scored.length) {
      final next = scored[end].value;
      if (next.readinessTier != current.readinessTier ||
          next.queuePosition != current.queuePosition ||
          next.cachedSegments != current.cachedSegments) {
        break;
      }
      end++;
    }

    final chunk = scored
        .sublist(start, end)
        .map((entry) => entry.key)
        .toList(growable: false);
    ordered.addAll(
      reorderForStartupSurface(
        chunk,
        surfaceKey:
            '${surfaceKey}_${current.readinessTier}_${current.queuePosition}_${current.cachedSegments}',
        sessionNamespace: sessionNamespace,
        maxShuffleWindow: chunk.length,
      ),
    );
    start = end;
  }

  return ordered;
}

_ShortPresentationSignal _resolveShortPresentationSignal(PostsModel post) {
  final docId = post.docID.trim();
  final cacheManager = SegmentCacheManager.maybeFind();
  final scheduler = maybeFindPrefetchScheduler();
  final entry = cacheManager?.getEntry(docId);
  final cachedSegments = entry?.cachedSegmentCount ?? 0;
  final activelyDownloading =
      scheduler?.isActivelyDownloadingDoc(docId) ?? false;
  final queuePosition = scheduler?.queuePositionForDoc(docId) ?? -1;
  final hasPendingPrefetch =
      scheduler?.hasPendingPrefetchForDoc(docId) ?? false;
  final isQueued =
      activelyDownloading || queuePosition >= 0 || hasPendingPrefetch;

  final readinessTier =
      switch ((entry?.isFullyCached ?? false, cachedSegments, isQueued)) {
    (true, _, _) => 5,
    (false, >= 2, true) => 4,
    (false, >= 2, false) => 3,
    (false, >= 1, true) => 2,
    (false, >= 1, false) => 1,
    _ when isQueued => 1,
    _ => 0,
  };

  return _ShortPresentationSignal(
    activelyDownloading: activelyDownloading,
    readinessTier: readinessTier,
    queuePosition: queuePosition,
    cachedSegments: cachedSegments,
  );
}
