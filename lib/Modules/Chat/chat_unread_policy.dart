import 'dart:math' as math;

class ChatUnreadPolicy {
  const ChatUnreadPolicy._();

  static int resolveUnreadCount({
    required int serverUnread,
    required int lastMessageAtMs,
    required int locallySeenAtMs,
    required String currentUid,
    required String lastSenderId,
    required int deletedCutoffMs,
  }) {
    if (lastMessageAtMs <= 0) {
      return math.max(0, serverUnread);
    }
    if (deletedCutoffMs > 0 && lastMessageAtMs <= deletedCutoffMs) {
      return 0;
    }
    if (locallySeenAtMs >= lastMessageAtMs) {
      return 0;
    }
    final localUnreadCandidate =
        lastSenderId.isNotEmpty && lastSenderId != currentUid ? 1 : 0;
    return math.max(serverUnread, localUnreadCandidate);
  }

  static int maxLocalReadCutoff(Iterable<int> cutoffs) {
    var result = 0;
    for (final cutoff in cutoffs) {
      if (cutoff > result) {
        result = cutoff;
      }
    }
    return result;
  }
}
