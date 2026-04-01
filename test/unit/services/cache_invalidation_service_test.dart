import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/cache_invalidation_service.dart';

void main() {
  test('cache invalidation service publishes and filters events', () async {
    final service = CacheInvalidationService();
    final seen = <CacheInvalidationEvent>[];

    final sub = service
        .watchType(CacheInvalidationEventType.messageUnsent)
        .listen(seen.add);

    service.publish(
      CacheInvalidationEvent.messageDeletedForUser(
        chatId: 'chat-a',
        messageIds: const <String>['m-1'],
        userId: 'user-a',
      ),
    );
    service.publish(
      CacheInvalidationEvent.messageUnsent(
        chatId: 'chat-a',
        messageId: 'm-2',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(seen, hasLength(1));
    expect(seen.single.type, CacheInvalidationEventType.messageUnsent);
    expect(seen.single.scopeId, 'chat-a');
    expect(seen.single.entityIds, <String>['m-2']);

    await sub.cancel();
    service.onClose();
  });
}
