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

  StreamSubscription<QuerySnapshot>? _messageSubscription;

  ChatListingContentController({
    required this.userID,
    required this.model,
  });

  @override
  void onInit() {
    super.onInit();
    listenToUnreadMessages();
    getLastMessage();
  }

  void listenToUnreadMessages() {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;

    _messageSubscription = FirebaseFirestore.instance
        .collection("Mesajlar")
        .doc(model.chatID)
        .collection("Chat")
        .where("userID", isNotEqualTo: currentUID)
        .where("isRead", isEqualTo: false)
        .orderBy("timeStamp", descending: true)
        .limit(10)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      notReadCounter.value = snapshot.docs.length;
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
    _messageSubscription?.cancel();
    super.onClose();
  }
}
