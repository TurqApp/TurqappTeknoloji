import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Core/NotificationService.dart';
import 'package:turqappv2/Core/Services/ConversationId.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/ChatListingController.dart';
import 'package:uuid/uuid.dart';

import '../../Core/BlockedTexts.dart';
import '../../Core/Services/OptimizedNSFWService.dart';
import '../../Models/MessageModel.dart';

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
  StreamSubscription<QuerySnapshot>? _legacyStream;
  StreamSubscription<QuerySnapshot>? _conversationStream;
  final Map<String, MessageModel> _legacyMessages = {};
  final Map<String, MessageModel> _conversationMessages = {};
  var showScrollDownButton = false.obs;

  ChatController({required this.chatID, required this.userID});

  @override
  void onInit() {
    super.onInit();
    getUserData();
    getData();
    _clearConversationUnread();
    _clearLegacyForceUnread();
    textEditingController.addListener(() {
      textMesage.value = textEditingController.text;
    });
    scrollController.addListener(() {
      showScrollDownButton.value = scrollController.offset > 500;
    });
  }

  Future<void> _clearLegacyForceUnread() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection("Mesajlar").doc(chatID).set({
        "forceUnread.$uid": false,
        "unread.$uid": 0,
      }, SetOptions(merge: true));
    } catch (_) {}
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
    _legacyStream?.cancel();
    _conversationStream?.cancel();
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

  void getData() {
    _legacyStream?.cancel();
    _conversationStream?.cancel();

    _legacyStream = FirebaseFirestore.instance
        .collection('Mesajlar')
        .doc(chatID)
        .collection('Chat')
        .orderBy("timeStamp", descending: true)
        .snapshots()
        .listen(_onLegacySnapshot);

    _conversationStream = FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .listen(_onConversationSnapshot);
  }

  Future<void> archiveCurrentChat() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final convRef =
          FirebaseFirestore.instance.collection("conversations").doc(chatID);
      final legacyRef =
          FirebaseFirestore.instance.collection("Mesajlar").doc(chatID);

      final convDoc = await convRef.get();
      if (convDoc.exists) {
        await convRef.set({"archived.$uid": true}, SetOptions(merge: true));
      }

      final legacyDoc = await legacyRef.get();
      if (legacyDoc.exists) {
        await legacyRef.set({"archived.$uid": true}, SetOptions(merge: true));
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

  void _onLegacySnapshot(QuerySnapshot snapshot) {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;
    _legacyMessages.clear();
    var hadUnreadFromOther = false;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final kullanicilar = List<String>.from(data["kullanicilar"] ?? []);
      if (!kullanicilar.contains(currentUID)) continue;

      final model = MessageModel.fromJson({
        ...data,
        "source": "legacy",
        "rawDocID": doc.id,
      }, 'legacy_${doc.id}');
      _legacyMessages[model.docID] = model;

      if ((data["userID"] ?? "") != currentUID && (data["isRead"] == false)) {
        hadUnreadFromOther = true;
        FirebaseFirestore.instance
            .collection('Mesajlar')
            .doc(chatID)
            .collection('Chat')
            .doc(doc.id)
            .update({"isRead": true});
      }
    }

    if (hadUnreadFromOther) {
      FirebaseFirestore.instance.collection("Mesajlar").doc(chatID).set({
        "unread.$currentUID": 0,
        "forceUnread.$currentUID": false,
      }, SetOptions(merge: true));
    }

    _refreshMergedMessages();
  }

  void _onConversationSnapshot(QuerySnapshot snapshot) {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;
    _conversationMessages.clear();
    final List<String> unseenRawDocIds = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final senderId = data["senderId"] ?? "";
      final seenBy = List<String>.from(data["seenBy"] ?? []);
      final model = MessageModel.fromConversationSnapshot(doc);
      _conversationMessages[model.docID] = model;

      if (senderId != currentUID && !seenBy.contains(currentUID)) {
        unseenRawDocIds.add(doc.id);
      }
    }

    if (unseenRawDocIds.isNotEmpty) {
      final convRef =
          FirebaseFirestore.instance.collection("conversations").doc(chatID);
      final batch = FirebaseFirestore.instance.batch();
      for (final rawId in unseenRawDocIds.take(25)) {
        final msgRef = convRef.collection("messages").doc(rawId);
        batch.update(msgRef, {
          "seenBy": FieldValue.arrayUnion([currentUID]),
        });
      }
      batch.set(convRef, {"unread.$currentUID": 0}, SetOptions(merge: true));
      batch.commit();
    }

    _refreshMergedMessages();
  }

  void _refreshMergedMessages() {
    final merged = <MessageModel>[
      ..._legacyMessages.values,
      ..._conversationMessages.values,
    ];
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
        backgroundColor: Colors.red.withOpacity(0.7),
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
        (gif?.isNotEmpty ?? false)) {
      print("📨 Mesaj gönderme koşulları sağlandı");

      // Notif body
      String notifBody;
      if (imageUrls != null && imageUrls.isNotEmpty) {
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

      final mesajData = {
        "timeStamp": DateTime.now().millisecondsSinceEpoch,
        "userID": FirebaseAuth.instance.currentUser!.uid,
        "lat": latLng?.latitude.toDouble() ?? 0.0,
        "long": latLng?.longitude.toDouble() ?? 0.0,
        "postType": postType ?? "",
        "postID": postID ?? "",
        "imgs": gif != null ? [gif] : (imageUrls ?? []),
        "video": "",
        "isRead": false,
        "kullanicilar": [userID, FirebaseAuth.instance.currentUser!.uid],
        "metin": text,
        "sesliMesaj": "",
        "kisiAdSoyad": kisiAdSoyad ?? "",
        "kisiTelefon": kisiTelefon ?? "",
        "begeniler": [],
      };

      final now = DateTime.now();
      final messageType = _resolveMessageType(
        text: text,
        imageUrls: imageUrls,
        latLng: latLng,
        kisiAdSoyad: kisiAdSoyad,
        postID: postID,
        gif: gif,
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
        "audioUrl": "",
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

      final legacyReply = replyingTo.value;
      if (legacyReply != null) {
        mesajData.addAll({
          "replyMessageId": legacyReply.rawDocID,
          "replySenderId": legacyReply.userID,
          "replyText": legacyReply.metin,
          "replyType":
              legacyReply.postType.isNotEmpty ? legacyReply.postType : "text",
          "reactions": <String, List<String>>{},
          "isEdited": false,
          "unsent": false,
          "forwarded": false,
        });
      } else {
        mesajData.addAll({
          "replyMessageId": "",
          "replySenderId": "",
          "replyText": "",
          "replyType": "",
          "reactions": <String, List<String>>{},
          "isEdited": false,
          "unsent": false,
          "forwarded": false,
        });
      }

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
      );

      await FirebaseFirestore.instance
          .collection("Mesajlar")
          .doc(chatID)
          .collection("Chat")
          .add(mesajData);
      print("✅ Firestore'a mesaj eklendi");

// timestamp güncelleme
      try {
        await FirebaseFirestore.instance
            .collection("Mesajlar")
            .doc(chatID)
            .set({
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
          "lastMessage": previewText,
          "deleted": [],
          "userID1": FirebaseAuth.instance.currentUser!.uid,
          "userID2": userID,
          "unread.${FirebaseAuth.instance.currentUser!.uid}": 0,
          "unread.$userID": FieldValue.increment(1),
          "forceUnread.$userID": false,
        }, SetOptions(merge: true));
        print("🕒 chatID'nin timestamp'i güncellendi");
      } catch (e, s) {
        print("🔥 HATA: chatID'nin timestamp'i güncellenemedi: $e");
        print(s);
      }

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

// ...devamı aynı...

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
    if (model.source == "conversation") {
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
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection("Mesajlar")
        .doc(chatID)
        .collection("Chat")
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

    if (model.source == "conversation") {
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
      return;
    }

    await FirebaseFirestore.instance
        .collection("Mesajlar")
        .doc(chatID)
        .collection("Chat")
        .doc(model.rawDocID)
        .update({
      "unsent": true,
      "metin": "",
      "imgs": <String>[],
      "lat": 0,
      "long": 0,
      "postID": "",
      "postType": "",
      "kisiAdSoyad": "",
      "kisiTelefon": "",
    });
  }

  Future<void> _editMessage(MessageModel model, String newText) async {
    if (model.source == "conversation") {
      await FirebaseFirestore.instance
          .collection("conversations")
          .doc(chatID)
          .collection("messages")
          .doc(model.rawDocID)
          .update({
        "text": newText,
        "isEdited": true,
      });
      return;
    }

    await FirebaseFirestore.instance
        .collection("Mesajlar")
        .doc(chatID)
        .collection("Chat")
        .doc(model.rawDocID)
        .update({
      "metin": newText,
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

    final legacyChatId = buildConversationId(currentUID, targetUserId);
    await FirebaseFirestore.instance
        .collection("Mesajlar")
        .doc(legacyChatId)
        .set({
      "deleted": [],
      "timeStamp": DateTime.now().millisecondsSinceEpoch,
      "lastMessage": model.metin.isNotEmpty ? model.metin : "İletilen mesaj",
      "userID1": currentUID,
      "userID2": targetUserId,
      "unread.$currentUID": 0,
      "unread.$targetUserId": FieldValue.increment(1),
      "forceUnread.$targetUserId": false,
    }, SetOptions(merge: true));

    AppSnackbar("İletildi", "Mesaj seçilen sohbete iletildi");
    if (Get.isRegistered<ChatListingController>()) {
      Get.find<ChatListingController>().getList();
    }
  }

  Future<void> pickImage() async {
    final List<XFile> picked = await picker.pickMultiImage(limit: 10);
    if (picked.isEmpty) return;

    // 1) Seçilenleri File listesine dönüştür
    final files = picked.map((x) => File(x.path)).toList();

    // 2) NSFW tespiti (OptimizedNSFWService)
    for (final f in files) {
      final r = await OptimizedNSFWService.checkImage(f);
      if (r.isNSFW) {
        // Uygunsuz içerik varsa kullanıcıyı uyar, state'i güncelleme
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withOpacity(0.7),
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
        backgroundColor: Colors.red.withOpacity(0.7),
      );
      return;
    }

    // Temizse ekle
    images.value = [file];
    selection.value = 1;
  }

  Future<void> uploadImageToStorage() async {
    uploadPercent.value = 1;
    final storage = FirebaseStorage.instance;
    final uuid = Uuid();

    List<String> downloadUrls = [];

    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final fileName = uuid.v4(); // benzersiz isim

      final ref = storage.ref().child(
            'ChatAssets/$chatID/$fileName${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

      final uploadTask = ref.putFile(image);

      // Yüklenme yüzdesi hesapla
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double percent =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Resim $i yükleniyor: %${percent.toStringAsFixed(2)}');
        uploadPercent.value = percent;
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
      print('Resim $i yüklendi: $downloadUrl');
    }

    print('Tüm URL’ler: $downloadUrls');

    uploadPercent.value = 0;
    selection.value = 0;

    sendMessage(imageUrls: downloadUrls);
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
  }) {
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
  }) {
    if (text.isNotEmpty) return text;
    if (imageUrls != null && imageUrls.isNotEmpty) return "Fotoğraf";
    if (gif != null && gif.isNotEmpty) return "GIF";
    if (latLng != null) return "Konum";
    if (kisiAdSoyad != null && kisiAdSoyad.isNotEmpty) return "Kişi";
    if (postID != null && postID.isNotEmpty) return "Gönderi";
    return "Mesaj";
  }
}
