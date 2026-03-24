import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/ders_ve_sonuclar_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'deneme_sinavi_yap_controller_actions_part.dart';

class DenemeSinaviYapController extends GetxController
    with WidgetsBindingObserver {
  static DenemeSinaviYapController ensure({
    required String tag,
    required SinavModel model,
    required Function sinaviBitir,
    required Function showGecersizAlert,
    required bool uyariAtla,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      DenemeSinaviYapController(
        model: model,
        sinaviBitir: sinaviBitir,
        showGecersizAlert: showGecersizAlert,
        uyariAtla: uyariAtla,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static DenemeSinaviYapController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<DenemeSinaviYapController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<DenemeSinaviYapController>(tag: tag);
  }

  var fullName = "".obs;
  var list = <SoruModel>[].obs;
  var selectedAnswers = <String>[].obs;
  var dersSonuclari = <DersVeSonuclar>[].obs;
  var selection = 0.obs;
  var isConnected = true.obs;
  var hataCount = 0.obs;
  var isLoading = true.obs;
  var isInitialized = false.obs;

  final SinavModel model;
  final Function sinaviBitir;
  final Function showGecersizAlert;
  final bool uyariAtla;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  DenemeSinaviYapController({
    required this.model,
    required this.sinaviBitir,
    required this.showGecersizAlert,
    required this.uyariAtla,
  });

  @override
  void onInit() {
    super.onInit();
    selection.value = uyariAtla ? 0 : 1;
    fetchUserData();
    getSorular();
    checkInternetConnection();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print("Uygulama arka plana atıldı.");
    } else if (state == AppLifecycleState.resumed) {
      print("Uygulama ön plana geldi.");
      if (hataCount.value == 1) {
        sinaviGecersizSay();
      } else {
        AppSnackbar(
          'common.warning'.tr,
          'practice.background_warning'.tr,
        );
      }
      hataCount.value += 1;
      selectedAnswers.value = List<String>.filled(list.length, "");
    } else if (state == AppLifecycleState.detached) {
      sinaviGecersizSay();
    }
  }

  Future<void> fetchUserData() async {
    try {
      final data = await _userSummaryResolver.resolve(
        _currentUserId,
        preferCache: true,
      );
      fullName.value = data?.displayName.trim() ?? '';
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.user_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> getSorular() async {
    try {
      final questions = await _practiceExamRepository.fetchQuestions(
        model.docID,
        preferCache: true,
      );
      list.value = questions;
      selectedAnswers.value = List<String>.filled(questions.length, "");
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.questions_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  void checkInternetConnection() {
    Connectivity().onConnectivityChanged.listen((results) {
      isConnected.value = results.any((r) => r != ConnectivityResult.none);
      print(
        isConnected.value
            ? 'Connectivity available.'
            : 'No internet connection.',
      );
    });
  }
}
