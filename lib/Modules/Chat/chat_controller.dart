import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/giphy_picker_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/InAppNotifications/in_app_notifications_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Core/Camera/chat_camera_capture_view.dart';
import '../../Core/blocked_texts.dart';
import '../../Core/Services/optimized_nsfw_service.dart';
import '../../Models/message_model.dart';

part 'chat_controller_conversation.dart';
part 'chat_controller_media_part.dart';

class ChatController extends GetxController {
  String chatID;
  String userID;
  var nickname = "".obs;
  var avatarUrl = "".obs;
  var token = "".obs;
  var fullName = "".obs;
  var bio = "".obs;
  var followersCount = 0.obs;
  var followingCount = 0.obs;
  var postCount = 0.obs;
  var selection = 0.obs;
  var textMesage = ''.obs;
  var uploadPercent = 0.0.obs;
  RxList<MessageModel> messages = <MessageModel>[].obs;
  TextEditingController textEditingController = TextEditingController();
  ScrollController scrollController = ScrollController();
  PageController pageController = PageController();
  FocusNode focus = FocusNode();
  bool didAutoFocusOnce = false;
  var currentPage = 0.obs;
  final picker = ImagePicker();
  RxList<File> images = <File>[].obs;
  final Rx<File?> pendingVideo = Rx<File?>(null);
  final RxString selectedGifUrl = ''.obs;
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final replyingTo = Rxn<MessageModel>();
  final editingMessage = Rxn<MessageModel>();
  Timer? _messageSyncTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _messagesSubscription;
  DateTime? _lastServerSyncAt;
  bool _isMessageSyncing = false;
  bool _isLoadingOlder = false;
  bool _conversationHasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? _conversationOldestCursor;
  static const int _initialPageSize = 60;
  static const int _olderPageSize = 40;
  static const int _syncHeadSize = 40;
  final Map<String, MessageModel> _conversationMessages = {};
  var showScrollDownButton = false.obs;
  var scrollDownOpacity = 0.0.obs;
  var isLoadingOlder = false.obs;
  var hasMoreOlder = true.obs;
  var isOtherTyping = false.obs;
  var chatBgPaletteIndex = 0.obs;
  final RxBool isSelectionMode = false.obs;
  final RxSet<String> selectedMessageIds = <String>{}.obs;
  final RxBool showStarredOnly = false.obs;
  var isUploading = false.obs;
  var isRecording = false.obs;
  var recordingDuration = 0.obs;
  Timer? _typingDebounce;
  Timer? _recordingTimer;
  StreamSubscription<DocumentSnapshot>? _typingStream;
  bool _typingActive = false;
  int _lastTypingHeartbeatMs = 0;
  bool _recipientMuted = false;
  static const int _typingHeartbeatIntervalMs = 1500;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;
  static const int _localChatWindowLimit = 180;

  NetworkAwarenessService? get _network =>
      Get.isRegistered<NetworkAwarenessService>()
          ? Get.find<NetworkAwarenessService>()
          : null;
  final UserRepository _userRepository = UserRepository.ensure();

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;

  Duration get _serverSyncGap {
    if (_isOffline) return const Duration(days: 1);
    return _isOnWiFi
        ? const Duration(seconds: 12)
        : const Duration(seconds: 30);
  }

  ChatController({required this.chatID, required this.userID});

  @override
  void onInit() {
    super.onInit();
    getUserData();
    loadChatBackgroundPreference();
    unawaited(getData());
    _clearConversationUnread();
    _syncUnreadIndicatorsLocal();
    unawaited(_markConversationOpenedNow());
    textEditingController.addListener(() {
      textMesage.value = textEditingController.text;
      _onTypingChanged();
    });
    _listenTypingState();
    scrollController.addListener(() {
      final offset = scrollController.offset;
      final visible = offset > 500;
      showScrollDownButton.value = visible;
      if (!visible) {
        scrollDownOpacity.value = 0.0;
      } else {
        final strength = ((offset - 500) / 900).clamp(0.0, 1.0);
        scrollDownOpacity.value = (0.45 + (strength * 0.55)).clamp(0.45, 1.0);
      }
      if (scrollController.hasClients &&
          scrollController.position.maxScrollExtent > 0 &&
          offset > (scrollController.position.maxScrollExtent - 280)) {
        loadOlderMessages();
      }
    });
  }

  Future<void> _clearConversationUnread() =>
      _ChatControllerConversationX(this)._clearConversationUnread();

  void _syncUnreadIndicatorsLocal() =>
      _ChatControllerConversationX(this)._syncUnreadIndicatorsLocal();

  @override
  void onClose() {
    unawaited(_markConversationOpenedNow());
    _messageSyncTimer?.cancel();
    _messagesSubscription?.cancel();
    _typingStream?.cancel();
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _clearTyping();
    super.onClose();
  }

