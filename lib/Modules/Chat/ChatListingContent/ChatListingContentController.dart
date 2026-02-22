import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/ChatListingModel.dart';
import 'package:turqappv2/Models/MessageModel.dart';

class ChatListingContentController extends GetxController {
  String userID;
  ChatListingModel model;
  var notReadCounter = 0.obs;
  RxList<MessageModel> lastMessage = <MessageModel>[].obs;

  StreamSubscription<DocumentSnapshot>? _conversationSubscription;
  StreamSubscription<DocumentSnapshot>? _legacyRootSubscription;

  ChatListingContentController({
    required this.userID,
    required this.model,
  });

  @override
  void onInit() {
    super.onInit();
    if (model.isConversation) {
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
    } else {
      listenToUnreadMessages();
      getLastMessage();
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

  void listenToUnreadMessages() {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;

    _legacyRootSubscription = FirebaseFirestore.instance
        .collection("Mesajlar")
        .doc(model.chatID)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      final forceUnread = Map<String, dynamic>.from(data["forceUnread"] ?? {});
      final unreadMap = Map<String, dynamic>.from(data["unread"] ?? {});
      final rawUnread = unreadMap[currentUID];
      final unread =
          rawUnread is int ? rawUnread : int.tryParse("$rawUnread") ?? 0;
      if (forceUnread[currentUID] == true) {
        notReadCounter.value = unread > 0 ? unread : 1;
      } else {
        notReadCounter.value = unread < 0 ? 0 : unread;
      }
    });
  }

  Future<void> getLastMessage() async {
    FirebaseFirestore.instance
        .collection("Mesajlar")
        .doc(model.chatID)
        .collection("Chat")
        .orderBy("timeStamp", descending: true)
        .limit(1)
        .get()
        .then((snap) {
      for (var doc in snap.docs) {
        lastMessage.insert(0, MessageModel.fromSnapshot(doc));
      }
    });
  }

  @override
  void onClose() {
    _conversationSubscription?.cancel();
    _legacyRootSubscription?.cancel();
    super.onClose();
  }
}
