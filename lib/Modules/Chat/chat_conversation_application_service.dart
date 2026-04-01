import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Models/message_model.dart';

class ChatSendPlan {
  const ChatSendPlan({
    required this.currentUid,
    required this.text,
    required this.messageType,
    required this.previewText,
    required this.notificationBody,
    required this.payload,
    required this.resolvedTargetUid,
    required this.targetUidForConversation,
  });

  final String currentUid;
  final String text;
  final String messageType;
  final String previewText;
  final String notificationBody;
  final Map<String, dynamic> payload;
  final String? resolvedTargetUid;
  final String targetUidForConversation;
}

class ChatReadReceiptSnapshot {
  const ChatReadReceiptSnapshot({
    required this.rawDocId,
    required this.senderId,
    required this.status,
    required this.seenBy,
    required this.timestampMs,
  });

  final String rawDocId;
  final String senderId;
  final String status;
  final List<String> seenBy;
  final int timestampMs;
}

class ChatReadPolicyPlan {
  const ChatReadPolicyPlan({
    required this.unseenRawDocIds,
    required this.undeliveredRawDocIds,
    required this.latestSeenTs,
  });

  final List<String> unseenRawDocIds;
  final List<String> undeliveredRawDocIds;
  final int latestSeenTs;

  bool get hasPendingRepositoryUpdates =>
      unseenRawDocIds.isNotEmpty || undeliveredRawDocIds.isNotEmpty;
}

class ChatConversationApplicationService {
  ChatConversationApplicationService({
    Future<Map<String, dynamic>?> Function(
      String chatId, {
      bool preferCache,
      bool cacheOnly,
    })? conversationLoader,
    Future<void> Function({
      required String chatId,
      required String currentUid,
      required String otherUid,
      required String lastMessage,
      required int nowMs,
    })? conversationEnvelopeUpserter,
  })  : _conversationLoader = conversationLoader ??
            ((chatId, {preferCache = true, cacheOnly = false}) {
              return ConversationRepository.ensure().getConversation(
                chatId,
                preferCache: preferCache,
                cacheOnly: cacheOnly,
              );
            }),
        _conversationEnvelopeUpserter = conversationEnvelopeUpserter ??
            _buildConversationEnvelopeUpserter();

  final Future<Map<String, dynamic>?> Function(
    String chatId, {
    bool preferCache,
    bool cacheOnly,
  }) _conversationLoader;

  final Future<void> Function({
    required String chatId,
    required String currentUid,
    required String otherUid,
    required String lastMessage,
    required int nowMs,
  }) _conversationEnvelopeUpserter;

  static Future<void> Function({
    required String chatId,
    required String currentUid,
    required String otherUid,
    required String lastMessage,
    required int nowMs,
  }) _buildConversationEnvelopeUpserter() {
    return ({
      required String chatId,
      required String currentUid,
      required String otherUid,
      required String lastMessage,
      required int nowMs,
    }) {
      return ConversationRepository.ensure().upsertConversationEnvelope(
        chatId: chatId,
        currentUid: currentUid,
        otherUid: otherUid,
        lastMessage: lastMessage,
        nowMs: nowMs,
      );
    };
  }

