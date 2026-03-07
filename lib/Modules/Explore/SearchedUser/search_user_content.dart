import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

class SearchUserContent extends StatelessWidget {
  final OgrenciModel model;
  final bool isSearch;

  const SearchUserContent(
      {super.key, required this.model, required this.isSearch});

  Future<String> _resolveTargetUid() async {
    var targetUid = model.userID.trim();
    if (targetUid.isNotEmpty) return targetUid;
    final handle = model.nickname.trim().toLowerCase();
    if (handle.isEmpty) return "";
    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: handle)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first.id;
    } catch (_) {}
    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .where("nickname", isEqualTo: model.nickname.trim())
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first.id;
    } catch (_) {}
    return "";
  }

  Future<void> _saveRecentIfNeeded(String targetUid) async {
    try {
      final currentUserID = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserID == null || currentUserID.isEmpty) return;
      final userRef =
          FirebaseFirestore.instance.collection("users").doc(currentUserID);
      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        userRef.collection("lastSearches").doc(targetUid),
        {
          "userID": targetUid,
          "updatedDate": DateTime.now().millisecondsSinceEpoch,
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      if (Get.isRegistered<ExploreController>()) {
        await Get.find<ExploreController>().refreshRecentSearchUsers();
      }
    } catch (_) {}
  }

  Future<bool> _isTargetAccountActive(String targetUid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(targetUid)
          .get();
      final data = snap.data();
      if (data == null) return false;
      final deletedAccount = (data['isDeleted'] ?? false) == true;
      final status = (data['accountStatus'] ?? '').toString().toLowerCase();
      if (deletedAccount ||
          status == 'pending_deletion' ||
          status == 'deleted') {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _removeRecent() async {
    final targetUid = await _resolveTargetUid();
    if (targetUid.isEmpty) return;
    try {
      final currentUserID = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserID != null && currentUserID.isNotEmpty) {
        final userRef =
            FirebaseFirestore.instance.collection("users").doc(currentUserID);
        final batch = FirebaseFirestore.instance.batch();
        batch.delete(userRef.collection("lastSearches").doc(targetUid));
        await batch.commit();
      }
    } catch (_) {}
    if (Get.isRegistered<ExploreController>()) {
      await Get.find<ExploreController>().refreshRecentSearchUsers();
      Get.find<ExploreController>().isSearchMode.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final targetUid = await _resolveTargetUid();
                    if (targetUid.isEmpty) return;
                    final isActive = await _isTargetAccountActive(targetUid);
                    if (!isActive) {
                      await _removeRecent();
                      Get.snackbar(
                        'Bilgi',
                        'Bu hesap artık görüntülenemiyor.',
                        snackPosition: SnackPosition.TOP,
                        duration: const Duration(seconds: 2),
                      );
                      return;
                    }
                    Get.to(
                      () => SocialProfile(userID: targetUid),
                      preventDuplicates: false,
                    );
                    await _saveRecentIfNeeded(targetUid);
                  },
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.withAlpha(50)),
                        ),
                        child: ClipOval(
                          child: model.avatarUrl != ""
                              ? SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CachedNetworkImage(
                                    imageUrl: model.avatarUrl,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: CupertinoActivityIndicator(
                                        color: Colors.grey),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    model.nickname,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                  RozetContent(size: 14, userID: model.userID)
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "${model.firstName.trimRight()} ${model.lastName.trimRight()}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isSearch)
                TextButton(
                  onPressed: _removeRecent,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(4, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 20,
                    color: Colors.grey,
                  ),
                )
              else
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.blueAccent,
                  size: 15,
                )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 15, left: 65),
          child: SizedBox(
            height: 1,
            child: Divider(color: Colors.grey.withAlpha(20)),
          ),
        ),
      ],
    );
  }
}
