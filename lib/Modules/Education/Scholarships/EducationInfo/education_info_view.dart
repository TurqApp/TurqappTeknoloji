import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/container_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Education/Scholarships/EducationInfo/education_info_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'education_info_view_actions_part.dart';
part 'education_info_view_fields_part.dart';

class EducationInfoView extends StatefulWidget {
  EducationInfoView({super.key});

  @override
  State<EducationInfoView> createState() => _EducationInfoViewState();
}

class _EducationInfoViewState extends State<EducationInfoView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final EducationInfoController controller;
  final UserRepository _userRepository = UserRepository.ensure();
  final CurrentUserService _currentUserService = CurrentUserService.instance;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_education_${identityHashCode(this)}';
    final existing = maybeFindEducationInfoController(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ?? ensureEducationInfoController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindEducationInfoController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<EducationInfoController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildHeader(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Obx(
                () => Column(
                  children: [
                    SizedBox(height: 50),
                    if (!controller.isInitialLoading.value)
                      Expanded(
                        child: Column(
                          children: [
                            DropdownField(
                              config: FieldConfig(
                                label:
                                    "scholarship.applicant.education_level".tr,
                                items: [
                                  controller.middleSchoolValue,
                                  controller.highSchoolValue,
                                  controller.associateValue,
                                  controller.bachelorValue,
                                  controller.mastersValue,
                                  controller.doctorateValue,
                                ],
                                value: controller.selectedEducationLevel,
                                onSelect: (selected) {
                                  controller.selectedEducationLevel.value =
                                      selected;
                                  controller.loadSavedDataForLevel(selected);
                                },
                                isSearchable: false,
                              ),
                              controller: controller,
                            ),
                            12.ph,
                            Expanded(child: _buildFormFields()),
                            20.ph,
                            _buildSaveButton(),
                            15.ph,
                          ],
                        ),
                      ),
                    if (controller.isInitialLoading.value ||
                        controller.isLoading.value)
                      Expanded(
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
