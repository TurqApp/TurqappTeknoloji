import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../Models/ogrenci_model.dart';

class BlockedUsersController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  RxList<String> blockedUsers = <String>[].obs;
  RxList<OgrenciModel> blockedUserDetails = <OgrenciModel>[].obs;
  RxBool isLoading = true.obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapBlockedUsers());
  }

  Future<void> _bootstrapBlockedUsers() async {
    final hasLocal = await _hydrateBlockedUsersFromCache();
    if (hasLocal) {
      isLoading.value = false;
      final uid = CurrentUserService.instance.userId;
      if (uid.isNotEmpty &&
          SilentRefreshGate.shouldRefresh(
            'blocked_users:$uid',
            minInterval: _silentRefreshInterval,
          )) {
        unawaited(fetchBlockedUserIDsAndDetails(
          silent: true,
          forceRefresh: true,
        ));
      }
      return;
    }
    await fetchBlockedUserIDsAndDetails();
  }

  Future<bool> _hydrateBlockedUsersFromCache() async {
    final uid = CurrentUserService.instance.userId;
    final entries = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'blockedUsers',
      preferCache: true,
      cacheOnly: true,
    );
    if (entries.isNotEmpty) {
      blockedUsers.value = entries.map((d) => d.id).toList();
      await fetchBlockedUserDetails(cacheOnly: true);
      return blockedUserDetails.isNotEmpty;
    }

    final data = await _userRepository.getUserRaw(uid, cacheOnly: true);
    if (data != null && data.containsKey("blockedUsers")) {
      blockedUsers.value = List<String>.from(data["blockedUsers"] ?? const []);
      await fetchBlockedUserDetails(cacheOnly: true);
      return blockedUsers.isNotEmpty;
    }
    return false;
  }

  Future<void> fetchBlockedUserIDsAndDetails({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.userId;
      final entries = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'blockedUsers',
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (entries.isNotEmpty) {
        blockedUsers.value = entries.map((d) => d.id).toList();
        await fetchBlockedUserDetails(
          cacheOnly: false,
          preferCache: !forceRefresh,
        );
        SilentRefreshGate.markRefreshed('blocked_users:$uid');
        return;
      }

      // Legacy fallback
      final data = await _userRepository.getUserRaw(
        uid,
        preferCache: !forceRefresh,
        forceServer: forceRefresh,
      );
      if (data != null && data.containsKey("blockedUsers")) {
        blockedUsers.value =
            List<String>.from(data["blockedUsers"] ?? const <String>[]);
        await fetchBlockedUserDetails(
          cacheOnly: false,
          preferCache: !forceRefresh,
        );
        SilentRefreshGate.markRefreshed('blocked_users:$uid');
        return;
      }
      blockedUsers.clear();
      blockedUserDetails.clear();
      SilentRefreshGate.markRefreshed('blocked_users:$uid');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBlockedUserDetails({
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (blockedUsers.isEmpty) {
      blockedUserDetails.clear();
      return;
    }

    final profiles = await _userSummaryResolver.resolveMany(
      blockedUsers.toList(),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final nextDetails = <OgrenciModel>[];
    for (final userID in blockedUsers) {
      final data = profiles[userID];
      if (data != null) {
        nextDetails.add(
          OgrenciModel(
            userID: userID,
            firstName: data.displayName,
            lastName: '',
            avatarUrl: data.avatarUrl,
            nickname: data.preferredName,
          ),
        );
      }
    }
    blockedUserDetails.assignAll(nextDetails);
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
            Text(
              "blocked_users.unblock_confirm_title".tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "blocked_users.unblock_confirm_body".trParams({
                'nickname': nickname,
              }),
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
                      child: Text(
                        "common.cancel".tr,
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
                        final uid = CurrentUserService.instance.userId;
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
                          "common.success".tr,
                          "blocked_users.unblock_success"
                              .trParams({'nickname': nickname}),
                        );
                      } catch (e) {
                        AppSnackbar(
                          "common.error".tr,
                          "blocked_users.unblock_failed".tr,
                        );
                      }
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "blocked_users.unblock".tr,
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
