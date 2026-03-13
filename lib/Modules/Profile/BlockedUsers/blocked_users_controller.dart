import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import '../../../Models/ogrenci_model.dart';

class BlockedUsersController extends GetxController {
  RxList<String> blockedUsers = <String>[].obs;
  RxList<OgrenciModel> blockedUserDetails = <OgrenciModel>[].obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    fetchBlockedUserIDsAndDetails();
  }

  Future<void> fetchBlockedUserIDsAndDetails() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final entries = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'blockedUsers',
      preferCache: true,
    );
    if (entries.isNotEmpty) {
      blockedUsers.value = entries.map((d) => d.id).toList();
      await fetchBlockedUserDetails();
      return;
    }

    // Legacy fallback
    final data = await _userRepository.getUserRaw(uid);
    if (data != null && data.containsKey("blockedUsers")) {
      blockedUsers.value = List<String>.from(data["blockedUsers"] ?? const []);
      await fetchBlockedUserDetails();
    }
  }

  Future<void> fetchBlockedUserDetails() async {
    blockedUserDetails.clear();

    final profiles = await _userRepository.getUsersRaw(blockedUsers.toList());
    for (final userID in blockedUsers) {
      final data = profiles[userID];
      if (data != null) {
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
                        await _subcollectionRepository.deleteEntry(
                          uid,
                          subcollection: 'blockedUsers',
                          docId: userID,
                        );

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
