import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'deneme_sinavi_preview_controller_fields_part.dart';
part 'deneme_sinavi_preview_controller_actions_part.dart';
part 'deneme_sinavi_preview_controller_runtime_part.dart';

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
  final int fifteenMinutes = 15 * 60 * 1000;
  final _state = _DenemeSinaviPreviewControllerState();
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

  Future<void> fetchUserData() =>
      DenemeSinaviPreviewControllerRuntimePart(this).fetchUserData();

  Future<void> getGecersizlikDurumu() =>
      DenemeSinaviPreviewControllerRuntimePart(this).getGecersizlikDurumu();

  Future<void> sinaviBitirAlert() => _sinaviBitirAlertImpl();

  void showGecersizAlert() => _showGecersizAlertImpl();

  Future<void> addBasvuru() => _addBasvuruImpl();

  Future<void> basvuruKontrol() =>
      DenemeSinaviPreviewControllerRuntimePart(this).basvuruKontrol();

  Future<void> refreshData() =>
      DenemeSinaviPreviewControllerRuntimePart(this).refreshData();

  Future<void> syncSavedState() =>
      DenemeSinaviPreviewControllerRuntimePart(this).syncSavedState();

  Future<void> toggleSaved() => _toggleSavedImpl();
}
