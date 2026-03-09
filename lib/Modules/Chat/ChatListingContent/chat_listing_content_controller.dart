import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        .listen((snapshot) async {
      final prevUnread = notReadCounter.value;
      if (!snapshot.exists) {
        notReadCounter.value = 0;
        model.unreadCount = 0;
        if (Get.isRegistered<UnreadMessagesController>()) {
          Get.find<UnreadMessagesController>().updateConversationUnreadLocal(
            otherUid: userID,
            unreadCount: 0,
          );
        }
        if (Get.isRegistered<ChatListingController>()) {
          Get.find<ChatListingController>()
              .updateUnreadLocal(chatId: model.chatID, unreadCount: 0);
        }
        return;
      }
      final data = snapshot.data() ?? <String, dynamic>{};
      final unreadMap = Map<String, dynamic>.from(data["unread"] ?? {});
      final rawUnread = unreadMap[currentUID];
      final serverUnread = rawUnread is num
          ? rawUnread.toInt()
          : int.tryParse("$rawUnread") ?? 0;
      final lastSenderId = (data["lastSenderId"] ?? "").toString();
      int ts = 0;
      final lmAt = data["lastMessageAt"];
      if (lmAt is Timestamp) {
        ts = lmAt.millisecondsSinceEpoch;
      } else {
        final fallbackTs = data["lastMessageAtMs"];
        ts = fallbackTs is int ? fallbackTs : int.tryParse("$fallbackTs") ?? 0;
      }
      final prefs = await SharedPreferences.getInstance();
      final seenTs =
          prefs.getInt("chat_last_opened_${currentUID}_${model.chatID}") ?? 0;
      final localUnread =
          lastSenderId.isNotEmpty && lastSenderId != currentUID && ts > seenTs;
      final seenCoversLatestMessage = ts > 0 && seenTs >= ts;
      final unread = seenCoversLatestMessage
          ? 0
          : ((serverUnread > 0 || localUnread) ? 1 : 0);

      notReadCounter.value = unread;
      model.unreadCount = unread;
      if (Get.isRegistered<UnreadMessagesController>()) {
        Get.find<UnreadMessagesController>().updateConversationUnreadLocal(
          otherUid: userID,
          unreadCount: unread,
          chatId: model.chatID,
          seenAtMs: seenTs,
        );
      }
      if (Get.isRegistered<ChatListingController>()) {
        Get.find<ChatListingController>()
            .updateUnreadLocal(chatId: model.chatID, unreadCount: unread);
      }

      // unread değişiminde listeyi anında güncelle
      if (prevUnread != unread && Get.isRegistered<ChatListingController>()) {
        Get.find<ChatListingController>()
            .updateUnreadLocal(chatId: model.chatID, unreadCount: unread);
      }
    }, onError: (_) {});
  }

  @override
  void onClose() {
    _conversationSubscription?.cancel();
    super.onClose();
  }
}
