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
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Core/Camera/chat_camera_capture_view.dart';
import '../../Core/blocked_texts.dart';
import '../../Core/Services/optimized_nsfw_service.dart';
import '../../Models/message_model.dart';

class ChatController extends GetxController {
  String chatID;
  String userID;
  var nickname = "".obs;
  var pfImage = "".obs;
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
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;
  static const int _localChatWindowLimit = 180;

  NetworkAwarenessService? get _network =>
      Get.isRegistered<NetworkAwarenessService>()
          ? Get.find<NetworkAwarenessService>()
          : null;

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;

  Duration get _serverSyncGap {
    if (_isOffline) return const Duration(days: 1);
    return _isOnWiFi
        ? const Duration(seconds: 12)
        : const Duration(seconds: 30);
  }

  ChatController({required this.chatID, required this.userID});

  Future<void> _upsertLegacyMessageHead({
    required String lastMessage,
    required int timestampMs,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty) return;
    await FirebaseFirestore.instance.collection("message").doc(chatID).set({
      "deleted": <String>[],
      "timeStamp": timestampMs,
      "userID1": currentUid,
      "userID2": userID,
      "participants": [currentUid, userID],
      "lastMessage": lastMessage,
      "lastSenderId": currentUid,
    }, SetOptions(merge: true));
  }

  Future<void> _appendLegacyChatMessage({
    required String text,
    required List<String> imageUrls,
    required String videoUrl,
    required String videoThumbnail,
    required String audioUrl,
    required int audioDurationMs,
    required LatLng? latLng,
    required String? kisiAdSoyad,
    required String? kisiTelefon,
    required String? postID,
    required String? postType,
    required String? gif,
    required int timeStampMs,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection("message")
        .doc(chatID)
        .collection("Chat")
        .add({
      "timeStamp": timeStampMs,
      "userID": currentUid,
      "metin": text,
      "imgs": gif != null && gif.isNotEmpty ? [gif] : imageUrls,
      "video": videoUrl,
      "videoThumbnail": videoThumbnail,
      "sesliMesaj": audioUrl,
      "audioDurationMs": audioDurationMs,
      "lat": latLng?.latitude ?? 0,
      "long": latLng?.longitude ?? 0,
      "kisiAdSoyad": kisiAdSoyad ?? "",
      "kisiTelefon": kisiTelefon ?? "",
      "postID": postID ?? "",
      "postType": postType ?? "",
      "isRead": false,
      "begeniler": <String>[],
      "kullanicilar": <String>[],
    });
  }

  @override
  void onInit() {
    super.onInit();
    getUserData();
    _loadLocalConversationWindow();
    loadChatBackgroundPreference();
    getData();
    _clearConversationUnread();
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

  Future<void> _clearConversationUnread() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection("conversations")
          .doc(chatID)
          .set({"unread.$uid": 0}, SetOptions(merge: true));
    } catch (_) {}
  }

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

