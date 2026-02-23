import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Models/message_model.dart';

class ChatListingContentController extends GetxController {
  String userID;
  ChatListingModel model;
  var notReadCounter = 0.obs;
  RxList<MessageModel> lastMessage = <MessageModel>[].obs;

  StreamSubscription<DocumentSnapshot>? _conversationSubscription;

  ChatListingContentController({
    required this.userID,
    required this.model,
  });

  @override
  void onInit() {
    super.onInit();
    notReadCounter.value = model.unreadCount;
    _listenConversationUnread();
    if (model.lastMessage.isNotEmpty) {
      lastMessage.assignAll([
        MessageModel(
          docID: "preview_${model.chatID}",
          rawDocID: "preview_${model.chatID}",
          source: "preview",
          timeStamp: num.tryParse(model.timeStamp) ?? 0,
          userID: model.userID,
          lat: 0,
          long: 0,
          postType: "",
          postID: "",
          imgs: const [],
          video: "",
          isRead: model.unreadCount <= 0,
          kullanicilar: const [],
          metin: model.lastMessage,
          sesliMesaj: "",
          kisiAdSoyad: "",
          kisiTelefon: "",
          begeniler: const [],
          isEdited: false,
          isUnsent: false,
          isForwarded: false,
          replyMessageId: "",
          replySenderId: "",
          replyText: "",
          replyType: "",
          reactions: const {},
        )
      ]);
    }
  }

  void _listenConversationUnread() {
    final currentUID = FirebaseAuth.instance.currentUser?.uid;
    if (currentUID == null) return;
    _conversationSubscription = FirebaseFirestore.instance
        .collection("conversations")
        .doc(model.chatID)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        notReadCounter.value = 0;
        return;
      }
      final data = snapshot.data() ?? <String, dynamic>{};
      final unreadMap = Map<String, dynamic>.from(data["unread"] ?? {});
      final rawUnread = unreadMap[currentUID];
      final unread =
          rawUnread is int ? rawUnread : int.tryParse("$rawUnread") ?? 0;
      notReadCounter.value = unread;
    }, onError: (_) {});
  }

  @override
  void onClose() {
    _conversationSubscription?.cancel();
    super.onClose();
  }
}
