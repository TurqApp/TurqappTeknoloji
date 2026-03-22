import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/Chat/chat_realtime_sync_policy.dart';

ChatRealtimeHeadEntry _entry({
  required String id,
  int createdDateMs = 100,
  int updatedDateMs = 0,
  String status = 'sent',
  bool isEdited = false,
  bool isUnsent = false,
  int seenByCount = 1,
  int reactionBucketCount = 0,
  int reactionSelectionCount = 0,
  int likeCount = 0,
  int deletedForCount = 0,
}) {
  return ChatRealtimeHeadEntry(
    id: id,
    createdDateMs: createdDateMs,
    updatedDateMs: updatedDateMs,
    status: status,
    isEdited: isEdited,
    isUnsent: isUnsent,
    seenByCount: seenByCount,
    reactionBucketCount: reactionBucketCount,
    reactionSelectionCount: reactionSelectionCount,
    likeCount: likeCount,
    deletedForCount: deletedForCount,
  );
}

void main() {
  test('buildHeadSignature changes when mutation counts change', () {
    final base = ChatRealtimeSyncPolicy.buildHeadSignature([
      _entry(id: 'm1', reactionBucketCount: 1, reactionSelectionCount: 1),
    ]);
    final changed = ChatRealtimeSyncPolicy.buildHeadSignature([
      _entry(id: 'm1', reactionBucketCount: 1, reactionSelectionCount: 2),
    ]);

    expect(changed, isNot(base));
  });

  test('buildHeadSignature changes when deletedFor count changes', () {
    final base = ChatRealtimeSyncPolicy.buildHeadSignature([
      _entry(id: 'm1', deletedForCount: 0),
    ]);
    final changed = ChatRealtimeSyncPolicy.buildHeadSignature([
      _entry(id: 'm1', deletedForCount: 1),
    ]);

    expect(changed, isNot(base));
  });

  test('shouldTriggerSync when initial head is available', () {
    final signature = ChatRealtimeSyncPolicy.buildHeadSignature([
      _entry(id: 'm1', createdDateMs: 300),
    ]);

    final shouldSync = ChatRealtimeSyncPolicy.shouldTriggerSync(
      previousHeadSignature: '',
      nextHeadSignature: signature,
      latestLoadedTimestampMs: 300,
      latestRemoteTimestampMs: 300,
    );

    expect(shouldSync, isTrue);
  });

  test(
      'shouldTriggerSync when head signature changes without newer createdDate',
      () {
    final previous = ChatRealtimeSyncPolicy.buildHeadSignature([
      _entry(id: 'm1', createdDateMs: 300, updatedDateMs: 0),
    ]);
    final next = ChatRealtimeSyncPolicy.buildHeadSignature([
      _entry(id: 'm1', createdDateMs: 300, updatedDateMs: 900),
    ]);

    final shouldSync = ChatRealtimeSyncPolicy.shouldTriggerSync(
      previousHeadSignature: previous,
      nextHeadSignature: next,
      latestLoadedTimestampMs: 300,
      latestRemoteTimestampMs: 300,
    );

    expect(shouldSync, isTrue);
  });

  test('should not trigger sync for identical signatures', () {
    final signature = ChatRealtimeSyncPolicy.buildHeadSignature([
      _entry(id: 'm1', createdDateMs: 300, updatedDateMs: 900),
    ]);

    final shouldSync = ChatRealtimeSyncPolicy.shouldTriggerSync(
      previousHeadSignature: signature,
      nextHeadSignature: signature,
      latestLoadedTimestampMs: 300,
      latestRemoteTimestampMs: 300,
    );

    expect(shouldSync, isFalse);
  });
}
