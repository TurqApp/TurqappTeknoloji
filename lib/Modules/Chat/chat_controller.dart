import 'dart:async';
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
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

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
  var selection = 0.obs;
  var textMesage = ''.obs;
  var uploadPercent = 0.0.obs;
  RxList<MessageModel> messages = <MessageModel>[].obs;
  TextEditingController textEditingController = TextEditingController();
  ScrollController scrollController = ScrollController();
  PageController pageController = PageController();
  FocusNode focus = FocusNode();
  var currentPage = 0.obs;
  final picker = ImagePicker();
  RxList<File> images = <File>[].obs;
  final replyingTo = Rxn<MessageModel>();
  final editingMessage = Rxn<MessageModel>();
  Timer? _messageSyncTimer;
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
  var isLoadingOlder = false.obs;
  var hasMoreOlder = true.obs;
  var isOtherTyping = false.obs;
  var isUploading = false.obs;
  var isRecording = false.obs;
  var recordingDuration = 0.obs;
  Timer? _typingDebounce;
  Timer? _recordingTimer;
  StreamSubscription<DocumentSnapshot>? _typingStream;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;

  NetworkAwarenessService? get _network =>
      Get.isRegistered<NetworkAwarenessService>()
          ? Get.find<NetworkAwarenessService>()
          : null;

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;

  Duration get _serverSyncGap {
    if (_isOffline) return const Duration(days: 1);
    return _isOnWiFi ? const Duration(seconds: 3) : const Duration(seconds: 8);
  }

  ChatController({required this.chatID, required this.userID});

  @override
  void onInit() {
    super.onInit();
    getUserData();
    getData();
    _clearConversationUnread();
    textEditingController.addListener(() {
      textMesage.value = textEditingController.text;
      _onTypingChanged();
    });
    _listenTypingState();
    scrollController.addListener(() {
      showScrollDownButton.value = scrollController.offset > 500;
      if (scrollController.hasClients &&
          scrollController.position.maxScrollExtent > 0 &&
          scrollController.offset >
              (scrollController.position.maxScrollExtent - 280)) {
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
    _messageSyncTimer?.cancel();
    _typingStream?.cancel();
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _clearTyping();
    super.onClose();
  }

  void getUserData() async {
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(userID).get();
    nickname.value = doc.get("nickname");
    pfImage.value = doc.get("pfImage");
    fullName.value = "${doc.get("firstName")} ${doc.get("lastName")}";
    bio.value = doc.get("bio");
    token.value = doc.get("token");
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
      FirebaseFirestore.instance.collection("conversations").doc(chatID).set({
        "typing.$uid": DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
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
    FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .set({"typing.$uid": 0}, SetOptions(merge: true));
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
    });
  }

  void getData() {
    _messageSyncTimer?.cancel();

    _loadInitialMessages(forceServer: true);
    _messageSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _syncMessages(forceServer: false);
    });
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

  void _applyConversationSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool replace,
  }) {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;
    if (replace) _conversationMessages.clear();
    final List<String> unseenRawDocIds = [];
    final List<String> undeliveredRawDocIds = [];

    for (final doc in docs) {
      final data = doc.data();
      final senderId = data["senderId"] ?? "";
      final seenBy = List<String>.from(data["seenBy"] ?? []);
      final status = data["status"] ?? "";
      final model = MessageModel.fromConversationSnapshot(doc);
      _conversationMessages[model.docID] = model;

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
      if (unseenRawDocIds.isNotEmpty) {
        batch.set(convRef, {"unread.$currentUID": 0}, SetOptions(merge: true));
      }
      batch.commit();
    }
  }

  void _refreshMergedMessages() {
    final merged = <MessageModel>[..._conversationMessages.values];
    merged.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    messages.value = merged;
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
  }) async {
    print("🚀 sendMessage BAŞLADI");

    final text = textEditingController.text.trim();
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
        if (replyingTo.value != null)
          "replyTo": {
            "messageId": replyingTo.value!.rawDocID,
            "senderId": replyingTo.value!.userID,
            "text": replyingTo.value!.metin,
            "type": replyingTo.value!.postType.isNotEmpty
                ? replyingTo.value!.postType
                : "text",
          },
      };

      print("🗂 Mesaj data hazır, firestore'a ekleniyor...");

// Notif
      NotificationService.instance.sendNotification(
        token: token.value,
        title: nickname.value,
        body: notifBody,
        docID: chatID,
        type: "Chat",
      );
      print("🔔 Notification gönderildi");

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
        await convRef.collection("messages").add(conversationMessageData);
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
      } catch (e, s) {
        print("🔥 HATA: conversation yazımı başarısız: $e");
        print(s);
      }

      print("🧹 TextEditingController temizleniyor...");
      textEditingController.clear();
      clearComposerAction();
      if (Get.isRegistered<ChatListingController>()) {
        Get.find<ChatListingController>().getList();
      }
      print("🎉 MESAJ TAMAMEN GÖNDERİLDİ ve TEMİZLENDİ!");
    } else {
      print("❗️Hiçbir mesaj gönderme koşulu sağlanmadı, mesaj gönderilmiyor.");
    }
  }

  Future<void> toggleReaction(MessageModel model, String emoji) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .doc(model.rawDocID);
    final snap = await ref.get();
    final reactions =
        Map<String, dynamic>.from(snap.data()?["reactions"] ?? {});
    final current = List<String>.from(reactions[emoji] ?? []);
    await ref.update({
      "reactions.$emoji": current.contains(uid)
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
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
      // Güvenlik: Seçim ekranı dışında dosya değişmişse tekrar doğrula.
      for (final image in images) {
        final check = await OptimizedNSFWService.checkImage(image);
        if (check.isNSFW) {
          isUploading.value = false;
          uploadPercent.value = 0;
          AppSnackbar(
            "Yükleme Başarısız!",
            "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
            backgroundColor: Colors.red.withValues(alpha: 0.7),
          );
          return;
        }
      }

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final fileName = uuid.v4();

        final ref = storage.ref().child(
              'ChatAssets/$chatID/$fileName${DateTime.now().millisecondsSinceEpoch}.jpg',
            );

        final uploadTask = ref.putFile(image);

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

      await sendMessage(imageUrls: downloadUrls);
    } catch (e) {
      print("Resim upload error: $e");
      uploadPercent.value = 0;
      isUploading.value = false;
      AppSnackbar("Hata", "Resim yüklenirken bir hata oluştu");
    }
  }

  Future<void> pickVideo() async {
    final XFile? pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (pickedFile == null) return;
    await _processAndSendVideo(File(pickedFile.path));
  }

  Future<void> pickCameraVideo() async {
    final XFile? pickedFile = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 3),
    );
    if (pickedFile == null) return;
    await _processAndSendVideo(File(pickedFile.path));
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

      // 3. Upload video
      final videoFileName = uuid.v4();
      final videoRef = storage.ref().child(
            'ChatAssets/$chatID/videos/$videoFileName.mp4',
          );
      final videoUpload = videoRef.putFile(fileToUpload);
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
          final thumbRef = storage.ref().child(
                'ChatAssets/$chatID/videos/${videoFileName}_thumb.jpg',
              );
          await thumbRef.putData(thumbBytes);
          thumbUrl = await thumbRef.getDownloadURL();
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
    if (await _audioRecorder.hasPermission()) {
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
    } else {
      AppSnackbar("İzin Gerekli", "Mikrofon izni verilmedi");
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
      final uploadTask = ref.putFile(file);
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
