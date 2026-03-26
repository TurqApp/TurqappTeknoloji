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

part 'deneme_sinavi_yap_controller_fields_part.dart';
part 'deneme_sinavi_yap_controller_config_part.dart';
part 'deneme_sinavi_yap_controller_facade_part.dart';
part 'deneme_sinavi_yap_controller_runtime_part.dart';
part 'deneme_sinavi_yap_controller_shell_part.dart';

class DenemeSinaviYapController extends GetxController
    with WidgetsBindingObserver {
  static DenemeSinaviYapController ensure({
    required String tag,
    required SinavModel model,
    required Function sinaviBitir,
    required Function showGecersizAlert,
    required bool uyariAtla,
    bool permanent = false,
  }) =>
      _ensureDenemeSinaviYapController(
        tag: tag,
        model: model,
        sinaviBitir: sinaviBitir,
        showGecersizAlert: showGecersizAlert,
        uyariAtla: uyariAtla,
        permanent: permanent,
      );

  static DenemeSinaviYapController? maybeFind({required String tag}) =>
      _maybeFindDenemeSinaviYapController(tag: tag);

  final _DenemeSinaviYapControllerShellState _shellState =
      _DenemeSinaviYapControllerShellState();

  DenemeSinaviYapController({
    required SinavModel model,
    required Function sinaviBitir,
    required Function showGecersizAlert,
    required bool uyariAtla,
  }) {
    _shellState.config = _DenemeSinaviYapControllerConfig(
      model: model,
      sinaviBitir: sinaviBitir,
      showGecersizAlert: showGecersizAlert,
      uyariAtla: uyariAtla,
    );
  }

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
}
