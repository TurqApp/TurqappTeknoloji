import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalPreview/optical_preview.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'optical_form_entry_controller_data_part.dart';
part 'optical_form_entry_controller_actions_part.dart';

class OpticalFormEntryController extends GetxController {
  static OpticalFormEntryController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      OpticalFormEntryController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static OpticalFormEntryController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<OpticalFormEntryController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<OpticalFormEntryController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  final search = TextEditingController();
  final focusNode = FocusNode();
  final searchText = ''.obs; // Reactive search text
  final model = Rx<OpticalFormModel?>(null);
  final fullName = ''.obs;
  final avatarUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
