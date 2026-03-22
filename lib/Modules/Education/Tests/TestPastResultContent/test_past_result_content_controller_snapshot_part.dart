part of 'test_past_result_content_controller.dart';

extension TestPastResultContentControllerSnapshotPart
    on TestPastResultContentController {
  void _applySnapshot(List<Map<String, dynamic>> snapshot) {
    count.value = 0;
    timeStamp.value = 0;
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    final filtered = snapshot
        .where((doc) => (doc['userID'] ?? '').toString() == currentUserId)
        .toList(growable: false)
      ..sort(
        (a, b) => ((b['timeStamp'] ?? 0) as num)
            .compareTo((a['timeStamp'] ?? 0) as num),
      );

    if (filtered.isNotEmpty) {
      count.value = filtered.length;
      timeStamp.value = ((filtered.first['timeStamp'] ?? 0) as num).toInt();
    }
  }
}
