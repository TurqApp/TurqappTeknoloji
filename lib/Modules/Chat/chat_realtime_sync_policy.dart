class ChatRealtimeHeadEntry {
  const ChatRealtimeHeadEntry({
    required this.id,
    required this.createdDateMs,
    required this.updatedDateMs,
    required this.status,
    required this.isEdited,
    required this.isUnsent,
    required this.seenByCount,
    required this.reactionBucketCount,
    required this.reactionSelectionCount,
    required this.likeCount,
    required this.deletedForCount,
  });

  final String id;
  final int createdDateMs;
  final int updatedDateMs;
  final String status;
  final bool isEdited;
  final bool isUnsent;
  final int seenByCount;
  final int reactionBucketCount;
  final int reactionSelectionCount;
  final int likeCount;
  final int deletedForCount;
}

class ChatRealtimeSyncPolicy {
  const ChatRealtimeSyncPolicy._();

  static String buildHeadSignature(Iterable<ChatRealtimeHeadEntry> entries) {
    final parts = entries.map((entry) {
      return [
        entry.id,
        entry.createdDateMs,
        entry.updatedDateMs,
        entry.status.trim(),
        entry.isEdited ? 1 : 0,
        entry.isUnsent ? 1 : 0,
        entry.seenByCount,
        entry.reactionBucketCount,
        entry.reactionSelectionCount,
        entry.likeCount,
        entry.deletedForCount,
      ].join(':');
    }).toList(growable: false);
    return parts.join('|');
  }

  static bool shouldTriggerSync({
    required String previousHeadSignature,
    required String nextHeadSignature,
    required int latestLoadedTimestampMs,
    required int latestRemoteTimestampMs,
  }) {
    if (nextHeadSignature.isEmpty) return false;
    if (previousHeadSignature.isEmpty) {
      return nextHeadSignature.isNotEmpty &&
          latestRemoteTimestampMs >= latestLoadedTimestampMs;
    }
    if (previousHeadSignature == nextHeadSignature) return false;
    return true;
  }
}
