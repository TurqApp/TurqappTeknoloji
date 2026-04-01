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
