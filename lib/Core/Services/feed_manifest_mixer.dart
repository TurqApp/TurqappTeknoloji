import 'dart:math';

import 'package:turqappv2/Core/Repositories/feed_manifest_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';

enum FeedManifestDeckSource {
  manifest,
  gap,
}

class FeedManifestDeckEntry {
  const FeedManifestDeckEntry({
    required this.entry,
    required this.source,
  });

  final FeedManifestEntry entry;
  final FeedManifestDeckSource source;

  PostsModel get post => entry.post;
  String get canonicalId => entry.canonicalId;
}

class FeedManifestDeckResult {
  const FeedManifestDeckResult({
    required this.entries,
    required this.manifestCount,
    required this.gapCount,
    required this.skippedConsumedCount,
    required this.skippedDuplicateCount,
  });

  final List<FeedManifestDeckEntry> entries;
  final int manifestCount;
  final int gapCount;
  final int skippedConsumedCount;
  final int skippedDuplicateCount;

  List<PostsModel> get posts =>
      entries.map((entry) => entry.post).toList(growable: false);
}

class FeedManifestMixer {
  const FeedManifestMixer();

  static const int defaultLimit = 60;
  static const int defaultGapEvery = 6;
  static const int defaultMinUserSpacing = 3;
  static const int defaultScanWindow = 24;
  static const int defaultHeadPenaltyDepth = 40;

  FeedManifestDeckResult buildDeck({
    required List<FeedManifestEntry> manifestEntries,
    List<FeedManifestEntry> gapEntries = const <FeedManifestEntry>[],
    required int seed,
    int limit = defaultLimit,
    Set<String> consumedCanonicalIds = const <String>{},
    Set<String> consumedDocIds = const <String>{},
    Set<String> headPenaltyCanonicalIds = const <String>{},
    int gapEvery = defaultGapEvery,
    int minUserSpacing = defaultMinUserSpacing,
    int scanWindow = defaultScanWindow,
    int headPenaltyDepth = defaultHeadPenaltyDepth,
  }) {
    final normalizedLimit = max(0, limit);
    if (normalizedLimit == 0) {
      return const FeedManifestDeckResult(
        entries: <FeedManifestDeckEntry>[],
        manifestCount: 0,
        gapCount: 0,
        skippedConsumedCount: 0,
        skippedDuplicateCount: 0,
      );
    }

    final consumedCanonicals = consumedCanonicalIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final consumedDocs = consumedDocIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final headPenalties = headPenaltyCanonicalIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final seenCanonicals = <String>{};
    var skippedConsumedCount = 0;
    var skippedDuplicateCount = 0;

    List<_FeedDeckCandidate> prepare(
      List<FeedManifestEntry> sourceEntries,
      FeedManifestDeckSource source,
      int sourceSalt,
    ) {
      final random = Random(Object.hash(seed, sourceSalt, source.name));
      final candidates = <_FeedDeckCandidate>[];
      for (var index = 0; index < sourceEntries.length; index++) {
        final entry = sourceEntries[index];
        final post = entry.post;
        final canonicalId = entry.canonicalId.trim();
        final docId = post.docID.trim();
        if (canonicalId.isEmpty || docId.isEmpty) continue;
        if (consumedCanonicals.contains(canonicalId) ||
            consumedDocs.contains(docId)) {
          skippedConsumedCount++;
          continue;
        }
        if (!seenCanonicals.add(canonicalId)) {
          skippedDuplicateCount++;
          continue;
        }
        candidates.add(
          _FeedDeckCandidate(
            entry: entry,
            source: source,
            originalIndex: index,
            score: random.nextDouble(),
            headPenalty: headPenalties.contains(canonicalId),
          ),
        );
      }
      candidates.sort(_compareCandidates);
      return candidates;
    }

    final manifest = prepare(
      manifestEntries,
      FeedManifestDeckSource.manifest,
      17,
    );
    final gap = prepare(
      gapEntries,
      FeedManifestDeckSource.gap,
      43,
    );

    final deck = <FeedManifestDeckEntry>[];
    final recentUsers = <String>[];
    var manifestCount = 0;
    var gapCount = 0;
    final effectiveGapEvery = max(2, gapEvery);
    final maxGapCount =
        min(gap.length, (normalizedLimit / effectiveGapEvery).ceil());
    final effectiveScanWindow = max(1, scanWindow);
    final effectiveSpacing = max(0, minUserSpacing);

    while (deck.length < normalizedLimit &&
        (manifest.isNotEmpty || gap.isNotEmpty)) {
      final shouldTryGap = gap.isNotEmpty &&
          gapCount < maxGapCount &&
          deck.length >= effectiveGapEvery - 1 &&
          ((deck.length + seed.abs()) % effectiveGapEvery == 0);
      final primary = shouldTryGap ? gap : manifest;
      final fallback = shouldTryGap ? manifest : gap;
      var candidate = _takeNext(
        primary,
        recentUsers: recentUsers,
        position: deck.length,
        minUserSpacing: effectiveSpacing,
        scanWindow: effectiveScanWindow,
        headPenaltyDepth: headPenaltyDepth,
      );
      candidate ??= _takeNext(
        fallback,
        recentUsers: recentUsers,
        position: deck.length,
        minUserSpacing: effectiveSpacing,
        scanWindow: effectiveScanWindow,
        headPenaltyDepth: headPenaltyDepth,
      );
      if (candidate == null) break;

      deck.add(
        FeedManifestDeckEntry(
          entry: candidate.entry,
          source: candidate.source,
        ),
      );
      if (candidate.source == FeedManifestDeckSource.gap) {
        gapCount++;
      } else {
        manifestCount++;
      }
      final userId = candidate.entry.post.userID.trim();
      if (userId.isNotEmpty && effectiveSpacing > 0) {
        recentUsers.add(userId);
        if (recentUsers.length > effectiveSpacing) {
          recentUsers.removeAt(0);
        }
      }
    }

    return FeedManifestDeckResult(
      entries: deck,
      manifestCount: manifestCount,
      gapCount: gapCount,
      skippedConsumedCount: skippedConsumedCount,
      skippedDuplicateCount: skippedDuplicateCount,
    );
  }

