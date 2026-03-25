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

part 'deneme_sinavi_yap_controller_runtime_part.dart';

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
    _DenemeSinaviYapControllerRuntimePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _DenemeSinaviYapControllerRuntimePart(this).handleOnClose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _DenemeSinaviYapControllerRuntimePart(this)
        .didChangeAppLifecycleState(state);
  }

  Future<void> fetchUserData() =>
      _DenemeSinaviYapControllerRuntimePart(this).fetchUserData();

  Future<void> getSorular() =>
      _DenemeSinaviYapControllerRuntimePart(this).getSorular();

  void checkInternetConnection() =>
      _DenemeSinaviYapControllerRuntimePart(this).checkInternetConnection();

  void sinaviGecersizSay() =>
      _DenemeSinaviYapControllerRuntimePart(this).sinaviGecersizSay();

  Future<void> setData() =>
      _DenemeSinaviYapControllerRuntimePart(this).setData();

  Future<void> refreshData() =>
      _DenemeSinaviYapControllerRuntimePart(this).refreshData();
}
