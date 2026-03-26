part of 'prefetch_scheduler.dart';

class _PrefetchJob {
  final String docID;
  final int maxSegments, priority;
  final double sortScore;

  const _PrefetchJob({
    required this.docID,
    required this.maxSegments,
    required this.priority,
    required this.sortScore,
  });
}
