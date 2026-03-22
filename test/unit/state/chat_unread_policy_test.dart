import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/Chat/chat_unread_policy.dart';

void main() {
  group('ChatUnreadPolicy.resolveUnreadCount', () {
    test('returns server unread when no local read cutoff exists', () {
      final unread = ChatUnreadPolicy.resolveUnreadCount(
        serverUnread: 4,
        lastMessageAtMs: 200,
        locallySeenAtMs: 0,
        currentUid: 'self',
        lastSenderId: 'other',
        deletedCutoffMs: 0,
      );

      expect(unread, 4);
    });

    test('forces zero when latest message was already seen locally', () {
      final unread = ChatUnreadPolicy.resolveUnreadCount(
        serverUnread: 3,
        lastMessageAtMs: 500,
        locallySeenAtMs: 500,
        currentUid: 'self',
        lastSenderId: 'other',
        deletedCutoffMs: 0,
      );

      expect(unread, 0);
    });

    test('forces zero when conversation was deleted up to the latest message',
        () {
      final unread = ChatUnreadPolicy.resolveUnreadCount(
        serverUnread: 2,
        lastMessageAtMs: 700,
        locallySeenAtMs: 0,
        currentUid: 'self',
        lastSenderId: 'other',
        deletedCutoffMs: 700,
      );

      expect(unread, 0);
    });

    test('creates a local unread candidate when the latest sender is remote',
        () {
      final unread = ChatUnreadPolicy.resolveUnreadCount(
        serverUnread: 0,
        lastMessageAtMs: 900,
        locallySeenAtMs: 100,
        currentUid: 'self',
        lastSenderId: 'other',
        deletedCutoffMs: 0,
      );

      expect(unread, 1);
    });

    test('ignores local unread candidate when the latest sender is self', () {
      final unread = ChatUnreadPolicy.resolveUnreadCount(
        serverUnread: 0,
        lastMessageAtMs: 900,
        locallySeenAtMs: 100,
        currentUid: 'self',
        lastSenderId: 'self',
        deletedCutoffMs: 0,
      );

      expect(unread, 0);
    });
  });

  test('maxLocalReadCutoff picks the greatest local cutoff', () {
    expect(ChatUnreadPolicy.maxLocalReadCutoff([12, 99, 42]), 99);
    expect(ChatUnreadPolicy.maxLocalReadCutoff(const <int>[]), 0);
  });
}
