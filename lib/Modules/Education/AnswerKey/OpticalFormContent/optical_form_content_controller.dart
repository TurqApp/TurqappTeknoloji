import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

part 'optical_form_content_controller_ui_part.dart';
part 'optical_form_content_controller_data_part.dart';

class OpticalFormContentController extends GetxController {
  static OpticalFormContentController ensure(
    OpticalFormModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      OpticalFormContentController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static OpticalFormContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<OpticalFormContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<OpticalFormContentController>(tag: tag);
  }

  final OpticalFormModel model;
  final total = 0.obs;
  final OpticalFormRepository _opticalFormRepository =
      ensureOpticalFormRepository();

  OpticalFormContentController(this.model) {
    fetchTotal();
  }
}
