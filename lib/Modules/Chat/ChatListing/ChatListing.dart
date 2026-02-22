import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/EmptyRow.dart';
import 'package:turqappv2/Modules/Chat/ChatListingContent/ChatListingContent.dart';

import 'ChatListingController.dart';

class ChatListing extends StatelessWidget {
  ChatListing({super.key});
  final controller = Get.put(ChatListingController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(text: "Sohbetler"),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                  child: Container(
                    height: 50,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        controller: controller.search,
                        decoration: InputDecoration(
                            hintText: "Ara",
                            hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium"),
                            border: InputBorder.none,
                            icon: Icon(
                              CupertinoIcons.search,
                              color: Colors.grey,
                            )),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final isSearching = controller.search.text.isNotEmpty;
                    final hasResults = controller.filteredList.isNotEmpty;

                    return RefreshIndicator(
                      onRefresh: () async {
                        controller.list.clear();
                        await controller.getList();
                      },
                      backgroundColor: Colors.black,
                      color: Colors.white,
                      child: controller.waiting.value
                          ? const Center(child: CupertinoActivityIndicator())
                          : isSearching && !hasResults
                              ? EmptyRow(text: "Arama sonucu bulunamadı")
                              : ListView.builder(
                                  itemCount: controller.filteredList.length,
                                  itemBuilder: (context, index) {
                                    final item = controller.filteredList[index];

                                    return Dismissible(
                                      key: ValueKey(item.chatID),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: const Icon(Icons.delete,
                                            color: Colors.white),
                                      ),
                                      confirmDismiss: (direction) async {
                                        bool confirmed = false;

                                        await noYesAlert(
                                          title: "Sohbeti Sil",
                                          message:
                                              "Bu sohbeti silmek istediğinizden emin misiniz?",
                                          cancelText: "Vazgeç",
                                          yesText: "Sohbeti Sil",
                                          yesButtonColor:
                                              CupertinoColors.destructiveRed,
                                          onYesPressed: () {
                                            confirmed = true;
                                          },
                                        );
                                        return confirmed;
                                      },
                                      onDismissed: (direction) async {
                                        final deletedItem = controller
                                            .filteredList
                                            .removeAt(index);
                                        await FirebaseFirestore.instance
                                            .collection("Mesajlar")
                                            .doc(deletedItem.chatID)
                                            .update({
                                          "deleted": FieldValue.arrayUnion([
                                            FirebaseAuth
                                                .instance.currentUser!.uid
                                          ])
                                        });
                                        AppSnackbar("Sohbet Silindi",
                                            "Seçilen sohbet başarıyla silindi",
                                            snackPosition:
                                                SnackPosition.BOTTOM);
                                      },
                                      child: ChatListingContent(model: item),
                                    );
                                  },
                                ),
                    );
                  }),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          controller.showCreateChatBottomSheet();
                        },
                        style:
                            TextButton.styleFrom(padding: EdgeInsets.all(15)),
                        child: Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.blue, shape: BoxShape.circle),
                          child: Icon(
                            CupertinoIcons.add,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            Obx(() {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (controller.waiting.value) CupertinoActivityIndicator()
                ],
              );
            })
          ],
        ),
      ),
    );
  }
}