  static FeedManifestEntry entryFromPost(
    PostsModel post, {
    String slotId = 'runtime_gap',
    String slotPath = 'typesense_gap',
  }) {
    return FeedManifestEntry(
      post: post,
      canonicalId: canonicalIdForPost(post),
      slotId: slotId,
      slotPath: slotPath,
    );
  }

  static String canonicalIdForPost(PostsModel post) {
    final mainFlood = post.mainFlood.trim();
    if (mainFlood.isNotEmpty) return mainFlood;
    if (post.isFloodSeriesRoot) return post.docID.trim();
    return post.docID.trim().replaceFirst(RegExp(r'_\d+$'), '');
  }

  static _FeedDeckCandidate? _takeNext(
    List<_FeedDeckCandidate> candidates, {
    required List<String> recentUsers,
    required int position,
    required int minUserSpacing,
    required int scanWindow,
    required int headPenaltyDepth,
  }) {
    if (candidates.isEmpty) return null;
    final avoidPenalty = position < headPenaltyDepth;
    final upperBound = min(scanWindow, candidates.length);
    final recentUserSet = minUserSpacing <= 0
        ? const <String>{}
        : recentUsers.reversed.take(minUserSpacing).toSet();

    int? fallbackIndex;
    int? penaltyFallbackIndex;
    for (var i = 0; i < upperBound; i++) {
      final candidate = candidates[i];
      final userId = candidate.entry.post.userID.trim();
      final sameRecentUser =
          userId.isNotEmpty && recentUserSet.contains(userId);
      if (avoidPenalty && candidate.headPenalty) {
        penaltyFallbackIndex ??= i;
        continue;
      }
      fallbackIndex ??= i;
      if (!sameRecentUser) {
        return candidates.removeAt(i);
      }
    }

    if (fallbackIndex != null) {
      return candidates.removeAt(fallbackIndex);
    }
    if (penaltyFallbackIndex != null) {
      return candidates.removeAt(penaltyFallbackIndex);
    }
    return candidates.removeAt(0);
  }

  static int _compareCandidates(
    _FeedDeckCandidate a,
    _FeedDeckCandidate b,
  ) {
    final scoreCompare = a.score.compareTo(b.score);
    if (scoreCompare != 0) return scoreCompare;
    return a.originalIndex.compareTo(b.originalIndex);
  }
}

class _FeedDeckCandidate {
  const _FeedDeckCandidate({
    required this.entry,
    required this.source,
    required this.originalIndex,
    required this.score,
    required this.headPenalty,
  });

  final FeedManifestEntry entry;
  final FeedManifestDeckSource source;
  final int originalIndex;
  final double score;
  final bool headPenalty;
}
