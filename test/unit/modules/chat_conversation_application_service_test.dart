import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:turqappv2/Modules/Chat/chat_conversation_application_service.dart';

void main() {
  group('ChatConversationApplicationService', () {
    test('prepareSendPlan resolves counterpart and builds text payload',
        () async {
      final service = ChatConversationApplicationService(
        conversationLoader: (
          chatId, {
          bool preferCache = true,
          bool cacheOnly = false,
        }) async {
          return <String, dynamic>{
            'participants': <String>['user-a', 'user-b'],
          };
        },
      );

      final plan = await service.prepareSendPlan(
        currentUid: 'user-a',
        routeUserId: '',
        chatId: 'user-a_user-b',
        now: DateTime(2026, 3, 28, 12),
        text: 'Merhaba',
      );

      expect(plan, isNotNull);
      expect(plan!.resolvedTargetUid, 'user-b');
      expect(plan.targetUidForConversation, 'user-b');
      expect(plan.messageType, 'text');
      expect(plan.previewText, 'Merhaba');
      expect(plan.notificationBody, 'Merhaba');
      expect(plan.payload['senderId'], 'user-a');
      expect(plan.payload['text'], 'Merhaba');
      expect(plan.payload['type'], 'text');
      expect(plan.payload['seenBy'], <String>['user-a']);
    });

    test('prepareSendPlan infers reply payload and media message policy',
        () async {
      final service = ChatConversationApplicationService();

      final plan = await service.prepareSendPlan(
        currentUid: 'user-a',
        routeUserId: 'user-b',
        chatId: 'user-a_user-b',
        now: DateTime(2026, 3, 28, 12),
        text: '',
        imageUrls: const <String>[' https://example.com/a.jpg '],
        replyingTo: _message(
          rawDocId: 'reply-1',
          userId: 'user-b',
          text: 'ilk mesaj',
        ),
      );

      expect(plan, isNotNull);
      expect(plan!.messageType, 'media');
      expect(plan.payload['mediaUrls'], <String>['https://example.com/a.jpg']);
      expect(plan.payload['replyTo'], isA<Map<String, dynamic>>());
      expect(plan.payload['replyTo']['messageId'], 'reply-1');
      expect(plan.payload['replyTo']['senderId'], 'user-b');
      expect(plan.payload['replyTo']['type'], 'text');
    });

    test('buildReadPolicyPlan computes unseen and undelivered sets', () {
      final service = ChatConversationApplicationService();

      final plan = service.buildReadPolicyPlan(
        currentUid: 'user-a',
        snapshots: const <ChatReadReceiptSnapshot>[
          ChatReadReceiptSnapshot(
            rawDocId: 'm1',
            senderId: 'user-b',
            status: 'sent',
            seenBy: <String>[],
            timestampMs: 100,
          ),
          ChatReadReceiptSnapshot(
            rawDocId: 'm2',
            senderId: 'user-b',
            status: 'delivered',
            seenBy: <String>['user-a'],
            timestampMs: 120,
          ),
          ChatReadReceiptSnapshot(
            rawDocId: 'm3',
            senderId: 'user-a',
            status: 'sent',
            seenBy: <String>['user-a'],
            timestampMs: 140,
          ),
        ],
      );

      expect(plan.unseenRawDocIds, <String>['m1']);
      expect(plan.undeliveredRawDocIds, <String>['m1']);
      expect(plan.latestSeenTs, 140);
      expect(plan.hasPendingRepositoryUpdates, isTrue);
    });

    test('opened key and persist policy keep only newer timestamps', () {
      final service = ChatConversationApplicationService();

      expect(
        service.buildOpenedStorageKey(uid: 'user-a', chatId: 'chat-1'),
        'chat_last_opened_user-a_chat-1',
      );
      expect(
        service.shouldPersistOpenedAt(
          previousOpenedAtMs: 100,
          candidateTimestampMs: 120,
        ),
        isTrue,
      );
      expect(
        service.shouldPersistOpenedAt(
          previousOpenedAtMs: 100,
          candidateTimestampMs: 90,
        ),
        isFalse,
      );
    });

    test('chat controller delegates send and read policy to service', () {
      final sendSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat/chat_controller_send_part.dart',
      ).readAsStringSync();
      final actionsSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat/chat_controller_actions_part.dart',
      ).readAsStringSync();
      final conversationSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat/chat_controller_conversation.dart',
      ).readAsStringSync();

      expect(
        sendSource,
        contains('conversationApplicationService.prepareSendPlan'),
      );
      expect(
        sendSource,
        contains('conversationApplicationService.ensureConversationReady'),
      );
      expect(actionsSource, contains('buildReadPolicyPlan'));
      expect(conversationSource, contains('buildOpenedStorageKey'));
      expect(conversationSource, contains('shouldPersistOpenedAt'));
      expect(sendSource,
          isNot(contains('Future<String?> _resolveCounterpartUserId()')));
      expect(sendSource,
          isNot(contains('Future<void> _ensureConversationReady({')));
    });
  });
}

MessageModel _message({
  required String rawDocId,
  required String userId,
  required String text,
}) {
  return MessageModel(
    docID: 'conv_$rawDocId',
    rawDocID: rawDocId,
    source: 'conversation',
    timeStamp: 100,
    userID: userId,
    lat: 0,
    long: 0,
    postType: '',
    postID: '',
    imgs: const <String>[],
    video: '',
    isRead: false,
    kullanicilar: const <String>[],
    begeniler: const <String>[],
    metin: text,
    sesliMesaj: '',
    kisiAdSoyad: '',
    kisiTelefon: '',
    isEdited: false,
    isUnsent: false,
    isForwarded: false,
    replyMessageId: '',
    replySenderId: '',
    replyText: '',
    replyType: '',
    reactions: const <String, List<String>>{},
  );
}