  Future<String?> resolveCounterpartUserId({
    required String currentUid,
    required String routeUserId,
    required String chatId,
  }) async {
    final cleanCurrentUid = currentUid.trim();
    if (cleanCurrentUid.isEmpty) return null;

    final candidates = <String>{};
    final fromRoute = routeUserId.trim();
    if (fromRoute.isNotEmpty) candidates.add(fromRoute);

    for (final part in chatId.split('_')) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) candidates.add(trimmed);
    }

    try {
      final data = await _conversationLoader(
        chatId,
        preferCache: true,
        cacheOnly: false,
      );
      if (data != null) {
        final participants = data['participants'];
        if (participants is List) {
          for (final participant in participants) {
            final uid = participant.toString().trim();
            if (uid.isNotEmpty) candidates.add(uid);
          }
        }
        final uid1 = (data['userID1'] ?? '').toString().trim();
        final uid2 = (data['userID2'] ?? '').toString().trim();
        if (uid1.isNotEmpty) candidates.add(uid1);
        if (uid2.isNotEmpty) candidates.add(uid2);
      }
    } catch (_) {}

    for (final candidate in candidates) {
      if (candidate != cleanCurrentUid) return candidate;
    }
    return null;
  }

  Future<ChatSendPlan?> prepareSendPlan({
    required String currentUid,
    required String routeUserId,
    required String chatId,
    required DateTime now,
    required String text,
    List<String>? imageUrls,
    LatLng? latLng,
    String? kisiAdSoyad,
    String? kisiTelefon,
    String? gif,
    String? postID,
    String? postType,
    String? videoUrl,
    String? videoThumbnail,
    String? audioUrl,
    int? audioDurationMs,
    String? replyTextOverride,
    String? replyTypeOverride,
    String? replySenderIdOverride,
    String? replyMessageIdOverride,
    MessageModel? replyingTo,
  }) async {
    final trimmedText = text.trim();
    final normalizedImages = (imageUrls ?? const <String>[])
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final normalizedGif = (gif ?? '').trim();
    final normalizedPostId = (postID ?? '').trim();
    final normalizedPostType = (postType ?? '').trim();
    final normalizedVideoUrl = (videoUrl ?? '').trim();
    final normalizedVideoThumbnail = (videoThumbnail ?? '').trim();
    final normalizedAudioUrl = (audioUrl ?? '').trim();
    final normalizedContactName = (kisiAdSoyad ?? '').trim();
    final normalizedContactPhone = (kisiTelefon ?? '').trim();

    if (trimmedText.isEmpty &&
        normalizedImages.isEmpty &&
        latLng == null &&
        normalizedContactName.isEmpty &&
        normalizedPostId.isEmpty &&
        normalizedGif.isEmpty &&
        normalizedVideoUrl.isEmpty &&
        normalizedAudioUrl.isEmpty) {
      return null;
    }

    final messageType = _resolveMessageType(
      text: trimmedText,
      imageUrls: normalizedImages,
      latLng: latLng,
      kisiAdSoyad: normalizedContactName,
      postID: normalizedPostId,
      gif: normalizedGif,
      videoUrl: normalizedVideoUrl,
      audioUrl: normalizedAudioUrl,
    );
    final previewText = _buildLastMessageText(
      text: trimmedText,
      imageUrls: normalizedImages,
      latLng: latLng,
      kisiAdSoyad: normalizedContactName,
      postID: normalizedPostId,
      gif: normalizedGif,
      videoUrl: normalizedVideoUrl,
      audioUrl: normalizedAudioUrl,
    );
    final notificationBody = _buildNotificationBody(
      text: trimmedText,
      imageUrls: normalizedImages,
      latLng: latLng,
      kisiAdSoyad: normalizedContactName,
      postID: normalizedPostId,
      gif: normalizedGif,
      videoUrl: normalizedVideoUrl,
      audioUrl: normalizedAudioUrl,
    );
    final replyPayload = _buildReplyPayload(
      now: now,
      currentUid: currentUid,
      replyTextOverride: replyTextOverride,
      replyTypeOverride: replyTypeOverride,
      replySenderIdOverride: replySenderIdOverride,
      replyMessageIdOverride: replyMessageIdOverride,
      replyingTo: replyingTo,
    );
    final resolvedTargetUid = await resolveCounterpartUserId(
      currentUid: currentUid,
      routeUserId: routeUserId,
      chatId: chatId,
    );

    return ChatSendPlan(
      currentUid: currentUid,
      text: trimmedText,
      messageType: messageType,
      previewText: previewText,
      notificationBody: notificationBody,
      resolvedTargetUid: resolvedTargetUid,
      targetUidForConversation: (resolvedTargetUid ?? routeUserId).trim(),
      payload: {
        'senderId': currentUid,
        'text': trimmedText,
        'createdDate': now.millisecondsSinceEpoch,
        'seenBy': <String>[currentUid],
        'type': messageType,
        'mediaUrls': normalizedGif.isNotEmpty
            ? <String>[normalizedGif]
            : normalizedImages,
        'likes': <String>[],
        'isDeleted': false,
        'isEdited': false,
        'forwarded': false,
        'unsent': false,
        'audioUrl': normalizedAudioUrl,
        'audioDurationMs': audioDurationMs ?? 0,
        'videoUrl': normalizedVideoUrl,
        'videoThumbnail': normalizedVideoThumbnail,
        'status': 'sent',
        'reactions': <String, List<String>>{},
        if (latLng != null)
          'location': {
            'lat': latLng.latitude.toDouble(),
            'lng': latLng.longitude.toDouble(),
            'name': trimmedText,
          },
        if (normalizedContactName.isNotEmpty)
          'contact': {
            'name': normalizedContactName,
            'phone': normalizedContactPhone,
          },
        if (normalizedPostId.isNotEmpty)
          'postRef': {
            'postId': normalizedPostId,
            'postType': normalizedPostType,
            'previewText': '',
            'previewImageUrl': '',
          },
        if (replyPayload != null) 'replyTo': replyPayload,
      },
    );
  }

  Future<void> ensureConversationReady({
    required String chatId,
    required String currentUid,
    required String targetUserId,
    required String previewText,
    required int nowMs,
  }) async {
    final cleanCurrentUid = currentUid.trim();
    final cleanTargetUserId = targetUserId.trim();
    if (cleanCurrentUid.isEmpty || cleanTargetUserId.isEmpty) return;
    await _conversationEnvelopeUpserter(
      chatId: chatId,
      currentUid: cleanCurrentUid,
      otherUid: cleanTargetUserId,
      lastMessage: previewText,
      nowMs: nowMs,
    );
  }

  ChatReadPolicyPlan buildReadPolicyPlan({
    required String currentUid,
    required Iterable<ChatReadReceiptSnapshot> snapshots,
  }) {
    final unseenRawDocIds = <String>[];
    final undeliveredRawDocIds = <String>[];
    var latestSeenTs = 0;

    for (final snapshot in snapshots) {
      if (snapshot.timestampMs > latestSeenTs) {
        latestSeenTs = snapshot.timestampMs;
      }
      if (snapshot.senderId != currentUid &&
          !snapshot.seenBy.contains(currentUid)) {
        unseenRawDocIds.add(snapshot.rawDocId);
      }
      if (snapshot.senderId != currentUid && snapshot.status == 'sent') {
        undeliveredRawDocIds.add(snapshot.rawDocId);
      }
    }

    return ChatReadPolicyPlan(
      unseenRawDocIds: unseenRawDocIds,
      undeliveredRawDocIds: undeliveredRawDocIds,
      latestSeenTs: latestSeenTs,
    );
  }

  String buildOpenedStorageKey({
    required String uid,
    required String chatId,
  }) {
    return 'chat_last_opened_${uid}_$chatId';
  }

  bool shouldPersistOpenedAt({
    required int previousOpenedAtMs,
    required int candidateTimestampMs,
  }) {
    return candidateTimestampMs > previousOpenedAtMs;
  }

  String _buildNotificationBody({
    required String text,
    required List<String> imageUrls,
    required LatLng? latLng,
    required String kisiAdSoyad,
    required String postID,
    required String gif,
    required String videoUrl,
    required String audioUrl,
  }) {
    if (videoUrl.isNotEmpty) {
      return 'chat.notif_video'.tr;
    }
    if (audioUrl.isNotEmpty) {
      return 'chat.notif_audio'.tr;
    }
    if (imageUrls.isNotEmpty) {
      return 'chat.notif_images'.trParams({
        'count': imageUrls.length.toString(),
      });
    }
    if (postID.isNotEmpty) {
      return 'chat.notif_post'.tr;
    }
    if (latLng != null) {
      return 'chat.notif_location'.tr;
    }
    if (kisiAdSoyad.isNotEmpty) {
      return 'chat.notif_contact'.tr;
    }
    if (gif.isNotEmpty) {
      return 'chat.notif_gif'.tr;
    }
    return text;
  }

  String _resolveMessageType({
    required String text,
    required List<String> imageUrls,
    required LatLng? latLng,
    required String kisiAdSoyad,
    required String postID,
    required String gif,
    required String videoUrl,
    required String audioUrl,
  }) {
    if (videoUrl.isNotEmpty) return 'video';
    if (audioUrl.isNotEmpty) return 'audio';
    if (imageUrls.isNotEmpty) return 'media';
    if (gif.isNotEmpty) return 'gif';
    if (latLng != null) return 'location';
    if (kisiAdSoyad.isNotEmpty) return 'contact';
    if (postID.isNotEmpty) return 'post';
    if (text.isNotEmpty) return 'text';
    return 'text';
  }

  String _buildLastMessageText({
    required String text,
    required List<String> imageUrls,
    required LatLng? latLng,
    required String kisiAdSoyad,
    required String postID,
    required String gif,
    required String videoUrl,
    required String audioUrl,
  }) {
    if (text.isNotEmpty) return text;
    if (videoUrl.isNotEmpty) return 'chat.video'.tr;
    if (audioUrl.isNotEmpty) return 'chat.audio'.tr;
    if (imageUrls.isNotEmpty) return 'chat.photo'.tr;
    if (gif.isNotEmpty) return 'chat.gif'.tr;
    if (latLng != null) return 'chat.location'.tr;
    if (kisiAdSoyad.isNotEmpty) return 'chat.person'.tr;
    if (postID.isNotEmpty) return 'chat.post'.tr;
    return 'chat.message_hint'.tr;
  }

  Map<String, dynamic>? _buildReplyPayload({
    required DateTime now,
    required String currentUid,
    required String? replyTextOverride,
    required String? replyTypeOverride,
    required String? replySenderIdOverride,
    required String? replyMessageIdOverride,
    required MessageModel? replyingTo,
  }) {
    final hasExternalReply = (replyTextOverride ?? '').trim().isNotEmpty;
    if (hasExternalReply) {
      final replyText = (replyTextOverride ?? '').trim();
      final replyType = (replyTypeOverride ?? 'text').trim();
      final replySender = (replySenderIdOverride ?? currentUid).trim();
      final replyMessageId =
          (replyMessageIdOverride ?? 'preview_${now.microsecondsSinceEpoch}')
              .trim();
      return {
        'messageId': replyMessageId,
        'senderId': replySender,
        'text': replyText,
        'type': replyType.isEmpty ? 'text' : replyType,
      };
    }

    final repliedModel = replyingTo;
    if (repliedModel == null) return null;

    var inferredReplyText = '';
    var inferredReplyType = 'text';
    var inferredReplyTarget = repliedModel.rawDocID;

    if (repliedModel.video.isNotEmpty) {
      inferredReplyType = 'video';
      inferredReplyText = "🎥 ${'chat.video'.tr}";
      inferredReplyTarget = repliedModel.video;
    } else if (repliedModel.imgs.isNotEmpty) {
      inferredReplyType = 'media';
      inferredReplyText = "📷 ${'chat.photo'.tr}";
      inferredReplyTarget = repliedModel.imgs.first;
    } else if (repliedModel.sesliMesaj.isNotEmpty) {
      inferredReplyType = 'audio';
      inferredReplyText = "🎤 ${'chat.audio'.tr}";
    } else if (repliedModel.lat != 0 || repliedModel.long != 0) {
      inferredReplyType = 'location';
      inferredReplyText = "📍 ${'chat.location'.tr}";
    } else if (repliedModel.postID.trim().isNotEmpty) {
      inferredReplyType = 'post';
      inferredReplyText = "🔗 ${'chat.post'.tr}";
      inferredReplyTarget = repliedModel.postID.trim();
    } else if (repliedModel.kisiAdSoyad.trim().isNotEmpty) {
      inferredReplyType = 'contact';
      inferredReplyText = "👤 ${'chat.person'.tr}";
    } else {
      inferredReplyType = 'text';
      inferredReplyText = repliedModel.metin.trim().isNotEmpty
          ? repliedModel.metin
          : 'chat.message_hint'.tr;
    }

    return {
      'messageId': inferredReplyTarget,
      'senderId': repliedModel.userID,
      'text': inferredReplyText,
      'type': inferredReplyType,
    };
  }
}
