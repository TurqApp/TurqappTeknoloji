import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';

class ScholarshipDetailController extends GetxController {
  static const String _selectValue = 'Seçiniz';
  static const String _selectActionValue = 'Seçim Yap';
  static const String _selectJobValue = 'Meslek Seç';
  static const String _yesValue = 'Evet';
  static const String _middleSchool = 'Ortaokul';
  static const String _highSchool = 'Lise';
  final UserRepository _userRepository = UserRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  var showAllUniversities = false.obs;
  var hiddenUniversityCount = 0.obs;
  var isLoading = false.obs;
  var isFollowing = false.obs;
  var currentPageIndex = 0.obs;
  final RxBool applyReady = false.obs;
  final RxBool allreadyApplied = false.obs;
  final Rxn<IndividualScholarshipsModel> resolvedModel =
      Rxn<IndividualScholarshipsModel>();
  final RxBool detailLoading = false.obs;
  String? _followInitForId;

  @override
  void onInit() {
    super.onInit();
    checkUserApplicationReadiness();
    final scholarshipData = Get.arguments as Map<String, dynamic>?;
    if (scholarshipData != null) {
      final scholarshipId =
          (scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '')
              .toString();
      if (scholarshipId.isNotEmpty) {
        _loadFullScholarship(scholarshipId);
      }
      checkIfUserAlreadyApplied(scholarshipData);
      _incrementViewCount(scholarshipData);
    }
  }

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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final model = scholarshipData['model'];
    if (model is IndividualScholarshipsModel &&
        model.userID == currentUser.uid) {
      return;
    }
    ScholarshipFirestorePath.doc(docId).update({
      'goruntuleme': FieldValue.arrayUnion([currentUser.uid]),
    }).catchError((_) {});
  }

  Future<void> checkUserApplicationReadiness() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      applyReady.value = false;
      AppSnackbar("common.error".tr, "scholarship.login_required".tr);
      return;
    }

    try {
      isLoading.value = true;
      final data = await _userRepository.getUserRaw(currentUser.uid);

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
                _selectActionValue &&
            userString(data, key: 'engelliRaporu', scope: 'family')
                .isNotEmpty &&
            userString(data, key: 'calismaDurumu', scope: 'profile').isNotEmpty;

        bool isEducationInfoComplete = educationLevel.isNotEmpty &&
            userString(data, key: 'ulke', scope: 'profile').isNotEmpty &&
            (educationLevel == _middleSchool
                ? (userString(data, key: 'ortaOkul', scope: 'education')
                        .isNotEmpty &&
                    userString(data, key: 'sinif', scope: 'education')
                        .isNotEmpty &&
                    userString(data, key: 'il', scope: 'profile').isNotEmpty &&
                    userString(data, key: 'ilce', scope: 'profile').isNotEmpty)
                : educationLevel == _highSchool
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

        bool isFamilyInfoComplete = fatherLiving != _selectValue &&
            motherLiving != _selectValue &&
            userInt(data, key: 'totalLiving', scope: 'family') > 0 &&
            userString(data, key: 'evMulkiyeti', scope: 'family') !=
                _selectActionValue &&
            userString(data, key: 'ikametSehir', scope: 'profile').isNotEmpty &&
            userString(data, key: 'ikametIlce', scope: 'profile').isNotEmpty;

        if (fatherLiving == _yesValue) {
          isFamilyInfoComplete = isFamilyInfoComplete &&
              userString(data, key: 'fatherName', scope: 'family').isNotEmpty &&
              userString(data, key: 'fatherSurname', scope: 'family')
                  .isNotEmpty &&
              userString(data, key: 'fatherJob', scope: 'family') !=
                  _selectJobValue &&
              userString(data, key: 'fatherSalary', scope: 'family')
                  .isNotEmpty &&
              userString(data, key: 'fatherPhone', scope: 'family').isNotEmpty;
        }

        if (motherLiving == _yesValue) {
          isFamilyInfoComplete = isFamilyInfoComplete &&
              userString(data, key: 'motherName', scope: 'family').isNotEmpty &&
              userString(data, key: 'motherSurname', scope: 'family')
                  .isNotEmpty &&
              userString(data, key: 'motherJob', scope: 'family') !=
                  _selectJobValue &&
              userString(data, key: 'motherSalary', scope: 'family')
                  .isNotEmpty &&
              userString(data, key: 'motherPhone', scope: 'family').isNotEmpty;
        }

        applyReady.value = isPersonalInfoComplete &&
            isEducationInfoComplete &&
            isFamilyInfoComplete;
      } else {
        applyReady.value = false;
        AppSnackbar(
          "common.error".tr,
          "scholarship.user_data_missing".tr,
        );
      }
    } catch (e) {
      print('Kullanıcı hazırlık kontrolü hatası: $e');
      AppSnackbar("common.error".tr, "scholarship.check_info_failed".tr);
      applyReady.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkIfUserAlreadyApplied(
      Map<String, dynamic> scholarshipData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      allreadyApplied.value = false;
      return;
    }

    try {
      final String scholarshipId =
          scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '';

      if (scholarshipId.isNotEmpty) {
        allreadyApplied.value = await _scholarshipRepository.hasUserApplied(
          scholarshipId,
          currentUser.uid,
        );
      } else {
        allreadyApplied.value = false;
      }
    } catch (e) {
      AppSnackbar(
        "common.error".tr,
        "scholarship.application_check_failed".tr,
      );
      allreadyApplied.value = false;
    }
  }

  Future<void> applyForScholarship(String scholarshipId, String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppSnackbar("common.error".tr, "scholarship.login_required".tr);
      return;
    }

    try {
      isLoading.value = true;
      await checkUserApplicationReadiness();

      if (!applyReady.value) {
        return;
      }

      final docRef = ScholarshipFirestorePath.doc(scholarshipId);
      final field = 'basvurular';

      await docRef.collection('Basvurular').doc(currentUser.uid).set({
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      });

      await docRef.update({
        field: FieldValue.arrayUnion([currentUser.uid]),
      });
      await _scholarshipRepository.setUserAppliedCache(
        scholarshipId,
        currentUser.uid,
        true,
      );

      allreadyApplied.value = true;
      AppSnackbar("common.success".tr, "scholarship.applied_success".tr);
    } catch (e) {
      AppSnackbar("common.error".tr, "scholarship.apply_failed".tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initializeFollowState(String followedId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      isFollowing.value = false;
      return;
    }
    if (followedId.isEmpty) return;
    if (_followInitForId == followedId) return;
    _followInitForId = followedId;
    final followerId = currentUser.uid;
    isFollowing.value = await _followRepository.isFollowing(
      followedId,
      currentUid: followerId,
    );
  }

  void updatePageIndex(int pageIndex) {
    currentPageIndex.value = pageIndex;
  }

  void toggleUniversityList() {
    showAllUniversities.value = !showAllUniversities.value;
  }

  String formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'common.unspecified'.tr;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd.MM.yyyy').format(date);
  }

  final RxBool isFollowLoading = false.obs;

  Future<void> toggleFollowStatus(String userID) async {
    if (isFollowLoading.value) return;
    final wasFollowing = isFollowing.value;
    isFollowing.value = !wasFollowing; // optimistic
    isFollowLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      isFollowing.value = outcome.nowFollowing; // reconcile
      if (outcome.limitReached) {
        AppSnackbar(
          'scholarship.follow_limit_title'.tr,
          'scholarship.follow_limit_body'.tr,
        );
      }
    } catch (e) {
      isFollowing.value = wasFollowing; // revert
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
      await ScholarshipFirestorePath.doc(scholarshipId).delete();
      Get.back();
      final scholarshipsController = Get.find<ScholarshipsController>();
      await scholarshipsController.fetchScholarships();
      AppSnackbar("common.success".tr, "scholarship.delete_success".tr);
    } catch (e) {
      AppSnackbar("common.error".tr, "scholarship.delete_failed".tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelApplication(String scholarshipId, String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppSnackbar("common.error".tr, "scholarship.login_required".tr);
      return;
    }

    try {
      isLoading.value = true;
      final docRef = ScholarshipFirestorePath.doc(scholarshipId);
      final field = 'basvurular';

      await docRef.collection('Basvurular').doc(currentUser.uid).delete();

      await docRef.update({
        field: FieldValue.arrayRemove([currentUser.uid]),
      });

      allreadyApplied.value = false;
      await checkUserApplicationReadiness();
      AppSnackbar("common.success".tr, "scholarship.cancel_success".tr);
    } catch (e) {
      AppSnackbar("common.error".tr, "scholarship.cancel_failed".tr);
    } finally {
      isLoading.value = false;
    }
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
