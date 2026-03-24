import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/future_date_picker_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/multiple_choice_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/multiple_choice_bottom_sheet2.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_view.dart';
import 'dart:io';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'create_scholarship_basic_part.dart';
part 'create_scholarship_extra_part.dart';
part 'create_scholarship_extra_targeting_part.dart';
part 'create_scholarship_media_part.dart';

class CreateScholarshipView extends StatefulWidget {
  const CreateScholarshipView({super.key});

  @override
  State<CreateScholarshipView> createState() => _CreateScholarshipViewState();
}

class _CreateScholarshipViewState extends State<CreateScholarshipView> {
  late final CreateScholarshipController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'create_scholarship_${identityHashCode(this)}';
    final existing = CreateScholarshipController.maybeFind(tag: _controllerTag);
    _ownsController = existing == null;
    controller =
        existing ?? CreateScholarshipController.ensure(tag: _controllerTag);
    controller.controllerTag = _controllerTag;
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          CreateScholarshipController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<CreateScholarshipController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Obx(
              () => controller.currentSection.value == 1
                  ? buildTemelBilgiler(context, controller)
                  : controller.currentSection.value == 2
                      ? buildBasvuruBilgileri(context, controller)
                      : controller.currentSection.value == 3
                          ? buildEkBilgiler(context, controller)
                          : buildGorsel(context, controller),
            ),
          ),
        ),
      ),
    );
  }
}
