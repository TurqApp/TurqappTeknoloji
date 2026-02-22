import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/SocialMediaLinksController.dart';

import '../../../Models/SocialMediaModel.dart';

class SocialMediaLinks extends StatelessWidget {
  SocialMediaLinks({super.key});
  final controller = Get.put(SocialMediaController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Bağlantılar (${controller.list.length})"),
            const SizedBox(height: 15),
            Expanded(
              child: RefreshIndicator(
                backgroundColor: Colors.black,
                color: Colors.white,
                onRefresh: () async {
                  controller.list.clear();
                  await controller.getData();
                },
                child: Obx(() => ReorderableBuilder(
                      onReorder: (ReorderedListFunction reorderFn) async {
                        final oldList = controller.list.toList();
                        final newList =
                            reorderFn(oldList).cast<SocialMediaModel>();

                        // Eski sıraya göre modeli bul
                        for (int i = 0; i < oldList.length; i++) {
                          if (oldList[i].docID != newList[i].docID) {
                            final movedModel = newList[i];
                            final fromIndex = oldList
                                .indexWhere((e) => e.docID == movedModel.docID);
                            final toIndex = i;
                            print("Taşınan başlık: ${movedModel.title}");
                            FirebaseFirestore.instance
                                .collection("users")
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .collection("SosyalMedyaLinkleri")
                                .doc(movedModel.docID)
                                .update({"sira": toIndex});
                            print(
                                "Eski index: $fromIndex → Yeni index: $toIndex");
                            break;
                          }
                        }

                        controller.list.value = newList;
                        await controller.updateAllSira();
                      },
                      children: controller.list.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final model = entry.value;

                          return KeyedSubtree(
                            key: ValueKey(model.docID),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(20)),
                              child: Column(
                                children: [
                                  Flexible(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: model.logo,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () =>
                                                showRemoveConfirmation(index),
                                            child: Container(
                                              width: 25,
                                              height: 25,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                CupertinoIcons
                                                    .minus_circle_fill,
                                                color: Colors.red,
                                                size: 25,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    model.title,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                ],
                              ),
                            ),
                          );
                        },
                      ).toList(),
                      builder: (children) {
                        return GridView(
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          children: [
                            ...children,
                            _buildAddButton(),
                          ],
                        );
                      },
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showRemoveConfirmation(int index) async {
    final model = controller.list[index];
    await noYesAlert(
      title: "Bağlantıyı Kaldır",
      message: "Bu bağlantıyı kaldırmak istediğinizden emin misiniz?",
      cancelText: "Vazgeç",
      yesText: "Kaldır",
      yesButtonColor: CupertinoColors.destructiveRed,
      onYesPressed: () async {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection("SosyalMedyaLinkleri")
            .doc(model.docID)
            .delete();
        await controller.getData();
      },
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: controller.showAddBottomSheet,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Flexible(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Center(
                    child: Icon(CupertinoIcons.add, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              "Ekle",
              maxLines: 1,
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}
