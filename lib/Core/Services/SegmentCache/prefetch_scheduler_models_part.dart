part of 'prefetch_scheduler.dart';

class _PrefetchJob {
  final String docID;
  final int maxSegments;
  final int priority;
  final double sortScore;

  _PrefetchJob({
    required this.docID,
    required this.maxSegments,
    required this.priority,
    required this.sortScore,
  });
}
