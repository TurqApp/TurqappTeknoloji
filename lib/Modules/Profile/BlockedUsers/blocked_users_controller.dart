import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import '../../../Models/ogrenci_model.dart';

class BlockedUsersController extends GetxController {
  RxList<String> blockedUsers = <String>[].obs;
  RxList<OgrenciModel> blockedUserDetails = <OgrenciModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBlockedUserIDsAndDetails();
  }

  Future<void> fetchBlockedUserIDsAndDetails() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final subSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("blockedUsers")
        .get();
    if (subSnap.docs.isNotEmpty) {
      blockedUsers.value = subSnap.docs.map((d) => d.id).toList();
      await fetchBlockedUserDetails();
      return;
    }

    // Legacy fallback
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    if (doc.exists && doc.data()!.containsKey("blockedUsers")) {
      blockedUsers.value = List<String>.from(doc.get("blockedUsers"));
      await fetchBlockedUserDetails();
    }
  }

  Future<void> fetchBlockedUserDetails() async {
    blockedUserDetails.clear();

    for (var userID in blockedUsers) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userID)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        blockedUserDetails.add(OgrenciModel.fromMap(userID, data));
      }
    }
  }

  Future<void> askToUserAndRemoveBlock(String userID, String nickname) async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Engeli Kaldır",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "$nickname kullanıcısının engelini kaldırmak istediğinizden emin misin?",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back(); // Sheet’i kapat
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Vazgeç",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final userRef = FirebaseFirestore.instance
                            .collection("users")
                            .doc(uid);
                        await userRef.collection("blockedUsers").doc(userID).delete();

                        blockedUsers.remove(userID);
                        blockedUserDetails
                            .removeWhere((e) => e.userID == userID);

                        Get.back(); // Sheet’i kapat
                        AppSnackbar(
                            "Başarılı", "$nickname engelden çıkarıldı.");
                      } catch (e) {
                        AppSnackbar("Hata", "Engel kaldırılamadı.");
                      }
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Engeli Kaldır",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
