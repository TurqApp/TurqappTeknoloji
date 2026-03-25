import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'optical_preview_controller_runtime_part.dart';

class OpticalPreviewController extends GetxController {
  static OpticalPreviewController ensure(
    OpticalFormModel model,
    Function? onUpdate, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      OpticalPreviewController(model, onUpdate),
      tag: tag,
      permanent: permanent,
    );
  }

  static OpticalPreviewController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<OpticalPreviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<OpticalPreviewController>(tag: tag);
  }

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
    _disposeOpticalPreviewController(this);
    super.onClose();
  }

  void checkInternetConnection() => _checkOpticalPreviewInternet(this);

  void setData() => _saveOpticalPreviewData(this);

  void kullaniciyiSinavGirdiKaydet() => _initializeOpticalPreviewAnswers(this);

  void toggleAnswer(int index, String item) =>
      _toggleOpticalPreviewAnswer(this, index, item);

  void handleFinishTest(BuildContext context) =>
      _handleOpticalPreviewFinish(this);

  void startTest() {
    selection.value = 1;
  }

  bool canStartTest() {
    return fullName.text.trim().length >= 6 && ogrenciNo.text.trim().isNotEmpty;
  }

  void showAlertDialog(String title, String desc) =>
      _showOpticalPreviewAlert(title, desc);
}