  Future<void> _markConversationOpenedNow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      "chat_last_opened_${uid}_$chatID",
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _markConversationOpenedAt(int timestampMs) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = "chat_last_opened_${uid}_$chatID";
    final old = prefs.getInt(key) ?? 0;
    if (timestampMs > old) {
      await prefs.setInt(key, timestampMs);
    }
  }

  void getUserData() async {
    try {
      final data = (await Get.find<UserProfileCacheService>().getProfile(
            userID,
            preferCache: true,
            cacheOnly: _isOffline,
          )) ??
          <String, dynamic>{};

      nickname.value = (data["nickname"] ?? "").toString();
      pfImage.value = (data["pfImage"] ?? data["photoUrl"] ?? "").toString();
      token.value = (data["token"] ?? "").toString();

      final firstName = (data["firstName"] ?? "").toString().trim();
      final lastName = (data["lastName"] ?? "").toString().trim();
      final full = "$firstName $lastName".trim();
      fullName.value = full.isNotEmpty
          ? full
          : (data["fullName"] ?? nickname.value).toString();
      bio.value = (data["bio"] ?? "").toString();

      followersCount.value = _asInt(
          data["followersCount"] ?? data["takipci"] ?? data["followerCount"]);
      followingCount.value = _asInt(
          data["followingCount"] ?? data["takip"] ?? data["followCount"]);
      postCount.value =
          _asInt(data["postCount"] ?? data["gonderi"] ?? data["postsCount"]);
    } catch (_) {}
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is List) return value.length;
    return 0;
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTypingChanged() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final text = textEditingController.text;
    if (text.isNotEmpty) {
      try {
        FirebaseFirestore.instance.collection("conversations").doc(chatID).set({
          "typing.$uid": DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      } catch (_) {}
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        _clearTyping();
      });
    } else {
      _clearTyping();
    }
  }

  void _clearTyping() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      FirebaseFirestore.instance
          .collection("conversations")
          .doc(chatID)
          .set({"typing.$uid": 0}, SetOptions(merge: true));
    } catch (_) {}
  }

  void _listenTypingState() {
    _typingStream = FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      final typing = data["typing"] as Map<String, dynamic>? ?? {};
      final otherTs = typing[userID] as num? ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      isOtherTyping.value = otherTs > 0 && (now - otherTs) < 3000;

      // Sohbet açıkken, conversation başındaki son mesaj zamanını "görüldü"
      // marker'ına yaz. Böylece sohbetten çıkınca yeni gibi koyulaşmaz.
      int lastMessageAtMs = 0;
      final lmAt = data["lastMessageAt"];
      if (lmAt is Timestamp) {
        lastMessageAtMs = lmAt.millisecondsSinceEpoch;
      } else {
        final fallback = data["lastMessageAtMs"];
        lastMessageAtMs =
            fallback is int ? fallback : int.tryParse("$fallback") ?? 0;
      }
      if (lastMessageAtMs > 0) {
        unawaited(_markConversationOpenedAt(lastMessageAtMs));
      }
    });
  }

  void getData() {
    _messageSyncTimer?.cancel();
    _messagesSubscription?.cancel();

    // İlk açılışta cache-first: ekrandaki mesajlar anında local cache'ten gelsin.
    _loadInitialMessages(forceServer: false);
    _listenRealtimeMessages();
    _messageSyncTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _syncMessages(forceServer: false);
    });
  }

  Future<void> loadChatBackgroundPreference() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection("conversations")
          .doc(chatID)
          .get();
      final data = doc.data() ?? <String, dynamic>{};
      final raw = (data["chatBg.$uid"] ?? data["chatBgIndex"]) as dynamic;
      int idx = 0;
      if (raw is int) {
        idx = raw;
      } else if (raw is num) {
        idx = raw.toInt();
      } else if (raw is String) {
        idx = int.tryParse(raw) ?? 0;
      }
      if (idx < 0) idx = 0;
      if (idx > 5) idx = 5;
      chatBgPaletteIndex.value = idx;
    } catch (_) {}
  }

  Future<void> setChatBackgroundPreference(int index) async {
    if (index < 0 || index > 5) return;
    chatBgPaletteIndex.value = index;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection("conversations")
          .doc(chatID)
          .set({
        "chatBg.$uid": index,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _listenRealtimeMessages() {
    _messagesSubscription = FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .orderBy("createdAt", descending: true)
        .limit(_syncHeadSize)
        .snapshots()
        .listen((snapshot) {
      _applyConversationSnapshot(snapshot.docs, replace: false);
      _refreshMergedMessages();
    }, onError: (_) {});
  }

  Future<void> _loadInitialMessages({required bool forceServer}) async {
    final cacheOnly = _isOffline;
    final shouldHitServer = !cacheOnly && forceServer;
    try {
      final convBase = FirebaseFirestore.instance
          .collection("conversations")
          .doc(chatID)
          .collection("messages")
          .orderBy("createdAt", descending: true);

      final conversationSnapshot = await _getWithCachePreference(
        convBase.limit(_initialPageSize),
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
      );

      _applyConversationSnapshot(conversationSnapshot.docs, replace: true);

      _conversationOldestCursor = conversationSnapshot.docs.isNotEmpty
          ? conversationSnapshot.docs.last
          : _conversationOldestCursor;

      _conversationHasMore =
          conversationSnapshot.docs.length >= _initialPageSize;
      _updateHasMoreOlder();
      _refreshMergedMessages();
      _lastServerSyncAt = DateTime.now();
    } catch (_) {}
  }

  Future<void> _syncMessages({required bool forceServer}) async {
    if (_isMessageSyncing) return;
    final cacheOnly = _isOffline;
    final shouldHitServer = !cacheOnly &&
        (forceServer ||
            _lastServerSyncAt == null ||
            DateTime.now().difference(_lastServerSyncAt!) > _serverSyncGap);
    _isMessageSyncing = true;
    try {
      final convQuery = FirebaseFirestore.instance
          .collection("conversations")
          .doc(chatID)
          .collection("messages")
          .orderBy("createdAt", descending: true)
          .limit(_syncHeadSize);

      final conversationSnapshot = await _getWithCachePreference(
        convQuery,
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
      );

      _applyConversationSnapshot(conversationSnapshot.docs, replace: false);
      _refreshMergedMessages();

      if (shouldHitServer) {
        _lastServerSyncAt = DateTime.now();
      }
    } catch (_) {
    } finally {
      _isMessageSyncing = false;
    }
  }

  Future<void> loadOlderMessages() async {
    if (_isLoadingOlder) return;
    if (!_conversationHasMore) return;
    _isLoadingOlder = true;
    isLoadingOlder.value = true;
    try {
      final cacheOnly = _isOffline;
      final preferCache = true;

      if (_conversationHasMore && _conversationOldestCursor != null) {
        final convQuery = FirebaseFirestore.instance
            .collection("conversations")
            .doc(chatID)
            .collection("messages")
            .orderBy("createdAt", descending: true)
            .startAfterDocument(_conversationOldestCursor!)
            .limit(_olderPageSize);
        final convSnapshot = await _getWithCachePreference(
          convQuery,
          preferCache: preferCache,
          cacheOnly: cacheOnly,
        );
        _applyConversationSnapshot(convSnapshot.docs, replace: false);
        if (convSnapshot.docs.isNotEmpty) {
          _conversationOldestCursor = convSnapshot.docs.last;
        }
        _conversationHasMore = convSnapshot.docs.length >= _olderPageSize;
      }

      _updateHasMoreOlder();
      _refreshMergedMessages();
    } catch (_) {
    } finally {
      _isLoadingOlder = false;
      isLoadingOlder.value = false;
    }
  }

  Future<void> jumpToMessageByRawId(String rawId) async {
    if (rawId.trim().isEmpty) return;

    int index = messages.indexWhere((m) => m.rawDocID == rawId);
    var attempts = 0;
    while (index < 0 && attempts < 4 && hasMoreOlder.value) {
      await loadOlderMessages();
      index = messages.indexWhere((m) => m.rawDocID == rawId);
      attempts++;
    }

    if (index < 0) {
      AppSnackbar("Bilgi", "Yanıtlanan mesaj bulunamadı");
      return;
    }

    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final target =
        (index * 120.0).clamp(0.0, position.maxScrollExtent).toDouble();
    await scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  void _updateHasMoreOlder() {
    hasMoreOlder.value = _conversationHasMore;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getWithCachePreference(
    Query<Map<String, dynamic>> query, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    if (preferCache) {
      try {
        return await query.get(const GetOptions(source: Source.cache));
      } catch (_) {}
    }
    if (cacheOnly) {
      return query.get(const GetOptions(source: Source.cache));
    }
    return query.get(const GetOptions(source: Source.server));
  }

  Future<void> archiveCurrentChat() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final convRef =
          FirebaseFirestore.instance.collection("conversations").doc(chatID);
      final convDoc = await convRef.get();
      if (convDoc.exists) {
        await convRef.set({"archived.$uid": true}, SetOptions(merge: true));
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
    } catch (e) {
      debugPrint("[Chat] toggleStarMessage error: $e");
    }
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
      batch.set(convRef, {"unread.$currentUID": 0}, SetOptions(merge: true));
      batch.commit().catchError((_) => null);
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

  Future<void> _loadLocalConversationWindow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localChatWindowKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final restored = <MessageModel>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final m = _deserializeLocalMessage(Map<String, dynamic>.from(item));
        if (m != null) restored.add(m);
      }
      if (restored.isEmpty) return;
      restored.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
      messages.value = restored;
    } catch (_) {}
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
    print("🚀 sendMessage BAŞLADI");

    final text = (textOverride ?? textEditingController.text).trim();
    print("✏️ Mesaj text: '$text'");

    // 1. Küfür kontrolü
    if (text.isNotEmpty && kufurKontrolEt(text)) {
      print("⛔️ Küfür bulundu, return!");
      AppSnackbar(
        "Topluluk Kurallarına Aykırı",
        "Göndermeye çalıştığınız mesaj uygunsuz içerik içeriyor. Lütfen saygılı bir dil kullanın.",
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      return;
    }
    print("✅ Küfür yok, devam!");

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
      print("📨 Mesaj gönderme koşulları sağlandı");

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
      print("🔔 Notif body: $notifBody");

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
        "createdAt": Timestamp.fromDate(now),
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

      print("🗂 Mesaj data hazır, firestore'a ekleniyor...");

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
        final convRef =
            FirebaseFirestore.instance.collection("conversations").doc(chatID);
        // IMPORTANT: Parent conversation must exist (with participants)
        // before writing into subcollection messages (Firestore rules).
        await convRef.set({
          "participants": [FirebaseAuth.instance.currentUser!.uid, userID],
          "lastMessage": previewText,
          "lastMessageAt": FieldValue.serverTimestamp(),
          "lastMessageAtMs": now.millisecondsSinceEpoch,
          "lastSenderId": FirebaseAuth.instance.currentUser!.uid,
          "archived.${FirebaseAuth.instance.currentUser!.uid}": false,
          "archived.$userID": false,
          "unread.${FirebaseAuth.instance.currentUser!.uid}": 0,
          "unread.$userID": FieldValue.increment(1),
        }, SetOptions(merge: true));
        final addedRef =
            await convRef.collection("messages").add(conversationMessageData);

        bool recipientMuted = false;
        try {
          final convSnap = await convRef.get();
          final convData = convSnap.data() ?? <String, dynamic>{};
          final mutedMap = Map<String, dynamic>.from(convData["muted"] ?? {});
          recipientMuted = mutedMap[userID] == true;
        } catch (_) {}

        // Legacy mirror: keep "message" collection in sync as well.
        try {
          await _upsertLegacyMessageHead(
            lastMessage: previewText,
            timestampMs: now.millisecondsSinceEpoch,
          );
          await _appendLegacyChatMessage(
            text: text,
            imageUrls: imageUrls ?? const <String>[],
            videoUrl: videoUrl ?? "",
            videoThumbnail: videoThumbnail ?? "",
            audioUrl: audioUrl ?? "",
            audioDurationMs: audioDurationMs ?? 0,
            latLng: latLng,
            kisiAdSoyad: kisiAdSoyad,
            kisiTelefon: kisiTelefon,
            postID: postID,
            postType: postType,
            gif: gif,
            timeStampMs: now.millisecondsSinceEpoch,
          );
        } catch (_) {}

        print("✅ Firestore yazımı başarılı");

        // Anında UI güncellemesi: sunucu sync beklemeden mesaj listesine düşür.
        try {
          final optimistic = MessageModel.fromConversationSnapshot(
            await addedRef.get(),
          );
          _conversationMessages[optimistic.docID] = optimistic;
          _refreshMergedMessages();
        } catch (_) {
          // Optimistic UI başarısız olsa bile mesaj gönderildi, sync ile gelecek.
          _syncMessages(forceServer: true);
        }

        // Notifikasyon gönder (hata olursa mesaj zaten gönderildi)
        if (!recipientMuted) {
          try {
            NotificationService.instance.sendNotification(
              token: token.value,
              title: nickname.value,
              body: notifBody,
              docID: chatID,
              type: "Chat",
            );
            print("🔔 Notification gönderildi");
          } catch (_) {}
        } else {
          print("🔕 Sohbet sessizde: bildirim gönderilmedi");
        }
      } catch (e, s) {
        print("🔥 HATA: conversation yazımı başarısız: $e");
        print(s);
        AppSnackbar("Hata", "Mesaj gönderilemedi. Lütfen tekrar dene.");
      }

      print("🧹 TextEditingController temizleniyor...");
      if (textOverride == null) {
        textEditingController.clear();
      }
      clearComposerAction();
      if (Get.isRegistered<ChatListingController>()) {
        Get.find<ChatListingController>().getList();
      }
      print("🎉 MESAJ TAMAMEN GÖNDERİLDİ ve TEMİZLENDİ!");
    } else {
      print("❗️Hiçbir mesaj gönderme koşulu sağlanmadı, mesaj gönderilmiyor.");
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
    final snap = await FirebaseFirestore.instance
        .collection("conversations")
        .where("participants", arrayContains: currentUID)
        .orderBy("lastMessageAt", descending: true)
        .limit(30)
        .get();

    final items = <Map<String, String>>[];
    for (final doc in snap.docs) {
      if (doc.id == chatID) continue;
      final participants = List<String>.from(doc.data()["participants"] ?? []);
      final other = participants.firstWhereOrNull((v) => v != currentUID);
      if (other == null || other.isEmpty) continue;
      final userDoc =
          await FirebaseFirestore.instance.collection("users").doc(other).get();
      if (!userDoc.exists) continue;
      items.add({
        "chatID": doc.id,
        "userID": other,
        "nickname": userDoc.data()?["nickname"] ?? "",
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
      "createdAt": FieldValue.serverTimestamp(),
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

    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(targetChatId)
        .collection("messages")
        .add(convMessage);

    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(targetChatId)
        .set({
      "participants": [currentUID, targetUserId],
      "lastMessage": model.metin.isNotEmpty ? model.metin : "İletilen mesaj",
      "lastMessageAt": FieldValue.serverTimestamp(),
      "lastMessageAtMs": DateTime.now().millisecondsSinceEpoch,
      "lastSenderId": currentUID,
      "archived.$currentUID": false,
      "archived.$targetUserId": false,
      "unread.$currentUID": 0,
      "unread.$targetUserId": FieldValue.increment(1),
    }, SetOptions(merge: true));

    AppSnackbar("İletildi", "Mesaj seçilen sohbete iletildi");
    if (Get.isRegistered<ChatListingController>()) {
      Get.find<ChatListingController>().getList();
    }
  }

  Future<void> pickImage() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final files = await AppImagePickerService.pickImages(ctx, maxAssets: 10);
    if (files.isEmpty) return;

    // 2) NSFW tespiti (OptimizedNSFWService)
    for (final f in files) {
      final r = await OptimizedNSFWService.checkImage(f);
      if (r.isNSFW) {
        // Uygunsuz içerik varsa kullanıcıyı uyar, state'i güncelleme
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        return;
      }
    }

    // 3) Her şey temizse state'i set et
    images.value = files;
    pendingVideo.value = null;
    selection.value = 1;
  }

  Future<void> pickCameraImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    // NSFW tespiti (OptimizedNSFWService)
    final r = await OptimizedNSFWService.checkImage(file);
    if (r.isNSFW) {
      AppSnackbar(
        "Yükleme Başarısız!",
        "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      return;
    }

    // Temizse ekle
    images.value = [file];
    pendingVideo.value = null;
    selection.value = 1;
  }

  Future<void> uploadImageToStorage() async {
    if (images.isEmpty) return;
    isUploading.value = true;
    uploadPercent.value = 1;
    final storage = FirebaseStorage.instance;
    final uuid = Uuid();

    List<String> downloadUrls = [];

    try {
      // Not: Seçim aşamasında NSFW kontrolü zaten yapıldı.

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        File fileToUpload = image;

        try {
          final tempDir = Directory.systemTemp.path;
          final targetPath =
              '$tempDir/chat_img_${DateTime.now().millisecondsSinceEpoch}_$i.webp';
          final compressed = await FlutterImageCompress.compressAndGetFile(
            image.path,
            targetPath,
            quality: 82,
            minWidth: 1440,
            minHeight: 1440,
            keepExif: false,
            format: CompressFormat.webp,
          );
          if (compressed != null) {
            fileToUpload = File(compressed.path);
          }
        } catch (e) {
          print("Görsel sıkıştırma atlandı: $e");
        }

        final fileName = uuid.v4();

        final ref = storage.ref().child(
              'ChatAssets/$chatID/$fileName${DateTime.now().millisecondsSinceEpoch}.webp',
            );

        final bytes = await fileToUpload.readAsBytes();
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(
            contentType: "image/webp",
            cacheControl: 'public, max-age=31536000, immutable',
          ),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double percent =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          uploadPercent.value = percent;
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      uploadPercent.value = 0;
      isUploading.value = false;
      selection.value = 0;
      images.clear();

      await sendMessage(imageUrls: downloadUrls);
    } catch (e) {
      print("Resim upload error: $e");
      uploadPercent.value = 0;
      isUploading.value = false;
      images.clear();
      AppSnackbar("Hata", "Resim yüklenemedi: $e");
    }
  }

  Future<void> pickVideo() async {
    final XFile? pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (pickedFile == null) return;
    images.clear();
    pendingVideo.value = File(pickedFile.path);
    selection.value = 1;
  }

  Future<void> pickCameraVideo() async {
    final XFile? pickedFile = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 1),
    );
    if (pickedFile == null) return;
    images.clear();
    pendingVideo.value = File(pickedFile.path);
    selection.value = 1;
  }

  Future<void> openCustomCameraCapture() async {
    final result = await Get.to<ChatCameraCaptureResult>(
      () => const ChatCameraCaptureView(),
      transition: Transition.fadeIn,
    );
    if (result == null) return;

    if (result.mode == ChatCameraMode.photo) {
      final file = result.file;
      final r = await OptimizedNSFWService.checkImage(file);
      if (r.isNSFW) {
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        return;
      }
      images.value = [file];
      pendingVideo.value = null;
      selection.value = 1;
      return;
    }

    images.clear();
    pendingVideo.value = result.file;
    selection.value = 1;
  }

  Future<void> uploadPendingVideoToStorage() async {
    final file = pendingVideo.value;
    if (file == null) return;
    await _processAndSendVideo(file);
    pendingVideo.value = null;
    selection.value = 0;
  }

  void clearPendingMedia() {
    images.clear();
    pendingVideo.value = null;
    selection.value = 0;
  }

  Future<void> _processAndSendVideo(File videoFile) async {
    isUploading.value = true;
    uploadPercent.value = 1;
    final uuid = Uuid();
    final storage = FirebaseStorage.instance;

    try {
      // Zorunlu NSFW video kontrolü (upload öncesi).
      final nsfw = await OptimizedNSFWService.checkVideo(videoFile);
      if (nsfw.isNSFW) {
        isUploading.value = false;
        uploadPercent.value = 0;
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        return;
      }

      // 1. Compress video (skip if fails)
      File fileToUpload = videoFile;
      try {
        final compressed = await VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        if (compressed?.file != null) {
          fileToUpload = compressed!.file!;
        }
      } catch (e) {
        print("Video sıkıştırma atlandı: $e");
      }

      // 2. Generate thumbnail (skip if fails)
      Uint8List? thumbBytes;
      try {
        thumbBytes = await vt.VideoThumbnail.thumbnailData(
          video: videoFile.path,
          imageFormat: vt.ImageFormat.JPEG,
          maxWidth: 300,
          quality: 75,
        );
      } catch (e) {
        print("Thumbnail oluşturma atlandı: $e");
      }

      // 3. Upload video (chat akışı mp4 kalır)
      final videoFileName = uuid.v4();
      final videoRef = storage.ref().child(
            'ChatAssets/$chatID/videos/$videoFileName.mp4',
          );
      final videoUpload = videoRef.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: 'video/mp4',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );
      videoUpload.snapshotEvents.listen((snapshot) {
        uploadPercent.value =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      });
      final videoSnapshot = await videoUpload;
      final videoDownloadUrl = await videoSnapshot.ref.getDownloadURL();

      // 4. Upload thumbnail
      String thumbUrl = "";
      if (thumbBytes != null) {
        try {
          thumbUrl = await WebpUploadService.uploadBytesAsWebp(
            storage: storage,
            bytes: thumbBytes,
            storagePathWithoutExt:
                'ChatAssets/$chatID/videos/${videoFileName}_thumb',
          );
        } catch (e) {
          print("Thumbnail yükleme atlandı: $e");
        }
      }

      uploadPercent.value = 0;
      isUploading.value = false;

      // 5. Send message
      await sendMessage(
        videoUrl: videoDownloadUrl,
        videoThumbnail: thumbUrl,
      );
    } catch (e) {
      print("Video upload error: $e");
      uploadPercent.value = 0;
      isUploading.value = false;
      AppSnackbar("Hata", "Video yüklenirken bir hata oluştu");
    }
  }

  Future<void> startVoiceRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        AppSnackbar("İzin Gerekli", "Mikrofon izni verilmedi");
        return;
      }
      final dir = Directory.systemTemp;
      final path = '${dir.path}/${Uuid().v4()}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _recordingPath = path;
      isRecording.value = true;
      recordingDuration.value = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingDuration.value++;
      });
    } catch (e) {
      print("Ses kaydı başlatma hatası: $e");
      isRecording.value = false;
      AppSnackbar("Hata", "Ses kaydı başlatılamadı");
    }
  }

  Future<void> stopVoiceRecording() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    isRecording.value = false;
    final durationMs = recordingDuration.value * 1000;
    recordingDuration.value = 0;

    if (path == null || path.isEmpty) return;

    isUploading.value = true;
    uploadPercent.value = 1;
    try {
      final file = File(path);
      final storage = FirebaseStorage.instance;
      final fileName = Uuid().v4();
      final ref = storage.ref().child('ChatAssets/$chatID/voice/$fileName.m4a');
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'audio/mp4',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );
      uploadTask.snapshotEvents.listen((snapshot) {
        uploadPercent.value =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      });
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      uploadPercent.value = 0;
      isUploading.value = false;

      await sendMessage(audioUrl: downloadUrl, audioDurationMs: durationMs);
      _recordingPath = null;
    } catch (e) {
      print("Voice upload error: $e");
      uploadPercent.value = 0;
      isUploading.value = false;
      AppSnackbar("Hata", "Sesli mesaj yüklenirken bir hata oluştu");
    }
  }

  Future<void> cancelVoiceRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    isRecording.value = false;
    recordingDuration.value = 0;
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      _recordingPath = null;
    }
  }

  Future<void> selectContact() async {
    if (!await FlutterContacts.requestPermission()) {
      print("Rehber izni verilmedi.");
      return;
    }
    final contact = await FlutterContacts.openExternalPick();
    if (contact != null) {
      sendMessage(
        kisiAdSoyad: contact.displayName,
        kisiTelefon: contact.phones.first.number,
      );
    } else {
      print("Kişi seçilmedi.");
    }
  }

  String _resolveMessageType({
    required String text,
    List<String>? imageUrls,
    LatLng? latLng,
    String? kisiAdSoyad,
    String? postID,
    String? gif,
    String? videoUrl,
    String? audioUrl,
  }) {
    if (videoUrl != null && videoUrl.isNotEmpty) return "video";
    if (audioUrl != null && audioUrl.isNotEmpty) return "audio";
    if (imageUrls != null && imageUrls.isNotEmpty) return "media";
    if (gif != null && gif.isNotEmpty) return "gif";
    if (latLng != null) return "location";
    if (kisiAdSoyad != null && kisiAdSoyad.isNotEmpty) return "contact";
    if (postID != null && postID.isNotEmpty) return "post";
    if (text.isNotEmpty) return "text";
    return "text";
  }

  String _buildLastMessageText({
    required String text,
    List<String>? imageUrls,
    LatLng? latLng,
    String? kisiAdSoyad,
    String? postID,
    String? gif,
    String? videoUrl,
    String? audioUrl,
  }) {
    if (text.isNotEmpty) return text;
    if (videoUrl != null && videoUrl.isNotEmpty) return "Video";
    if (audioUrl != null && audioUrl.isNotEmpty) return "Sesli mesaj";
    if (imageUrls != null && imageUrls.isNotEmpty) return "Fotoğraf";
    if (gif != null && gif.isNotEmpty) return "GIF";
    if (latLng != null) return "Konum";
    if (kisiAdSoyad != null && kisiAdSoyad.isNotEmpty) return "Kişi";
    if (postID != null && postID.isNotEmpty) return "Gönderi";
    return "Mesaj";
  }
}
