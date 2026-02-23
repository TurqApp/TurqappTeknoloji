import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';

class AnswerKeyContentController extends GetxController {
  final BookletModel model;
  final Function(bool) onUpdate;

  final isBookmarked = false.obs;
  final pfImage = ''.obs;
  final nickname = ''.obs;
  final secim = ''.obs;

  AnswerKeyContentController(this.model, this.onUpdate);

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  void _initialize() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null && model.kaydet.contains(currentUserId)) {
      isBookmarked.value = true;
    }

    _fetchUserData();
    _updateViewCount(currentUserId);
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(model.userID)
          .get();
      pfImage.value = doc.get("pfImage") ?? '';
      nickname.value = doc.get("nickname") ?? '';
      log(
        "Kullanıcı verisi çekildi: ${model.docID} için nickname: ${nickname.value}",
      );
    } catch (e) {
      log("Kullanıcı verisi çekme hatası: $e");
    }
  }

  void _updateViewCount(String? currentUserId) {
    if (currentUserId != null && model.userID != currentUserId) {
      FirebaseFirestore.instance
          .collection("Kitapciklar")
          .doc(model.docID)
          .update({
        "goruntuleme": FieldValue.arrayUnion([currentUserId]),
      }).catchError((e) => log("Görüntüleme güncelleme hatası: $e"));
    }
  }

  Future<void> toggleBookmark() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('Kitapciklar').doc(model.docID);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) return;

        final data = docSnapshot.data();
        final favorites = List<String>.from(data?['kaydet'] ?? []);

        if (favorites.contains(userId)) {
          favorites.remove(userId);
          isBookmarked.value = false;
        } else {
          favorites.add(userId);
          isBookmarked.value = true;
        }

        transaction.update(docRef, {'kaydet': favorites});
      });
    } catch (e) {
      log("Yer işareti değiştirme hatası: $e");
    }
  }

  void navigateToPreview(BuildContext context) {
    Get.to(() => BookletPreview(model: model));
  }

  void showBottomSheet(BuildContext context) {
    if (model.userID != FirebaseAuth.instance.currentUser?.uid) {
      _showSpamBottomSheet(context);
    } else {
      _showDeleteBottomSheet(context);
    }
  }

  void _showSpamBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Obx(
          () => FractionallySizedBox(
            heightFactor: 0.15,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Cevap Anahtarı Hakkında",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      secim.value = secim.value == "Spam" ? "" : "Spam";
                      if (secim.value == "Spam") {
                        Get.back();
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text(
                            "Spam",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(50),
                            ),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                color: secim.value == "Spam"
                                    ? Colors.indigo
                                    : Colors.white,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteBottomSheet(BuildContext context) {
    noYesAlert(
      title: "Kitabı Sil",
      message: "Bu kitabı silmek istediğinizden emin misiniz?",
      cancelText: "Vazgeç",
      yesText: "Sil",
      onYesPressed: () async {
        try {
          await FirebaseFirestore.instance
              .collection("Kitapciklar")
              .doc(model.docID)
              .delete();
          onUpdate(true);
        } catch (e) {
          log("Kitapçık silme hatası: $e");
        }
      },
    );
  }
}
