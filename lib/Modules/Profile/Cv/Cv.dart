import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv_controller.dart';

part 'cv_personal_part.dart';
part 'cv_education_part.dart';
part 'cv_other_part.dart';

class Cv extends StatefulWidget {
  const Cv({super.key});

  @override
  State<Cv> createState() => _CvState();
}

class _CvState extends State<Cv> {
  late final CvController controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'cv_${identityHashCode(this)}';
    controller = CvController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (CvController.maybeFind(tag: _controllerTag) != null &&
        identical(
          CvController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<CvController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle('cv.title'.tr),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('cv.personal_info'.tr),
                const SizedBox(height: 12),
                step1(),
                const SizedBox(height: 24),
                _sectionTitle('cv.education_info'.tr),
                const SizedBox(height: 12),
                step2(),
                const SizedBox(height: 24),
                _sectionTitle('cv.other_info'.tr),
                const SizedBox(height: 12),
                step3(),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    if (controller.isSaving.value) return;
                    if (controller.firstName.text.trim().isEmpty) {
                      AppSnackbar(
                          'cv.missing_field'.tr, 'cv.missing_first_name'.tr);
                    } else if (controller.lastName.text.trim().isEmpty) {
                      AppSnackbar(
                          'cv.missing_field'.tr, 'cv.missing_last_name'.tr);
                    } else if (controller.mail.text.trim().isEmpty) {
                      AppSnackbar('cv.missing_field'.tr, 'cv.missing_email'.tr);
                    } else if (!controller
                        .validateEmail(controller.mail.text.trim())) {
                      AppSnackbar(
                          'cv.invalid_format'.tr, 'cv.invalid_email'.tr);
                    } else if (controller.phoneNumber.text.trim().isEmpty) {
                      AppSnackbar('cv.missing_field'.tr, 'cv.missing_phone'.tr);
                    } else if (!controller
                        .validatePhone(controller.phoneNumber.text)) {
                      AppSnackbar(
                          'cv.invalid_format'.tr, 'cv.invalid_phone'.tr);
                    } else if (controller.onYazi.text.trim().isEmpty) {
                      AppSnackbar('cv.missing_field'.tr, 'cv.missing_about'.tr);
                    } else if (controller.okullar.isEmpty) {
                      AppSnackbar(
                          'cv.missing_field'.tr, 'cv.missing_school'.tr);
                    } else {
                      controller.setData();
                    }
                  },
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'cv.save'.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontFamily: "MontserratBold",
      ),
    );
  }

  Widget _buildAddRow({
    required String text,
    required VoidCallback onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.add,
              color: Colors.black,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontFamily: "MontserratMedium",
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
