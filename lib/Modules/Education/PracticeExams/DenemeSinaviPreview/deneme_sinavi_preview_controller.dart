import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'deneme_sinavi_preview_controller_actions_part.dart';

class DenemeSinaviPreviewController extends GetxController {
  static DenemeSinaviPreviewController ensure({
    required String tag,
    required SinavModel model,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      DenemeSinaviPreviewController(model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static DenemeSinaviPreviewController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<DenemeSinaviPreviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<DenemeSinaviPreviewController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  var nickname = "".obs;
  var avatarUrl = "".obs;
  var dahaOnceBasvurdu = false.obs;
  var basvuranSayisi = 0.obs;
  var currentTime = DateTime.now().millisecondsSinceEpoch.obs;
  var showSucces = false.obs;
  var sinavaGirebilir = false.obs;
  var examTime = 0.obs;
  var isLoading = true.obs;
  var isInitialized = false.obs;
  var isSaved = false.obs;
  final int fifteenMinutes = 15 * 60 * 1000;

  final SinavModel model;
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  DenemeSinaviPreviewController({required this.model});

  @override
  void onInit() {
    super.onInit();
    examTime.value = model.timeStamp.toInt();
    fetchUserData();
    basvuruKontrol();
    getGecersizlikDurumu();
    syncSavedState();
  }

  Future<void> fetchUserData() => _fetchUserDataImpl();

  Future<void> getGecersizlikDurumu() => _getGecersizlikDurumuImpl();

  Future<void> sinaviBitirAlert() => _sinaviBitirAlertImpl();

  void showGecersizAlert() => _showGecersizAlertImpl();

  Future<void> addBasvuru() => _addBasvuruImpl();

  Future<void> basvuruKontrol() => _basvuruKontrolImpl();

  Future<void> refreshData() => _refreshDataImpl();

  Future<void> syncSavedState() => _syncSavedStateImpl();

  Future<void> toggleSaved() => _toggleSavedImpl();

  Future<void> _fetchUserDataImpl() async {
    try {
      final data = await _userSummaryResolver.resolve(
            model.userID,
            preferCache: true,
          ) ??
          _userSummaryResolver.resolveFromMaps(model.userID);
      nickname.value = data.preferredName;
      avatarUrl.value = data.avatarUrl;
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.user_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> _getGecersizlikDurumuImpl() async {
    try {
      final data = await _practiceExamRepository.fetchRawById(
        model.docID,
        preferCache: true,
      );

      if (data == null || !data.containsKey('gecersizSayilanlar')) {
        sinavaGirebilir.value = true;
        return;
      }

      final gecersizSayilanlar = List<String>.from(
        data['gecersizSayilanlar'] ?? [],
      );
      sinavaGirebilir.value = !gecersizSayilanlar.contains(_currentUserId);
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.invalidity_load_failed'.tr);
      sinavaGirebilir.value = true;
    }
  }

  Future<void> _basvuruKontrolImpl() async {
    try {
      basvuranSayisi.value =
          await _practiceExamRepository.fetchParticipantCount(
        model.docID,
        preferCache: true,
      );
      dahaOnceBasvurdu.value = await _practiceExamRepository.hasApplication(
        model.docID,
        _currentUserId,
      );
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.application_check_failed'.tr);
    }
  }

  Future<void> _refreshDataImpl() async {
    currentTime.value = DateTime.now().millisecondsSinceEpoch;
    await fetchUserData();
    await basvuruKontrol();
    await syncSavedState();
  }

  Future<void> _syncSavedStateImpl() async {
    final savedController = SavedPracticeExamsController.ensure();
    if (savedController.savedExamIds.isEmpty &&
        !savedController.isLoading.value) {
      await savedController.loadSavedExams();
    }
    isSaved.value = savedController.savedExamIds.contains(model.docID);
  }
}
