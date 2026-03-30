part of 'scholarship_detail_controller_library.dart';

extension ScholarshipDetailControllerActionsPart
    on ScholarshipDetailController {
  Future<void> applyForScholarship(String scholarshipId, String type) async {
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    if (currentUserId.isEmpty) {
      AppSnackbar("common.error".tr, "scholarship.login_required".tr);
      return;
    }

    try {
      isLoading.value = true;
      await checkUserApplicationReadiness();

      if (!applyReady.value) {
        return;
      }

      await _scholarshipRepository.applyForScholarship(
        scholarshipId: scholarshipId,
        userId: currentUserId,
      );

      allreadyApplied.value = true;
      AppSnackbar("common.success".tr, "scholarship.applied_success".tr);
    } catch (e) {
      AppSnackbar("common.error".tr, "scholarship.apply_failed".tr);
    } finally {
      isLoading.value = false;
    }
  }

  void updatePageIndex(int pageIndex) {
    currentPageIndex.value = pageIndex;
  }

  void toggleUniversityList() {
    showAllUniversities.value = !showAllUniversities.value;
  }

  Future<void> toggleFollowStatus(String userID) async {
    if (isFollowLoading.value) return;
    final wasFollowing = isFollowing.value;
    isFollowing.value = !wasFollowing;
    isFollowLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollowFromLocalState(
        userID,
        assumedFollowing: wasFollowing,
      );
      isFollowing.value = outcome.nowFollowing;
      if (outcome.limitReached) {
        AppSnackbar(
          'scholarship.follow_limit_title'.tr,
          'scholarship.follow_limit_body'.tr,
        );
      }
    } catch (e) {
      isFollowing.value = wasFollowing;
      AppSnackbar("common.error".tr, "scholarship.follow_failed".tr);
    } finally {
      isFollowLoading.value = false;
    }
  }

  Future<void> deleteScholarship(String scholarshipId, String type) async {
    if (scholarshipId.isEmpty) {
      AppSnackbar("common.error".tr, "scholarship.invalid".tr);
      return;
    }

    try {
      isLoading.value = true;
      await _scholarshipRepository.deleteScholarship(
        scholarshipId: scholarshipId,
        actorUserId: CurrentUserService.instance.effectiveUserId,
      );
      Get.back();
      await maybeFindScholarshipsController()?.fetchScholarships();
      AppSnackbar("common.success".tr, "scholarship.delete_success".tr);
    } catch (e) {
      AppSnackbar("common.error".tr, "scholarship.delete_failed".tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelApplication(String scholarshipId, String type) async {
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    if (currentUserId.isEmpty) {
      AppSnackbar("common.error".tr, "scholarship.login_required".tr);
      return;
    }

    try {
      isLoading.value = true;
      await _scholarshipRepository.cancelScholarshipApplication(
        scholarshipId: scholarshipId,
        userId: currentUserId,
      );

      allreadyApplied.value = false;
      await checkUserApplicationReadiness();
      AppSnackbar("common.success".tr, "scholarship.cancel_success".tr);
    } catch (e) {
      AppSnackbar("common.error".tr, "scholarship.cancel_failed".tr);
    } finally {
      isLoading.value = false;
    }
  }
}
