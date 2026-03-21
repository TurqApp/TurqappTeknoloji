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
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/BankInfo/bank_info_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class BankInfoView extends StatefulWidget {
  BankInfoView({super.key});

  @override
  State<BankInfoView> createState() => _BankInfoViewState();
}

class _BankInfoViewState extends State<BankInfoView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final BankInfoController controller;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_bank_${identityHashCode(this)}';
    _ownsController = !Get.isRegistered<BankInfoController>(tag: _controllerTag);
    controller = _ownsController
        ? Get.put(BankInfoController(), tag: _controllerTag)
        : Get.find<BankInfoController>(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<BankInfoController>(tag: _controllerTag)) {
      final registeredController =
          Get.find<BankInfoController>(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<BankInfoController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: BackButtons(text: 'bank_info.title'.tr),
                  ),
                  PullDownButton(
                    itemBuilder: (context) => [
                      PullDownMenuItem(
                        title: 'bank_info.reset_menu'.tr,
                        icon: CupertinoIcons.restart,
                        onTap: () {
                          noYesAlert(
                            title: 'bank_info.reset_title'.tr,
                            message: 'bank_info.reset_body'.tr,
                            cancelText: 'common.cancel'.tr,
                            yesText: 'common.reset'.tr,
                            yesButtonColor: CupertinoColors.destructiveRed,
                            onYesPressed: () async {
                              controller.selectedBank.value =
                                  controller.defaultBankSelection;
                              controller.kolayAdres.value =
                                  controller.defaultFastTypeEmail;
                              controller.iban.clear();
                              await _userRepository.updateUserFields(
                                CurrentUserService.instance.userId,
                                {
                                ...scopedUserUpdate(
                                  scope: 'finance',
                                  values: {
                                    "iban": "",
                                    "bank": "",
                                  },
                                ),
                                ...scopedUserUpdate(
                                  scope: 'preferences',
                                  values: {
                                    "kolayAdresSelection": "",
                                  },
                                ),
                              },
                              );
                              AppSnackbar(
                                'common.success'.tr,
                                'bank_info.reset_success'.tr,
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
              Obx(
                () => controller.isLoading.value
                    ? Center(child: CupertinoActivityIndicator())
                    : Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'bank_info.fast_title'.tr,
                                  style: TextStyles.textFieldTitle,
                                ),
                                GestureDetector(
                                  onTap: () => controller
                                      .showKolayAdresBottomSheet(context),
                                  child: Container(
                                    height: 50,
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                    ),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: Obx(
                                        () => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              controller.localizedFastType(
                                                controller.kolayAdres.value,
                                              ),
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.chevron_down,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'bank_info.bank_label'.tr,
                                  style: TextStyles.textFieldTitle,
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      controller.showBankBottomSheet(context),
                                  child: Container(
                                    height: 50,
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                    ),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: Obx(
                                        () => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              controller.selectedBank.value ==
                                                      controller
                                                          .defaultBankSelection
                                                  ? 'bank_info.select_bank'.tr
                                                  : controller
                                                      .selectedBank.value,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.chevron_down,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  controller.localizedFastType(
                                    controller.kolayAdres.value,
                                  ),
                                  style: TextStyles.textFieldTitle,
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(20),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8)),
                                  ),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        Obx(
                                          () => controller.isIbanSelected
                                              ? Row(
                                                  children: [
                                                    Text(
                                                      "TR",
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                  ],
                                                )
                                              : controller.isPhoneSelected
                                                  ? Row(
                                                      children: [
                                                        Text(
                                                          "(+90) ",
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 15,
                                                            fontFamily:
                                                                "MontserratMedium",
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                      ],
                                                    )
                                                  : SizedBox.shrink(),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: controller.iban,
                                            inputFormatters:
                                                controller.isIbanSelected
                                                ? [
                                                    LengthLimitingTextInputFormatter(
                                                        16),
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ]
                                                : controller.isPhoneSelected
                                                    ? [
                                                        LengthLimitingTextInputFormatter(
                                                            10),
                                                        FilteringTextInputFormatter
                                                            .digitsOnly,
                                                      ]
                                                    : controller.isEmailSelected
                                                        ? [
                                                            LengthLimitingTextInputFormatter(
                                                                50),
                                                          ]
                                                        : [],
                                            keyboardType:
                                                controller.isIbanSelected ||
                                                        controller
                                                            .isPhoneSelected
                                                ? TextInputType.number
                                                : TextInputType.emailAddress,
                                            decoration: InputDecoration(
                                              hintText: controller
                                                  .localizedFastType(
                                                    controller.kolayAdres.value,
                                                  ),
                                              hintStyle: TextStyle(
                                                color: Colors.grey,
                                                fontFamily: "MontserratMedium",
                                              ),
                                              border: InputBorder.none,
                                            ),
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontFamily: "MontserratMedium",
                                            ),
                                            onChanged: (val) =>
                                                controller.iban.text = val,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: controller.pasteFromClipboard,
                                          child: Icon(
                                            CupertinoIcons.doc_on_doc,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(15),
                            child: GestureDetector(
                              onTap: controller.saveData,
                              child: Container(
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Color(controller.color.value),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
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
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
