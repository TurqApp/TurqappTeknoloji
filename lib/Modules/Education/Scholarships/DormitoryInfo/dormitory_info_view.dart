import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class DormitoryInfoView extends StatelessWidget {
  DormitoryInfoView({super.key});

  final DormitoryInfoController controller = Get.put(DormitoryInfoController());
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Expanded(
                  child: BackButtons(text: 'dormitory.title'.tr),
                ),
                PullDownButton(
                  itemBuilder: (context) => [
                    PullDownMenuItem(
                      title: 'dormitory.reset_menu'.tr,
                      icon: CupertinoIcons.restart,
                      onTap: () {
                        noYesAlert(
                          title: 'dormitory.reset_title'.tr,
                          message: 'dormitory.reset_body'.tr,
                          cancelText: 'common.cancel'.tr,
                          yesText: 'common.reset'.tr,
                          yesButtonColor: CupertinoColors.destructiveRed,
                          onYesPressed: () async {
                            controller.yurt.value = "";
                            controller.sehir.value = controller.selectCityValue;
                            controller.ilce.value =
                                controller.selectDistrictValue;
                            controller.sub.value =
                                controller.selectAdminTypeValue;
                            controller.listedeYok.value = false;
                            controller.yurtInput.clear();
                            controller.yurtInputText.value = "";
                            controller.yurtSelectionController.clear();

                            await _userRepository.updateUserFields(
                              CurrentUserService.instance.userId,
                              scopedUserUpdate(
                                scope: 'family',
                                values: {"yurt": ""},
                              ),
                            );

                            AppSnackbar(
                              'common.success'.tr,
                              'dormitory.reset_success'.tr,
                            );
                          },
                        );
                      },
                    ),
                  ],
                  buttonBuilder: (context, showMenu) => AppHeaderActionButton(
                    onTap: showMenu,
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? Center(child: CupertinoActivityIndicator())
                    : SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (controller.yurt.value != "")
                                Container(
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'dormitory.current_info'.tr,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          controller.yurt.value,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: controller.showIlSec,
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.grey
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Obx(
                                            () => Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  controller.sehir.value ==
                                                          controller
                                                              .selectCityValue
                                                      ? 'common.select_city'.tr
                                                      : controller.sehir.value,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                ),
                                                Icon(
                                                  CupertinoIcons.chevron_down,
                                                  size: 20,
                                                  color: Colors.black,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: controller.showIdariSec,
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.grey
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Obx(
                                            () => Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  controller.capitalize(
                                                    controller.localizedAdminType(
                                                      controller.sub.value,
                                                    ),
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                ),
                                                Icon(
                                                  CupertinoIcons.chevron_down,
                                                  size: 20,
                                                  color: Colors.black,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (controller.sehir.value !=
                                      controller.selectCityValue &&
                                  controller.sub.value !=
                                      controller.selectAdminTypeValue)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: GestureDetector(
                                    onTap: controller.showYurtSec,
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: TextField(
                                          controller: controller
                                              .yurtSelectionController,
                                          enabled: false,
                                          decoration: InputDecoration(
                                            hintText:
                                                'dormitory.select_dormitory'.tr,
                                            hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: "MontserratMedium",
                                            ),
                                            border: InputBorder.none,
                                            suffixIcon: Icon(
                                              CupertinoIcons.chevron_down,
                                              color: Colors.black,
                                              size: 20,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (controller.sehir.value !=
                                      controller.selectCityValue &&
                                  controller.sub.value !=
                                      controller.selectAdminTypeValue)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: controller.toggleListedeYok,
                                        child: Container(
                                          height: 20,
                                          width: 20,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(4),
                                            ),
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          child: Obx(
                                            () => controller.listedeYok.value
                                                ? Icon(
                                                    Icons.check,
                                                    color: Colors.black,
                                                    size: 20,
                                                  )
                                                : SizedBox(),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "common.not_listed".tr,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (controller.listedeYok.value &&
                                  controller.sehir.value !=
                                      controller.selectCityValue &&
                                  controller.sub.value !=
                                      controller.selectAdminTypeValue)
                                Container(
                                  alignment: Alignment.center,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: TextField(
                                      cursorColor: Colors.black,
                                      controller: controller.yurtInput,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      keyboardType: TextInputType.text,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(50),
                                      ],
                                      decoration: InputDecoration(
                                        hintText:
                                            "scholarship.dormitory_name_hint"
                                                .tr,
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: "MontserratMedium",
                                        ),
                                        border: InputBorder.none,
                                        suffixIcon: Obx(
                                          () => controller.yurtInputText.value
                                                  .isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.clear,
                                                    color: Colors.grey,
                                                  ),
                                                  onPressed: () {
                                                    controller.yurtInput
                                                        .clear();
                                                    controller.yurtInputText
                                                        .value = "";
                                                  },
                                                )
                                              : SizedBox(),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            Obx(
              () => (controller.listedeYok.value &&
                          controller.yurtInputText.value.isNotEmpty) ||
                      (!controller.listedeYok.value &&
                          controller.yurt.value.isNotEmpty)
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: controller.saveData,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                                child: Text(
                                  'common.save'.tr,
                                  style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
