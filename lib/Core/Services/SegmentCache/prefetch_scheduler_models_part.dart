part of 'prefetch_scheduler.dart';

class _PrefetchJob {
  final String docID;
  final int maxSegments, priority;
  final double sortScore;
  const _PrefetchJob(
      this.docID, this.maxSegments, this.priority, this.sortScore);
}
