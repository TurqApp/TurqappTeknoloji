import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'optical_preview_controller_facade_part.dart';
part 'optical_preview_controller_runtime_part.dart';

class OpticalPreviewController extends GetxController {
  static OpticalPreviewController ensure(
    OpticalFormModel model,
    Function? onUpdate, {
    String? tag,
    bool permanent = false,
  }) =>
      _ensureOpticalPreviewController(
        model,
        onUpdate,
        tag: tag,
        permanent: permanent,
      );

  static OpticalPreviewController? maybeFind({String? tag}) =>
      _maybeFindOpticalPreviewController(tag: tag);

  final OpticalFormModel model;
  final Function? onUpdate;
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();

  final cevaplar = <String>[].obs;
  final isConnected = true.obs;
  final selection = 0.obs;
  final fullName = TextEditingController();
  final ogrenciNo = TextEditingController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  OpticalPreviewController(this.model, this.onUpdate) {
    _initialize();
  }

  void _initialize() => _initializeOpticalPreviewController(this);

  @override
  void onClose() {
    _handleOpticalPreviewClose(this);
    super.onClose();
  }

  void checkInternetConnection() => _checkOpticalPreviewInternetFacade(this);

  void setData() => _saveOpticalPreviewDataFacade(this);

  void kullaniciyiSinavGirdiKaydet() =>
      _initializeOpticalPreviewAnswersFacade(this);

  void toggleAnswer(int index, String item) =>
      _toggleOpticalPreviewAnswerFacade(this, index, item);

  void handleFinishTest(BuildContext context) =>
      _handleOpticalPreviewFinishFacade(this);

  void startTest() => _startOpticalPreviewTest(this);

  bool canStartTest() => _canStartOpticalPreviewTest(this);

  void showAlertDialog(String title, String desc) =>
      _showOpticalPreviewAlertFacade(title, desc);
}
