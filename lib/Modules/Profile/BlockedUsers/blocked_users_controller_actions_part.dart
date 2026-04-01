part of 'blocked_users_controller.dart';

extension BlockedUsersControllerActionsPart on BlockedUsersController {
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
                      Get.back();
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
                        final uid = _currentUid;
                        await _subcollectionRepository.deleteEntry(
                          uid,
                          subcollection: 'blockedUsers',
                          docId: userID,
                        );
                        await CurrentUserService.instance
                            .removeBlockedUserLocal(userID);
                        await ViewerSurfaceInvalidationService
                            .invalidateForViewer(uid);

                        blockedUsers.remove(userID);
                        blockedUserDetails
                            .removeWhere((e) => e.userID == userID);

                        Get.back();
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
