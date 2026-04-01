import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/job_categories.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/family_info_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'family_info_view_fields_part.dart';
part 'family_info_view_sections_part.dart';

class FamilyInfoView extends StatefulWidget {
  FamilyInfoView({super.key});

  @override
  State<FamilyInfoView> createState() => _FamilyInfoViewState();
}

class _FamilyInfoViewState extends State<FamilyInfoView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final FamilyInfoController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_family_${identityHashCode(this)}';
    final existing = maybeFindFamilyInfoController(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ?? ensureFamilyInfoController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
            maybeFindFamilyInfoController(tag: _controllerTag), controller)) {
      Get.delete<FamilyInfoController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  Widget _buildCustomHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: BackButtons(text: 'family_info.title'.tr)),
        PullDownButton(
          itemBuilder: (context) => [
            PullDownMenuItem(
              title: 'family_info.reset_menu'.tr,
              onTap: () {
                noYesAlert(
                  title: 'family_info.reset_title'.tr,
                  message: 'family_info.reset_body'.tr,
                  cancelText: 'common.cancel'.tr,
                  yesText: 'common.reset'.tr,
                  onYesPressed: () {
                    controller.resetFamilyInfo();
                  },
                );
              },
              icon: CupertinoIcons.refresh,
            ),
          ],
          buttonBuilder: (context, showMenu) => AppHeaderActionButton(
            onTap: showMenu,
            child: Icon(
              AppIcons.ellipsisVertical,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomHeader(),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? Center(child: CupertinoActivityIndicator())
                    : SingleChildScrollView(
                        controller: controller.scrollController,
                        physics: ScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: _buildFormContent(),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaxValueTextInputFormatter extends TextInputFormatter {
  final int maxValue;

  MaxValueTextInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? value = int.tryParse(newValue.text);
    if (value == null || value > maxValue) {
      return oldValue;
    }

    return newValue;
  }
}

class CapitalizeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isNotEmpty) {
      final capitalized = capitalizeWords(newValue.text);
      return newValue.copyWith(
        text: capitalized,
        selection: TextSelection.collapsed(offset: capitalized.length),
      );
    }
    return newValue;
  }
}
