part of 'scholarship_detail_controller.dart';

extension ScholarshipDetailControllerDataPart on ScholarshipDetailController {
  Future<void> _loadFullScholarship(String scholarshipId) async {
    try {
      detailLoading.value = true;
      final model = await _scholarshipRepository.fetchById(
        scholarshipId,
        preferCache: true,
      );
      if (model != null) {
        resolvedModel.value = model;
      }
    } catch (_) {
      // keep summary model from list
    } finally {
      detailLoading.value = false;
    }
  }

  void _incrementViewCount(Map<String, dynamic> scholarshipData) {
    final docId =
        scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '';
    if (docId.isEmpty) return;
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    if (currentUserId.isEmpty) return;
    final model = scholarshipData['model'];
    if (model is IndividualScholarshipsModel && model.userID == currentUserId) {
      return;
    }
    ScholarshipFirestorePath.doc(docId).update({
      'goruntuleme': FieldValue.arrayUnion([currentUserId]),
    }).catchError((_) {});
  }

  Future<void> checkUserApplicationReadiness({bool showErrors = true}) async {
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    if (currentUserId.isEmpty) {
      applyReady.value = false;
      if (showErrors) {
        AppSnackbar("common.error".tr, "scholarship.login_required".tr);
      }
      return;
    }

    try {
      isLoading.value = true;
      final data = await _userRepository.getUserRaw(currentUserId);

      if (data != null) {
        final educationLevel =
            userString(data, key: 'educationLevel', scope: 'education');
        final fatherLiving =
            userString(data, key: 'fatherLiving', scope: 'family');
        final motherLiving =
            userString(data, key: 'motherLiving', scope: 'family');

        bool isPersonalInfoComplete = userString(data,
                    key: 'ulke', scope: 'profile')
                .isNotEmpty &&
            userString(data, key: 'nufusSehir', scope: 'profile').isNotEmpty &&
            userString(data, key: 'nufusIlce', scope: 'profile').isNotEmpty &&
            userString(data, key: 'dogumTarihi', scope: 'profile').isNotEmpty &&
            userString(data, key: 'medeniHal', scope: 'profile').isNotEmpty &&
            userString(data, key: 'cinsiyet', scope: 'profile') !=
                ScholarshipDetailController._selectActionValue &&
            userString(data, key: 'engelliRaporu', scope: 'family')
                .isNotEmpty &&
            userString(data, key: 'calismaDurumu', scope: 'profile').isNotEmpty;

        bool isEducationInfoComplete = educationLevel.isNotEmpty &&
            userString(data, key: 'ulke', scope: 'profile').isNotEmpty &&
            (educationLevel == ScholarshipDetailController._middleSchool
                ? (userString(data, key: 'ortaOkul', scope: 'education')
                        .isNotEmpty &&
                    userString(data, key: 'sinif', scope: 'education')
                        .isNotEmpty &&
                    userString(data, key: 'il', scope: 'profile').isNotEmpty &&
                    userString(data, key: 'ilce', scope: 'profile').isNotEmpty)
                : educationLevel == ScholarshipDetailController._highSchool
                    ? (userString(data, key: 'lise', scope: 'education')
                            .isNotEmpty &&
                        userString(data, key: 'sinif', scope: 'education')
                            .isNotEmpty &&
                        userString(data, key: 'il', scope: 'profile')
                            .isNotEmpty &&
                        userString(data, key: 'ilce', scope: 'profile')
                            .isNotEmpty)
                    : (userString(data,
                                key: 'universite', scope: 'education')
                            .isNotEmpty &&
                        userString(data, key: 'fakulte', scope: 'education')
                            .isNotEmpty &&
                        userString(data, key: 'bolum', scope: 'education')
                            .isNotEmpty &&
                        userString(data, key: 'il', scope: 'profile')
                            .isNotEmpty));

        bool isFamilyInfoComplete =
            fatherLiving != ScholarshipDetailController._selectValue &&
            motherLiving != ScholarshipDetailController._selectValue &&
            userInt(data, key: 'totalLiving', scope: 'family') > 0 &&
            userString(data, key: 'evMulkiyeti', scope: 'family') !=
                ScholarshipDetailController._selectActionValue &&
            userString(data, key: 'ikametSehir', scope: 'profile').isNotEmpty &&
            userString(data, key: 'ikametIlce', scope: 'profile').isNotEmpty;

        if (fatherLiving == ScholarshipDetailController._yesValue) {
          isFamilyInfoComplete = isFamilyInfoComplete &&
              userString(data, key: 'fatherName', scope: 'family').isNotEmpty &&
              userString(data, key: 'fatherSurname', scope: 'family')
                  .isNotEmpty &&
              userString(data, key: 'fatherJob', scope: 'family') !=
                  ScholarshipDetailController._selectJobValue &&
              userString(data, key: 'fatherSalary', scope: 'family')
                  .isNotEmpty &&
              userString(data, key: 'fatherPhone', scope: 'family').isNotEmpty;
        }

        if (motherLiving == ScholarshipDetailController._yesValue) {
          isFamilyInfoComplete = isFamilyInfoComplete &&
              userString(data, key: 'motherName', scope: 'family').isNotEmpty &&
              userString(data, key: 'motherSurname', scope: 'family')
                  .isNotEmpty &&
              userString(data, key: 'motherJob', scope: 'family') !=
                  ScholarshipDetailController._selectJobValue &&
              userString(data, key: 'motherSalary', scope: 'family')
                  .isNotEmpty &&
              userString(data, key: 'motherPhone', scope: 'family').isNotEmpty;
        }

        applyReady.value = isPersonalInfoComplete &&
            isEducationInfoComplete &&
            isFamilyInfoComplete;
      } else {
        applyReady.value = false;
        if (showErrors) {
          AppSnackbar(
            "common.error".tr,
            "scholarship.user_data_missing".tr,
          );
        }
      }
    } catch (e) {
      print('Kullanıcı hazırlık kontrolü hatası: $e');
      if (showErrors) {
        AppSnackbar("common.error".tr, "scholarship.check_info_failed".tr);
      }
      applyReady.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkIfUserAlreadyApplied(
    Map<String, dynamic> scholarshipData, {
    bool showErrors = true,
  }) async {
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    if (currentUserId.isEmpty) {
      allreadyApplied.value = false;
      return;
    }

    try {
      final String scholarshipId =
          scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '';

      if (scholarshipId.isNotEmpty) {
        allreadyApplied.value = await _scholarshipRepository.hasUserApplied(
          scholarshipId,
          currentUserId,
        );
      } else {
        allreadyApplied.value = false;
      }
    } catch (e) {
      if (showErrors) {
        AppSnackbar(
          "common.error".tr,
          "scholarship.application_check_failed".tr,
        );
      }
      allreadyApplied.value = false;
    }
  }

  Future<void> initializeFollowState(String followedId) async {
    final followerId = CurrentUserService.instance.effectiveUserId;
    if (followerId.isEmpty) {
      isFollowing.value = false;
      return;
    }
    if (followedId.isEmpty) return;
    if (_followInitForId == followedId) return;
    _followInitForId = followedId;
    isFollowing.value = await _followRepository.isFollowing(
      followedId,
      currentUid: followerId,
    );
  }

  String formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'common.unspecified'.tr;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Future<List<String>> getApplicantIds(String scholarshipId) {
    return _scholarshipRepository.fetchApplicantIds(
      scholarshipId,
      preferCache: true,
    );
  }

  Future<int> getApplicantCount(String scholarshipId) {
    return _scholarshipRepository.fetchApplicantCount(
      scholarshipId,
      preferCache: true,
    );
  }
}
