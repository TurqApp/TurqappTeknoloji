import 'dart:async';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateBook/create_book.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AnswerKeyContentController extends GetxController {
  static final Map<String, Set<String>> _savedIdsByUser =
      <String, Set<String>>{};
  static final Map<String, Future<Set<String>>> _savedIdsLoaders =
      <String, Future<Set<String>>>{};
  static AnswerKeyContentController ensure(
    BookletModel model,
    Function(bool) onUpdate, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      AnswerKeyContentController(model, onUpdate),
      tag: tag,
      permanent: permanent,
    );
  }

  static AnswerKeyContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<AnswerKeyContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<AnswerKeyContentController>(tag: tag);
  }

  BookletModel model;
  final Function(bool) onUpdate;

  final isBookmarked = false.obs;
  final secim = ''.obs;

  AnswerKeyContentController(this.model, this.onUpdate);
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  static String _resolveCurrentUid() {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return (FirebaseAuth.instance.currentUser?.uid ?? '').trim();
  }

  bool get isOwner => isCurrentUserId(model.userID);

  void syncModel(BookletModel nextModel) {
    model = nextModel;
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  void _initialize() {
    final currentUserId = _resolveCurrentUid();
    _primeBookmarkState(currentUserId);
    unawaited(_loadBookmarkState(currentUserId));
  }

  void _primeBookmarkState(String currentUserId) {
    if (currentUserId.isEmpty) {
      isBookmarked.value = false;
      return;
    }
    final cachedIds = _savedIdsByUser[currentUserId];
    if (cachedIds != null) {
      isBookmarked.value = cachedIds.contains(model.docID);
      return;
    }
    isBookmarked.value = false;
  }

  Future<void> _loadBookmarkState(String currentUserId) async {
    if (currentUserId.isEmpty) return;

    try {
      final savedIds = await _loadSavedIds(currentUserId);
      isBookmarked.value = savedIds.contains(model.docID);
    } catch (e) {
      log("Kaydet durumu okunamadı: $e");
    }
  }

  static Future<Set<String>> _loadSavedIds(String userId) {
    final cached = _savedIdsByUser[userId];
    if (cached != null) {
      return Future<Set<String>>.value(cached);
    }
    final existingLoader = _savedIdsLoaders[userId];
    if (existingLoader != null) {
      return existingLoader;
    }

    final loader = () async {
      final entries = await UserSubcollectionRepository.ensure().getEntries(
        userId,
        subcollection: 'books',
        orderByField: 'createdAt',
        descending: true,
        preferCache: true,
        forceRefresh: false,
      );
      final ids = entries.map((entry) => entry.id).toSet();
      _savedIdsByUser[userId] = ids;
      return ids;
    }();

    _savedIdsLoaders[userId] = loader;
    return loader.whenComplete(() {
      _savedIdsLoaders.remove(userId);
    });
  }

  static Future<void> warmSavedIdsForCurrentUser() async {
    final userId = _resolveCurrentUid();
    if (userId.isEmpty) return;
    await _loadSavedIds(userId);
  }

  void _updateViewCount() {
    final currentUserId = _resolveCurrentUid();
    if (currentUserId.isNotEmpty && model.userID != currentUserId) {
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
    final userId = _resolveCurrentUid();
    if (userId.isEmpty) return;

    try {
      if (isBookmarked.value) {
        await _userSubcollectionRepository.deleteEntry(
          userId,
          subcollection: 'books',
          docId: model.docID,
        );
        isBookmarked.value = false;
        _savedIdsByUser[userId]?.remove(model.docID);
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
      _savedIdsByUser.putIfAbsent(userId, () => <String>{}).add(model.docID);
    } catch (e) {
      log("Yer işareti değiştirme hatası: $e");
    }
  }

  void navigateToPreview(BuildContext context) {
    _updateViewCount();
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
              child: Text(
                "answer_key.inspect".tr,
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
              child: Text(
                'answer_key.delete_book'.tr,
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
              child: Text(
                'common.edit'.tr,
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
              child: Text(
                'common.cancel'.tr,
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
    final currentUid = _resolveCurrentUid();
    final canShareFeed =
        AdminAccessService.isKnownAdminSync() || model.userID == currentUid;
    if (!canShareFeed) {
      AppSnackbar('common.warning'.tr, 'answer_key.share_owner_only'.tr);
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
                : '${model.sinavTuru} ${'answer_key.book_answer_key_desc'.tr}',
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
      AppSnackbar('common.error'.tr, 'training.share_failed'.tr);
    }
  }

  void showBottomSheet(BuildContext context) {
    if (model.userID != _resolveCurrentUid()) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "answer_key.about_title".tr,
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
                      secim.value = secim.value == "spam" ? "" : "spam";
                      if (secim.value == "spam") {
                        Get.back();
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "common.spam".tr,
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
                                color: secim.value == "spam"
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
      title: "answer_key.delete_book".tr,
      message: "answer_key.delete_book_confirm".tr,
      cancelText: "common.cancel".tr,
      yesText: "common.delete".tr,
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
