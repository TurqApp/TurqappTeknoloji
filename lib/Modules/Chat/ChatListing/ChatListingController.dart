import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Models/ChatListingModel.dart';
import '../CreateChat/CreateChat.dart';

class ChatListingController extends GetxController {
  RxList<ChatListingModel> list = <ChatListingModel>[].obs;
  RxList<ChatListingModel> filteredList = <ChatListingModel>[].obs;

  TextEditingController search = TextEditingController();
  var waiting = false.obs;

  @override
  void onInit() {
    super.onInit();
    search.addListener(_onSearchChanged);
    getList();
  }

  void _onSearchChanged() {
    final query = search.text.toLowerCase();

    if (query.isEmpty) {
      filteredList.value = list;
    } else {
      filteredList.value = list.where((item) {
        final nickname = item.nickname.toLowerCase();
        final fullName = item.fullName.toLowerCase();
        return nickname.contains(query) || fullName.contains(query);
      }).toList();
    }
  }

  Future<void> getList() async {
    waiting.value = true;
    List<ChatListingModel> tempList = [];
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap1 = await FirebaseFirestore.instance
        .collection("Mesajlar")
        .where("userID1", isEqualTo: uid)
        .orderBy("timeStamp", descending: true)
        .get();
    list.clear();
    for (var doc in snap1.docs) {
      final deletedList = List<String>.from(doc.get("deleted") ?? []);
      if (!deletedList.contains(uid)) {
        final docc = await FirebaseFirestore.instance
            .collection("users")
            .doc(doc.get("userID2"))
            .get();

        tempList.add(ChatListingModel(
          chatID: doc.id,
          userID: doc.get("userID2"),
          timeStamp: doc.get("timeStamp").toString(),
          deleted: deletedList,
          nickname: docc.get("nickname"),
          fullName: "${docc.get("firstName")} ${docc.get("lastName")}",
          pfImage: docc.get("pfImage"),
        ));
      }
    }

    final snap2 = await FirebaseFirestore.instance
        .collection("Mesajlar")
        .where("userID2", isEqualTo: uid)
        .orderBy("timeStamp", descending: true)
        .get();

    for (var doc in snap2.docs) {
      final deletedList = List<String>.from(doc.get("deleted") ?? []);
      if (!deletedList.contains(uid)) {
        final docc = await FirebaseFirestore.instance
            .collection("users")
            .doc(doc.get("userID1"))
            .get();

        tempList.add(ChatListingModel(
          chatID: doc.id,
          userID: doc.get("userID1"),
          timeStamp: doc.get("timeStamp").toString(),
          deleted: deletedList,
          nickname: docc.get("nickname"),
          fullName: "${docc.get("firstName")} ${docc.get("lastName")}",
          pfImage: docc.get("pfImage"),
        ));
      }
    }

    tempList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    list.value = tempList;
    filteredList.value = tempList;
    waiting.value = false;
  }

  void showCreateChatBottomSheet() {
    Get.bottomSheet(
      CreateChat(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  @override
  void onClose() {
    search.removeListener(_onSearchChanged);
    search.dispose();
    super.onClose();
  }
}
