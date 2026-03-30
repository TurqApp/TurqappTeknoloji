import 'dart:async';

import 'package:get/get.dart';

enum CacheInvalidationEventType {
  messageDeletedForUser,
  messageUnsent,
  postDeleted,
  storyDeleted,
  storyExpired,
  marketRemoved,
  jobUnpublished,
  tutoringUnpublished,
  visibilityChanged,
}

class CacheInvalidationEvent {
  const CacheInvalidationEvent({
    required this.type,
    this.scopeId = '',
    this.entityId = '',
    this.entityIds = const <String>[],
    this.actorUserId = '',
    this.payload = const <String, Object?>{},
  });

  factory CacheInvalidationEvent.messageDeletedForUser({
    required String chatId,
    required Iterable<String> messageIds,
    required String userId,
  }) {
    final normalizedIds = messageIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    return CacheInvalidationEvent(
      type: CacheInvalidationEventType.messageDeletedForUser,
      scopeId: chatId.trim(),
      entityIds: normalizedIds,
      entityId: normalizedIds.isNotEmpty ? normalizedIds.first : '',
      actorUserId: userId.trim(),
    );
  }

  factory CacheInvalidationEvent.messageUnsent({
    required String chatId,
    required String messageId,
  }) {
    final normalizedId = messageId.trim();
    return CacheInvalidationEvent(
      type: CacheInvalidationEventType.messageUnsent,
      scopeId: chatId.trim(),
      entityId: normalizedId,
      entityIds:
          normalizedId.isEmpty ? const <String>[] : <String>[normalizedId],
    );
  }

  final CacheInvalidationEventType type;
  final String scopeId;
  final String entityId;
  final List<String> entityIds;
  final String actorUserId;
  final Map<String, Object?> payload;

  bool get isMessageEvent =>
      type == CacheInvalidationEventType.messageDeletedForUser ||
      type == CacheInvalidationEventType.messageUnsent;
}

class CacheInvalidationService extends GetxService {
  static CacheInvalidationService? maybeFind() {
    final isRegistered = Get.isRegistered<CacheInvalidationService>();
    if (!isRegistered) return null;
    return Get.find<CacheInvalidationService>();
  }

  static CacheInvalidationService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(CacheInvalidationService(), permanent: true);
  }

  final StreamController<CacheInvalidationEvent> _controller =
      StreamController<CacheInvalidationEvent>.broadcast();

  Stream<CacheInvalidationEvent> get events => _controller.stream;

  void publish(CacheInvalidationEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  Stream<CacheInvalidationEvent> watchType(CacheInvalidationEventType type) {
    return _controller.stream.where((event) => event.type == type);
  }

  @override
  void onClose() {
    _controller.close();
    super.onClose();
  }
}
