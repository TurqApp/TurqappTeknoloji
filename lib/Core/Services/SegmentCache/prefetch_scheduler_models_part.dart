part of 'prefetch_scheduler.dart';

class _PrefetchJob {
  final String docID;
  final int maxSegments, priority;
  final double sortScore;
  const _PrefetchJob(
      this.docID, this.maxSegments, this.priority, this.sortScore);
}

class _ResolvedPrefetchQueue {
  final List<String> docIDs;
  final List<PostsModel> posts;
  final int currentIndex;

  const _ResolvedPrefetchQueue({
    required this.docIDs,
    required this.posts,
    required this.currentIndex,
  });
}

class _ShortQuotaFillMinuteQueue {
  _ShortQuotaFillMinuteQueue({
    required this.anchorMs,
    required List<PostsModel> items,
  }) : _pending = items.toList(growable: true);

  final int anchorMs;
  final List<PostsModel> _pending;
  bool _servedInitialPick = false;

  PostsModel? takeNext({
    required Set<String> usedIds,
    required int preferredSubsliceIndex,
    required int preferredSubsliceSizeMs,
  }) {
    if (_pending.isEmpty) return null;

    if (!_servedInitialPick) {
      _servedInitialPick = true;
      final preferredStartMs = preferredSubsliceIndex * preferredSubsliceSizeMs;
      final preferredEndMs = preferredStartMs + preferredSubsliceSizeMs;
      for (var index = 0; index < _pending.length; index++) {
        final candidate = _pending[index];
        final docId = candidate.docID.trim();
        if (docId.isEmpty || usedIds.contains(docId)) continue;
        final millisecondOfSecond = candidate.timeStamp.toInt() % 1000;
        if (millisecondOfSecond >= preferredStartMs &&
            millisecondOfSecond < preferredEndMs) {
          return _pending.removeAt(index);
        }
      }
    }

    for (var index = 0; index < _pending.length; index++) {
      final candidate = _pending[index];
      final docId = candidate.docID.trim();
      if (docId.isEmpty || usedIds.contains(docId)) continue;
      return _pending.removeAt(index);
    }

    return null;
  }
}