  Future<void> _markConversationOpenedNow() =>
      _ChatControllerConversationX(this)._markConversationOpenedNow();

  Future<void> _markConversationOpenedAt(int timestampMs) =>
      _ChatControllerConversationX(this)._markConversationOpenedAt(
        timestampMs,
      );

  void getUserData() => _ChatControllerConversationX(this).getUserData();

  void scrollToBottom() => _ChatControllerConversationX(this).scrollToBottom();

  void _onTypingChanged() =>
      _ChatControllerConversationX(this)._onTypingChanged();

  void _clearTyping() => _ChatControllerConversationX(this)._clearTyping();

  void _listenTypingState() =>
      _ChatControllerConversationX(this)._listenTypingState();

  Future<void> getData() => _ChatControllerConversationX(this).getData();

  Future<void> loadChatBackgroundPreference() =>
      _ChatControllerConversationX(this).loadChatBackgroundPreference();

  Future<void> setChatBackgroundPreference(int index) =>
      _ChatControllerConversationX(this).setChatBackgroundPreference(index);

  Future<void> _syncMessages({required bool forceServer}) =>
      _ChatControllerConversationX(this)
          ._syncMessages(forceServer: forceServer);

  Future<void> loadOlderMessages() =>
      _ChatControllerConversationX(this).loadOlderMessages();

  Future<void> jumpToMessageByRawId(String rawId) =>
      _ChatControllerConversationX(this).jumpToMessageByRawId(rawId);

