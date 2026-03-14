import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateBook/create_book.dart';

class AnswerKeyContentController extends GetxController {
  BookletModel model;
  final Function(bool) onUpdate;

  final isBookmarked = false.obs;
  final avatarUrl = ''.obs;
  final nickname = ''.obs;
  final secim = ''.obs;

  AnswerKeyContentController(this.model, this.onUpdate);
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  bool get isOwner => model.userID == FirebaseAuth.instance.currentUser?.uid;

  void syncModel(BookletModel nextModel) {
    model = nextModel;
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  void _initialize() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchUserData();
    _loadBookmarkState(currentUserId);
    _updateViewCount(currentUserId);
  }

  Future<void> _loadBookmarkState(String? currentUserId) async {
    if (currentUserId == null) return;

    try {
      final savedEntry = await _userSubcollectionRepository.getEntry(
        currentUserId,
        subcollection: 'books',
        docId: model.docID,
        preferCache: true,
        forceRefresh: false,
      );
      isBookmarked.value = savedEntry != null;
    } catch (e) {
      log("Kaydet durumu okunamadı: $e");
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await UserRepository.ensure().getUser(
        model.userID,
        preferCache: true,
        cacheOnly: false,
      );
      avatarUrl.value = user?.avatarUrl ?? '';
      nickname.value = user?.preferredName ?? '';
    } catch (e) {
      log("Kullanıcı verisi çekme hatası: $e");
    }
  }

  void _updateViewCount(String? currentUserId) {
    if (currentUserId != null && model.userID != currentUserId) {
      FirebaseFirestore.instance.collection("books").doc(model.docID).update({
        "viewCount": FieldValue.increment(1),
      }).then((_) {
        model.viewCount += 1;
        return null;
      }).catchError((e) {
        log("Görüntüleme güncelleme hatası: $e");
        return null;
      });
    }
  }

  Future<void> toggleBookmark() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      if (isBookmarked.value) {
        await _userSubcollectionRepository.deleteEntry(
          userId,
          subcollection: 'books',
          docId: model.docID,
        );
        isBookmarked.value = false;
        return;
      }

      await _userSubcollectionRepository.upsertEntry(
        userId,
        subcollection: 'books',
        docId: model.docID,
        data: {
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
      isBookmarked.value = true;
    } catch (e) {
      log("Yer işareti değiştirme hatası: $e");
    }
  }

  void navigateToPreview(BuildContext context) {
    Get.to(() => BookletPreview(model: model));
  }

  void editBooklet(BuildContext context) {
    Get.to(
      () => CreateBook(
        onBack: onUpdate,
        existingBook: model,
      ),
    );
  }

  void deleteBooklet(BuildContext context) {
    _showDeleteBottomSheet(context);
  }

  void openBooklet(BuildContext context) {
    if (isOwner) {
      _showOwnerActions(context);
      return;
    }
    navigateToPreview(context);
  }

  void _showOwnerActions(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text(
          model.baslik,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontFamily: "MontserratBold",
          ),
        ),
        content: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: CachedNetworkImage(
            imageUrl: model.cover,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image),
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          GestureDetector(
            onTap: () {
              Get.back();
              navigateToPreview(context);
            },
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Görüntüle",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.purpleAccent,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Get.back();
              Future.delayed(const Duration(milliseconds: 300), () {
                deleteBooklet(context);
              });
            },
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Kitabı Sil",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.red,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Get.back();
              editBooklet(context);
            },
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Düzenle",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.indigo,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: Get.back,
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Vazgeç",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> shareBooklet() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canShareFeed =
        AdminAccessService.isKnownAdminSync() || model.userID == currentUid;
    if (!canShareFeed) {
      AppSnackbar("Yetki", "Sadece admin ve ilan sahibi paylaşabilir.");
      return;
    }
    final shareId = 'answer-key:${model.docID}';
    final shortTail =
        model.docID.length >= 8 ? model.docID.substring(0, 8) : model.docID;
    final fallbackId = 'answer-key-$shortTail';
    final fallbackUrl = 'https://turqapp.com/e/$fallbackId';

    try {
      await ShareActionGuard.run(() async {
        String shortUrl = '';
        try {
          shortUrl = await ShortLinkService().getEducationPublicUrl(
            shareId: shareId,
            title: model.baslik,
            desc: model.yayinEvi.isNotEmpty
                ? model.yayinEvi
                : '${model.sinavTuru} cevap anahtari',
            imageUrl: model.cover.isNotEmpty ? model.cover : null,
          );
        } catch (_) {
          shortUrl = fallbackUrl;
        }

        if (shortUrl.trim().isEmpty ||
            shortUrl.trim() == 'https://turqapp.com') {
          shortUrl = fallbackUrl;
        }

        await ShareLinkService.shareUrl(
          url: shortUrl,
          title: model.baslik,
          subject: model.baslik,
        );
      });
    } catch (_) {
      AppSnackbar("Hata", "Paylaşım başlatılamadı");
    }
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
              .collection("books")
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