  Future<void> archiveCurrentChat() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final convDoc = await _conversationRepository.getConversation(
        chatID,
        preferCache: true,
        cacheOnly: false,
      );
      if (convDoc != null) {
        await _conversationRepository.setArchived(
          currentUid: uid,
          otherUserId: userID,
          chatId: chatID,
          archived: true,
        );
      }
    } catch (_) {}
  }

  void startReply(MessageModel model) {
    replyingTo.value = model;
    editingMessage.value = null;
    focus.requestFocus();
  }

  void startEdit(MessageModel model) {
    if (model.userID != FirebaseAuth.instance.currentUser!.uid) return;
    if (model.metin.trim().isEmpty) return;
    editingMessage.value = model;
    replyingTo.value = null;
    textEditingController.text = model.metin;
    textMesage.value = model.metin;
    focus.requestFocus();
  }

  void clearComposerAction() {
    replyingTo.value = null;
    editingMessage.value = null;
    selectedGifUrl.value = '';
  }

  Future<void> pickGif(BuildContext context) async {
    final url = await GiphyPickerService.pickGifUrl(
      context,
      randomId: 'turqapp_chat_$chatID',
    );
    if (url != null && url.trim().isNotEmpty) {
      selectedGifUrl.value = url.trim();
      focus.unfocus();
    }
  }

  void startSelectionMode([String? rawId]) {
    isSelectionMode.value = true;
    if (rawId != null && rawId.isNotEmpty) {
      toggleSelection(rawId);
    }
  }

  void stopSelectionMode() {
    isSelectionMode.value = false;
    selectedMessageIds.clear();
  }

  void toggleSelection(String rawId) {
    if (rawId.isEmpty) return;
    final next = Set<String>.from(selectedMessageIds);
    if (next.contains(rawId)) {
      next.remove(rawId);
    } else {
      next.add(rawId);
    }
    selectedMessageIds
      ..clear()
      ..addAll(next);
    if (selectedMessageIds.isEmpty) {
      isSelectionMode.value = false;
    } else {
      isSelectionMode.value = true;
    }
  }

  void toggleStarredFilter() {
    showStarredOnly.value = !showStarredOnly.value;
  }

  List<MessageModel> get filteredMessages {
    if (!showStarredOnly.value) return messages;
    return messages.where((m) => m.isStarred).toList();
  }

  Future<void> toggleStarMessage(MessageModel model) async {
    try {
      final convRef =
          FirebaseFirestore.instance.collection("conversations").doc(chatID);
      final msgRef = convRef.collection("messages").doc(model.rawDocID);
      await msgRef.set({
        "isStarred": !model.isStarred,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> deleteSelectedMessages() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || selectedMessageIds.isEmpty) return;
    try {
      final convRef =
          FirebaseFirestore.instance.collection("conversations").doc(chatID);
      final batch = FirebaseFirestore.instance.batch();
      for (final rawId in selectedMessageIds) {
        final ref = convRef.collection("messages").doc(rawId);
        batch.set(
          ref,
          {
            "deletedFor": FieldValue.arrayUnion([uid])
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      final toRemove = Set<String>.from(selectedMessageIds);
      _conversationMessages
          .removeWhere((_, m) => toRemove.contains(m.rawDocID));
      selectedMessageIds.clear();
      isSelectionMode.value = false;
      _refreshMergedMessages();
    } catch (e) {
      AppSnackbar("Hata", "Mesajlar silinemedi");
    }
  }

  void _applyConversationSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool replace,
  }) {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;
    if (replace) _conversationMessages.clear();
    final List<String> unseenRawDocIds = [];
    final List<String> undeliveredRawDocIds = [];
    int latestSeenTs = 0;

    for (final doc in docs) {
      final data = doc.data();
      final senderId = data["senderId"] ?? "";
      final deletedFor = List<String>.from(data["deletedFor"] ?? []);
      if (deletedFor.contains(currentUID)) {
        _conversationMessages.remove("conv_${doc.id}");
        continue;
      }
      final status = data["status"] ?? "";
      final seenBy = List<String>.from(data["seenBy"] ?? []);
      final model = MessageModel.fromConversationSnapshot(doc);
      _conversationMessages[model.docID] = model;
      final ts = model.timeStamp.toInt();
      if (ts > latestSeenTs) latestSeenTs = ts;

      if (senderId != currentUID && !seenBy.contains(currentUID)) {
        unseenRawDocIds.add(doc.id);
      }

      // Mark other user's "sent" messages as "delivered" when we see them
      if (senderId != currentUID && status == "sent") {
        undeliveredRawDocIds.add(doc.id);
      }
    }

    final convRef =
        FirebaseFirestore.instance.collection("conversations").doc(chatID);

    if (unseenRawDocIds.isNotEmpty || undeliveredRawDocIds.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final rawId in unseenRawDocIds.take(25)) {
        final msgRef = convRef.collection("messages").doc(rawId);
        batch.update(msgRef, {
          "seenBy": FieldValue.arrayUnion([currentUID]),
          "status": "read",
        });
      }
      for (final rawId in undeliveredRawDocIds.take(25)) {
        if (!unseenRawDocIds.contains(rawId)) {
          final msgRef = convRef.collection("messages").doc(rawId);
          batch.update(msgRef, {"status": "delivered"});
        }
      }
      batch.commit().then((_) {
        return _conversationRepository.setUnreadCount(
          chatId: chatID,
          currentUid: currentUID,
          unreadCount: 0,
        );
      }).catchError((_) => null);
    }

    if (latestSeenTs > 0) {
      unawaited(_markConversationOpenedAt(latestSeenTs));
    }
  }

  void _refreshMergedMessages() {
    final merged = <MessageModel>[..._conversationMessages.values];
    merged.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    messages.value = merged;
    unawaited(_saveLocalConversationWindow(merged));
  }

  String get _localChatWindowKey => "chat_window_cache_$chatID";

  Future<bool> _loadLocalConversationWindow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localChatWindowKey);
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;

      final restored = <MessageModel>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final m = _deserializeLocalMessage(Map<String, dynamic>.from(item));
        if (m != null) restored.add(m);
      }
      if (restored.isEmpty) return false;
      restored.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
      messages.value = restored;
      return true;
    } catch (_) {}
    return false;
  }

  Future<void> _saveLocalConversationWindow(List<MessageModel> input) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = input.take(_localChatWindowLimit).toList();
      final payload = list.map(_serializeLocalMessage).toList();
      await prefs.setString(_localChatWindowKey, jsonEncode(payload));
    } catch (_) {}
  }

  Map<String, dynamic> _serializeLocalMessage(MessageModel m) {
    return {
      "docID": m.docID,
      "rawDocID": m.rawDocID,
      "source": m.source,
      "timeStamp": m.timeStamp,
      "userID": m.userID,
      "lat": m.lat,
      "long": m.long,
      "postType": m.postType,
      "postID": m.postID,
      "imgs": m.imgs,
      "video": m.video,
      "isRead": m.isRead,
      "kullanicilar": m.kullanicilar,
      "begeniler": m.begeniler,
      "metin": m.metin,
      "sesliMesaj": m.sesliMesaj,
      "kisiAdSoyad": m.kisiAdSoyad,
      "kisiTelefon": m.kisiTelefon,
      "isEdited": m.isEdited,
      "isUnsent": m.isUnsent,
      "isForwarded": m.isForwarded,
      "replyMessageId": m.replyMessageId,
      "replySenderId": m.replySenderId,
      "replyText": m.replyText,
      "replyType": m.replyType,
      "reactions": m.reactions,
      "status": m.status,
      "videoThumbnail": m.videoThumbnail,
      "audioDurationMs": m.audioDurationMs,
    };
  }

  MessageModel? _deserializeLocalMessage(Map<String, dynamic> data) {
    try {
      return MessageModel(
        docID: (data["docID"] ?? "").toString(),
        rawDocID: (data["rawDocID"] ?? "").toString(),
        source: (data["source"] ?? "conversation").toString(),
        timeStamp: data["timeStamp"] is num ? data["timeStamp"] as num : 0,
        userID: (data["userID"] ?? "").toString(),
        lat: data["lat"] is num ? data["lat"] as num : 0,
        long: data["long"] is num ? data["long"] as num : 0,
        postType: (data["postType"] ?? "").toString(),
        postID: (data["postID"] ?? "").toString(),
        imgs: List<String>.from(data["imgs"] ?? const []),
        video: (data["video"] ?? "").toString(),
        isRead: data["isRead"] == true,
        kullanicilar: List<String>.from(data["kullanicilar"] ?? const []),
        metin: (data["metin"] ?? "").toString(),
        sesliMesaj: (data["sesliMesaj"] ?? "").toString(),
        kisiAdSoyad: (data["kisiAdSoyad"] ?? "").toString(),
        kisiTelefon: (data["kisiTelefon"] ?? "").toString(),
        begeniler: List<String>.from(data["begeniler"] ?? const []),
        isEdited: data["isEdited"] == true,
        isUnsent: data["isUnsent"] == true,
        isForwarded: data["isForwarded"] == true,
        replyMessageId: (data["replyMessageId"] ?? "").toString(),
        replySenderId: (data["replySenderId"] ?? "").toString(),
        replyText: (data["replyText"] ?? "").toString(),
        replyType: (data["replyType"] ?? "").toString(),
        reactions: Map<String, List<String>>.from(
          (data["reactions"] as Map? ?? {}).map(
            (k, v) => MapEntry(
              k.toString(),
              List<String>.from(v ?? const []),
            ),
          ),
        ),
        status: (data["status"] ?? "").toString(),
        videoThumbnail: (data["videoThumbnail"] ?? "").toString(),
        audioDurationMs: data["audioDurationMs"] is num
            ? (data["audioDurationMs"] as num).toInt()
            : 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveCounterpartUserId() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (currentUid.isEmpty) return null;

    final candidates = <String>{};
    final fromParam = userID.trim();
    if (fromParam.isNotEmpty) candidates.add(fromParam);

    final parts = chatID.split("_");
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) candidates.add(trimmed);
    }

    try {
      final data = await _conversationRepository.getConversation(
        chatID,
        preferCache: true,
        cacheOnly: false,
      );
      if (data != null) {
        final participants = data["participants"];
        if (participants is List) {
          for (final p in participants) {
            final uid = p.toString().trim();
            if (uid.isNotEmpty) candidates.add(uid);
          }
        }
        final uid1 = (data["userID1"] ?? "").toString().trim();
        final uid2 = (data["userID2"] ?? "").toString().trim();
        if (uid1.isNotEmpty) candidates.add(uid1);
        if (uid2.isNotEmpty) candidates.add(uid2);
      }
    } catch (_) {}

    for (final uid in candidates) {
      if (uid != currentUid) return uid;
    }
    return null;
  }

  Map<String, int> _sanitizeUnreadMap(
    dynamic raw,
    List<String> participants,
  ) {
    final source = raw is Map ? raw : const <String, dynamic>{};
    final result = <String, int>{};
    for (final uid in participants) {
      final value = source[uid];
      if (value is int) {
        result[uid] = value < 0 ? 0 : value;
      } else if (value is num) {
        final parsed = value.toInt();
        result[uid] = parsed < 0 ? 0 : parsed;
      } else if (value is String) {
        final parsed = int.tryParse(value) ?? 0;
        result[uid] = parsed < 0 ? 0 : parsed;
      } else {
        result[uid] = 0;
      }
    }
    return result;
  }

  Map<String, bool> _sanitizeBoolParticipantMap(
    dynamic raw,
    List<String> participants, {
    bool defaultValue = false,
  }) {
    final source = raw is Map ? raw : const <String, dynamic>{};
    final result = <String, bool>{};
    for (final uid in participants) {
      final value = source[uid];
      if (value is bool) {
        result[uid] = value;
      } else if (value is num) {
        result[uid] = value != 0;
      } else {
        result[uid] = defaultValue;
      }
    }
    return result;
  }

  Map<String, int> _sanitizeIntParticipantMap(
    dynamic raw,
    List<String> participants, {
    int defaultValue = 0,
    bool nonNegative = true,
  }) {
    final source = raw is Map ? raw : const <String, dynamic>{};
    final result = <String, int>{};
    for (final uid in participants) {
      final value = source[uid];
      int parsed;
      if (value is int) {
        parsed = value;
      } else if (value is num) {
        parsed = value.toInt();
      } else if (value is String) {
        parsed = int.tryParse(value) ?? defaultValue;
      } else {
        parsed = defaultValue;
      }
      if (nonNegative && parsed < 0) parsed = 0;
      result[uid] = parsed;
    }
    return result;
  }

  Future<void> _ensureConversationReady({
    required String targetUserId,
    required String previewText,
    required int nowMs,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final participants = [currentUid, targetUserId]..sort();
    final convRef =
        FirebaseFirestore.instance.collection("conversations").doc(chatID);
    final convData = await _conversationRepository.getConversation(
      chatID,
      preferCache: true,
      cacheOnly: false,
    );

    if (convData == null) {
      await convRef.set({
        "participants": participants,
        "userID1": participants.first,
        "userID2": participants.last,
        "lastMessage": previewText,
        "lastMessageAt": nowMs,
        "lastMessageAtMs": nowMs,
        "lastSenderId": currentUid,
        "archived": {
          currentUid: false,
          targetUserId: false,
        },
        "unread": {
          currentUid: 0,
          targetUserId: 1,
        },
        "typing": {
          currentUid: 0,
          targetUserId: 0,
        },
        "muted": {
          currentUid: false,
          targetUserId: false,
        },
        "pinned": {
          currentUid: false,
          targetUserId: false,
        },
        "chatBg": {
          currentUid: 0,
          targetUserId: 0,
        },
      });
      return;
    }

    final data = convData;
    final existingParticipants = data["participants"] is List
        ? List<String>.from(
            (data["participants"] as List).map((e) => e.toString()),
          )
        : <String>[];
    final hasCanonicalParticipants = existingParticipants.length == 2 &&
        existingParticipants.contains(currentUid) &&
        existingParticipants.contains(targetUserId);

    final unread = _sanitizeUnreadMap(data["unread"], participants);
    unread[currentUid] = 0;
    unread[targetUserId] = (unread[targetUserId] ?? 0) + 1;
    final archived = _sanitizeBoolParticipantMap(
      data["archived"],
      participants,
      defaultValue: false,
    );
    archived[currentUid] = false;
    archived[targetUserId] = false;
    final typing = _sanitizeIntParticipantMap(
      data["typing"],
      participants,
      defaultValue: 0,
      nonNegative: true,
    );
    final muted = _sanitizeBoolParticipantMap(
      data["muted"],
      participants,
      defaultValue: false,
    );
    final pinned = _sanitizeBoolParticipantMap(
      data["pinned"],
      participants,
      defaultValue: false,
    );
    final chatBg = _sanitizeIntParticipantMap(
      data["chatBg"],
      participants,
      defaultValue: 0,
      nonNegative: true,
    );

    await convRef.set({
      if (!hasCanonicalParticipants) "participants": participants,
      if (!hasCanonicalParticipants) "userID1": participants.first,
      if (!hasCanonicalParticipants) "userID2": participants.last,
      "lastMessage": previewText,
      "lastMessageAt": nowMs,
      "lastMessageAtMs": nowMs,
      "lastSenderId": currentUid,
      "archived": archived,
      "unread": unread,
      "typing": typing,
      "muted": muted,
      "pinned": pinned,
      "chatBg": chatBg,
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage({
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
    String? textOverride,
    String? replyTextOverride,
    String? replyTypeOverride,
    String? replySenderIdOverride,
    String? replyMessageIdOverride,
  }) async {
    final text = (textOverride ?? textEditingController.text).trim();

    // 1. Küfür kontrolü
    if (text.isNotEmpty && kufurKontrolEt(text)) {
      AppSnackbar(
        "Topluluk Kurallarına Aykırı",
        "Göndermeye çalıştığınız mesaj uygunsuz içerik içeriyor. Lütfen saygılı bir dil kullanın.",
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      return;
    }

    if (editingMessage.value != null) {
      final editing = editingMessage.value!;
      if (text.isEmpty) return;
      await _editMessage(editing, text);
      textEditingController.clear();
      textMesage.value = "";
      editingMessage.value = null;
      return;
    }

    // 2. Mesaj koşulları
    if (text.isNotEmpty ||
        (imageUrls?.isNotEmpty ?? false) ||
        latLng != null ||
        (kisiAdSoyad?.isNotEmpty ?? false) ||
        (postID?.isNotEmpty ?? false) ||
        (gif?.isNotEmpty ?? false) ||
        (videoUrl?.isNotEmpty ?? false) ||
        (audioUrl?.isNotEmpty ?? false)) {
      // Notif body
      String notifBody;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        notifBody = "Bir video gönderdi";
      } else if (audioUrl != null && audioUrl.isNotEmpty) {
        notifBody = "Sesli mesaj gönderdi";
      } else if (imageUrls != null && imageUrls.isNotEmpty) {
        notifBody = "${imageUrls.length} adet resim gönderdi";
      } else if (postID != null && postID.isNotEmpty) {
        notifBody = "Bir gönderi paylaştı";
      } else if (latLng != null) {
        notifBody = "Bir konum gönderdi";
      } else if (kisiAdSoyad != null && kisiAdSoyad.isNotEmpty) {
        notifBody = "Bir rehber bilgisi paylaştı";
      } else if (gif != null && gif.isNotEmpty) {
        notifBody = "Bir GIF gönderdi";
      } else {
        notifBody = text;
      }

      final now = DateTime.now();
      final hasExternalReply = (replyTextOverride ?? "").trim().isNotEmpty;
      final replyTextFinal = (replyTextOverride ?? "").trim();
      final replyTypeFinal = (replyTypeOverride ?? "text").trim();
      final replySenderFinal =
          (replySenderIdOverride ?? FirebaseAuth.instance.currentUser!.uid)
              .trim();
      final replyMessageFinal =
          (replyMessageIdOverride ?? "preview_${now.microsecondsSinceEpoch}")
              .trim();

      String inferredReplyText = "";
      String inferredReplyType = "text";
      String inferredReplyTarget = "";
      final repliedModel = replyingTo.value;
      if (!hasExternalReply && repliedModel != null) {
        inferredReplyTarget = repliedModel.rawDocID;
        if (repliedModel.video.isNotEmpty) {
          inferredReplyType = "video";
          inferredReplyText = "🎥 Video";
          inferredReplyTarget = repliedModel.video;
        } else if (repliedModel.imgs.isNotEmpty) {
          inferredReplyType = "media";
          inferredReplyText = "📷 Fotoğraf";
          inferredReplyTarget = repliedModel.imgs.first;
        } else if (repliedModel.sesliMesaj.isNotEmpty) {
          inferredReplyType = "audio";
          inferredReplyText = "🎤 Ses";
        } else if (repliedModel.lat != 0 || repliedModel.long != 0) {
          inferredReplyType = "location";
          inferredReplyText = "📍 Konum";
        } else if (repliedModel.postID.trim().isNotEmpty) {
          inferredReplyType = "post";
          inferredReplyText = "🔗 Gönderi";
          inferredReplyTarget = repliedModel.postID.trim();
        } else if (repliedModel.kisiAdSoyad.trim().isNotEmpty) {
          inferredReplyType = "contact";
          inferredReplyText = "👤 Kişi";
        } else {
          inferredReplyType = "text";
          inferredReplyText = repliedModel.metin.trim().isNotEmpty
              ? repliedModel.metin
              : "Mesaj";
        }
      }

      final messageType = _resolveMessageType(
        text: text,
        imageUrls: imageUrls,
        latLng: latLng,
        kisiAdSoyad: kisiAdSoyad,
        postID: postID,
        gif: gif,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
      );

      final conversationMessageData = {
        "senderId": FirebaseAuth.instance.currentUser!.uid,
        "text": text,
        "createdDate": now.millisecondsSinceEpoch,
        "seenBy": [FirebaseAuth.instance.currentUser!.uid],
        "type": messageType,
        "mediaUrls": gif != null ? [gif] : (imageUrls ?? []),
        "likes": <String>[],
        "isDeleted": false,
        "isEdited": false,
        "forwarded": false,
        "unsent": false,
        "audioUrl": audioUrl ?? "",
        "audioDurationMs": audioDurationMs ?? 0,
        "videoUrl": videoUrl ?? "",
        "videoThumbnail": videoThumbnail ?? "",
        "status": "sent",
        "reactions": <String, List<String>>{},
        if (latLng != null)
          "location": {
            "lat": latLng.latitude.toDouble(),
            "lng": latLng.longitude.toDouble(),
            "name": text,
          },
        if (kisiAdSoyad != null && kisiAdSoyad.isNotEmpty)
          "contact": {
            "name": kisiAdSoyad,
            "phone": kisiTelefon ?? "",
          },
        if (postID != null && postID.isNotEmpty)
          "postRef": {
            "postId": postID,
            "postType": postType ?? "",
            "previewText": "",
            "previewImageUrl": "",
          },
        if (hasExternalReply)
          "replyTo": {
            "messageId": replyMessageFinal,
            "senderId": replySenderFinal,
            "text": replyTextFinal,
            "type": replyTypeFinal.isEmpty ? "text" : replyTypeFinal,
          },
        if (!hasExternalReply && replyingTo.value != null)
          "replyTo": {
            "messageId": inferredReplyTarget,
            "senderId": replyingTo.value!.userID,
            "text": inferredReplyText,
            "type": inferredReplyType,
          },
      };

      final previewText = _buildLastMessageText(
        text: text,
        imageUrls: imageUrls,
        latLng: latLng,
        kisiAdSoyad: kisiAdSoyad,
        postID: postID,
        gif: gif,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
      );

      try {
        final currentUid = FirebaseAuth.instance.currentUser!.uid;
        final resolvedTargetUid = await _resolveCounterpartUserId();
        final targetUidForConversation = resolvedTargetUid ?? userID;
        final convRef =
            FirebaseFirestore.instance.collection("conversations").doc(chatID);
        await _ensureConversationReady(
          targetUserId: targetUidForConversation,
          previewText: previewText,
          nowMs: now.millisecondsSinceEpoch,
        );
        final addedRef =
            await convRef.collection("messages").add(conversationMessageData);

        // Anında UI güncellemesi: sunucu sync beklemeden mesaj listesine düşür.
        try {
          final optimistic = MessageModel.fromConversationData(
            conversationMessageData,
            addedRef.id,
          );
          _conversationMessages[optimistic.docID] = optimistic;
          _refreshMergedMessages();
        } catch (_) {
          // Optimistic UI başarısız olsa bile mesaj gönderildi, sync ile gelecek.
          _syncMessages(forceServer: true);
        }

        // Notifikasyon gönder (hata olursa mesaj zaten gönderildi)
        if (!_recipientMuted &&
            resolvedTargetUid != null &&
            resolvedTargetUid.isNotEmpty &&
            resolvedTargetUid != currentUid) {
          try {
            NotificationService.instance.sendNotification(
              token: "",
              title: nickname.value,
              body: notifBody,
              docID: chatID,
              type: "Chat",
              targetUserID: resolvedTargetUid,
            );
          } catch (_) {}
        }
      } catch (_) {
        AppSnackbar("Hata", "Mesaj gönderilemedi. Lütfen tekrar dene.");
      }

      if (textOverride == null) {
        textEditingController.clear();
      }
      clearComposerAction();
      if (Get.isRegistered<ChatListingController>()) {
        Get.find<ChatListingController>().getList();
      }
    }
  }

  Future<void> sendExternalText(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await sendMessage(textOverride: clean);
  }

  Future<void> sendExternalReplyText(
    String text, {
    required String replyText,
    required String replyType,
    required String replyTarget,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await sendMessage(
      textOverride: clean,
      replyTextOverride: replyText,
      replyTypeOverride: replyType,
      replySenderIdOverride: FirebaseAuth.instance.currentUser?.uid ?? "",
      replyMessageIdOverride: replyTarget,
    );
  }

  Future<void> toggleReaction(MessageModel model, String emoji) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .doc(model.rawDocID);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final reactions = Map<String, dynamic>.from(data["reactions"] ?? {});
      final selectedUsers = List<String>.from(reactions[emoji] ?? const []);
      final wasSelected = selectedUsers.contains(uid);

      final updates = <String, dynamic>{};

      // Tek emoji kuralı: kullanıcıyı önce tüm reaction listelerinden kaldır.
      for (final entry in reactions.entries) {
        final key = entry.key.toString();
        final users = List<String>.from(entry.value ?? const []);
        if (users.contains(uid)) {
          updates["reactions.$key"] = FieldValue.arrayRemove([uid]);
        }
      }

      // Aynı emojiyse toggle-off, farklı emojiyse sadece seçilen emojiye ekle.
      if (!wasSelected) {
        updates["reactions.$emoji"] = FieldValue.arrayUnion([uid]);
      }

      tx.update(ref, updates);
    });
  }

  Future<void> unsendMessage(MessageModel model) async {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;
    if (model.userID != currentUID) return;

    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .doc(model.rawDocID)
        .update({
      "unsent": true,
      "text": "",
      "mediaUrls": <String>[],
      "location": FieldValue.delete(),
      "contact": FieldValue.delete(),
      "postRef": FieldValue.delete(),
    });
  }

  Future<void> _editMessage(MessageModel model, String newText) async {
    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .doc(model.rawDocID)
        .update({
      "text": newText,
      "isEdited": true,
    });
  }

  Future<void> openForwardPicker(MessageModel model) async {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;
    final docs = await _conversationRepository.fetchUserConversations(
      currentUID,
      preferCache: true,
      cacheOnly: false,
    );
    final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      docs,
    )..sort((a, b) {
        final aTs = ((a.data()["lastMessageAt"] ?? 0) as num).toInt();
        final bTs = ((b.data()["lastMessageAt"] ?? 0) as num).toInt();
        return bTs.compareTo(aTs);
      });
    final snapDocs = sortedDocs.take(30).toList(growable: false);

    final items = <Map<String, String>>[];
    final otherIds = <String>[];
    for (final doc in snapDocs) {
      if (doc.id == chatID) continue;
      final participants = List<String>.from(doc.data()["participants"] ?? []);
      final other = participants.firstWhereOrNull((v) => v != currentUID);
      if (other == null || other.isEmpty) continue;
      otherIds.add(other);
    }

    final userMap = await _userRepository.getUsersRaw(otherIds);
    for (final doc in snapDocs) {
      if (doc.id == chatID) continue;
      final participants = List<String>.from(doc.data()["participants"] ?? []);
      final other = participants.firstWhereOrNull((v) => v != currentUID);
      if (other == null || other.isEmpty) continue;
      final userData = userMap[other];
      if (userData == null) continue;
      items.add({
        "chatID": doc.id,
        "userID": other,
        "nickname": (userData["displayName"] ??
                userData["username"] ??
                userData["nickname"] ??
                "")
            .toString(),
      });
    }

    if (items.isEmpty) {
      AppSnackbar("Bilgi", "İletilecek sohbet bulunamadı");
      return;
    }

    Get.bottomSheet(
      SafeArea(
        child: Container(
          color: Colors.white,
          child: ListView(
            shrinkWrap: true,
            children: items
                .map(
                  (e) => ListTile(
                    title: Text(
                      e["nickname"] ?? "",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                    onTap: () async {
                      Get.back();
                      await forwardMessage(model, e["chatID"]!, e["userID"]!);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> forwardMessage(
      MessageModel model, String targetChatId, String targetUserId) async {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;

    final convMessage = {
      "senderId": currentUID,
      "text": model.metin,
      "createdDate": DateTime.now().millisecondsSinceEpoch,
      "seenBy": [currentUID],
      "type": model.postID.isNotEmpty
          ? "post"
          : model.kisiAdSoyad.isNotEmpty
              ? "contact"
              : model.lat != 0
                  ? "location"
                  : model.imgs.isNotEmpty
                      ? "media"
                      : "text",
      "mediaUrls": model.imgs,
      "likes": <String>[],
      "isDeleted": false,
      "isEdited": false,
      "forwarded": true,
      "unsent": false,
      "reactions": <String, List<String>>{},
      if (model.kisiAdSoyad.isNotEmpty)
        "contact": {
          "name": model.kisiAdSoyad,
          "phone": model.kisiTelefon,
        },
      if (model.lat != 0)
        "location": {
          "lat": model.lat,
          "lng": model.long,
          "name": model.metin,
        },
      if (model.postID.isNotEmpty)
        "postRef": {
          "postId": model.postID,
          "postType": model.postType,
          "previewText": "",
          "previewImageUrl": "",
        },
      "forwardedFrom": {
        "conversationId": chatID,
        "messageId": model.rawDocID,
        "senderName": nickname.value,
      }
    };

    final previewText = model.metin.isNotEmpty ? model.metin : "İletilen mesaj";
    final convRef = FirebaseFirestore.instance
        .collection("conversations")
        .doc(targetChatId);
    final participants = [currentUID, targetUserId]..sort();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final convData = await _conversationRepository.getConversation(
      targetChatId,
      preferCache: true,
      cacheOnly: false,
    );

    if (convData == null) {
      await convRef.set({
        "participants": participants,
        "userID1": participants.first,
        "userID2": participants.last,
        "lastMessage": previewText,
        "lastMessageAt": nowMs,
        "lastMessageAtMs": nowMs,
        "lastSenderId": currentUID,
        "archived": {
          currentUID: false,
          targetUserId: false,
        },
        "unread": {
          currentUID: 0,
          targetUserId: 1,
        },
        "typing": {
          currentUID: 0,
          targetUserId: 0,
        },
        "muted": {
          currentUID: false,
          targetUserId: false,
        },
        "pinned": {
          currentUID: false,
          targetUserId: false,
        },
        "chatBg": {
          currentUID: 0,
          targetUserId: 0,
        },
      });
    } else {
      final data = convData;
      final existingParticipants = data["participants"] is List
          ? List<String>.from(
              (data["participants"] as List).map((e) => e.toString()),
            )
          : <String>[];
      final hasCanonicalParticipants = existingParticipants.length == 2 &&
          existingParticipants.contains(currentUID) &&
          existingParticipants.contains(targetUserId);
      final unread = _sanitizeUnreadMap(data["unread"], participants);
      unread[currentUID] = 0;
      unread[targetUserId] = (unread[targetUserId] ?? 0) + 1;
      final archived = _sanitizeBoolParticipantMap(
        data["archived"],
        participants,
        defaultValue: false,
      );
      archived[currentUID] = false;
      archived[targetUserId] = false;
      final typing = _sanitizeIntParticipantMap(
        data["typing"],
        participants,
        defaultValue: 0,
        nonNegative: true,
      );
      final muted = _sanitizeBoolParticipantMap(
        data["muted"],
        participants,
        defaultValue: false,
      );
      final pinned = _sanitizeBoolParticipantMap(
        data["pinned"],
        participants,
        defaultValue: false,
      );
      final chatBg = _sanitizeIntParticipantMap(
        data["chatBg"],
        participants,
        defaultValue: 0,
        nonNegative: true,
      );

      await convRef.set({
        if (!hasCanonicalParticipants) "participants": participants,
        if (!hasCanonicalParticipants) "userID1": participants.first,
        if (!hasCanonicalParticipants) "userID2": participants.last,
        "lastMessage": previewText,
        "lastMessageAt": nowMs,
        "lastMessageAtMs": nowMs,
        "lastSenderId": currentUID,
        "archived": archived,
        "unread": unread,
        "typing": typing,
        "muted": muted,
        "pinned": pinned,
        "chatBg": chatBg,
      }, SetOptions(merge: true));
    }

    await convRef.collection("messages").add(convMessage);

    AppSnackbar("İletildi", "Mesaj seçilen sohbete iletildi");
    if (Get.isRegistered<ChatListingController>()) {
      Get.find<ChatListingController>().getList();
    }
  }
}
