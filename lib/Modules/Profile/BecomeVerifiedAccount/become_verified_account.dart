import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/verified_account_data_list.dart';
import 'package:turqappv2/Modules/Profile/BecomeVerifiedAccount/become_verified_account_controller.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turqappv2/Core/extension.dart';

class BecomeVerifiedAccount extends StatelessWidget {
  BecomeVerifiedAccount({super.key});
  final controller = Get.put(BecomeVerifiedAccountController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (controller.bodySelection.value != 0) {
                      controller.bodySelection--;
                    } else {
                      Get.back();
                    }
                  },
                  icon: const Icon(
                    CupertinoIcons.arrow_left,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(() {
                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                    child: Column(
                      children: [
                        if (controller.bodySelection.value == 0)
                          build1()
                        else if (controller.bodySelection.value == 1)
                          build2()
                        else if (controller.bodySelection.value == 2)
                          build3()
                        else if (controller.bodySelection.value == 3)
                          build4()
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget build1() {
    return Obx(() => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: HexColor.hex(controller.selectedColor.value),
                        size: 45,
                      ),
                      Text(
                        "settings.become_verified".tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "become_verified.intro".tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                      const SizedBox(height: 25),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: verifiedAccountData.length,
                        itemBuilder: (context, index) {
                          final item = verifiedAccountData[index];
                          final isSelected =
                              controller.selected.value?.title == item.title;
                          final localizedDesc = _localizedBadgeDesc(item.title);
                          final detailLines = localizedDesc
                              .split('\n')
                              .map((line) => line.trim())
                              .where((line) => line.isNotEmpty)
                              .toList(growable: false);
                          final secondaryDetail =
                              detailLines.length > 1 ? detailLines[1] : '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: TextButton(
                              onPressed: () {
                                controller.selectItem(item, index);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.transparent,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected
                                          ? HexColor.hex(
                                              controller.selectedColor.value)
                                          : Colors.grey.withAlpha(80)),
                                ),
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _localizedBadgeTitle(item.title),
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratBold",
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: Colors.grey),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(2),
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.indigo,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (isSelected)
                                      if (secondaryDetail.isNotEmpty)
                                        Text(
                                          secondaryDetail,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "Montserrat",
                                          ),
                                        ),
                                    if (isSelected &&
                                        _requiresAnnualRenewal(
                                            controller.selectedInt.value))
                                      Text(
                                        "become_verified.annual_renewal".tr,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratBold",
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "become_verified.footer".tr,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "Montserrat",
                          ),
                        ),
                      ),
                      TurqAppButton(
                        text: "common.continue".tr,
                        onTap: () {
                          controller.bodySelection.value++;
                        },
                      ),
                      const SizedBox(height: 12)
                    ],
                  ),
                ),
              ],
            )
          ],
        ));
  }

  Widget build2() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: HexColor.hex(controller.selectedColor.value),
              size: 50,
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              _localizedBadgeTitle(
                verifiedAccountData[controller.selectedInt.value].title,
              ),
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold"),
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              _localizedBadgeDesc(
                verifiedAccountData[controller.selectedInt.value].title,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            )
          ],
        ),
        SizedBox(
          height: 30,
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              color: Colors.white,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "become_verified.feature_ads".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Text(
                        "become_verified.feature_limited_ads".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "Montserrat"),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "become_verified.feature_post_boost".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Text(
                        "become_verified.feature_highest".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "Montserrat"),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_video_download".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_long_video".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_statistics".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_username".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_verification_mark".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_account_protection".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_channel_creation".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_priority_support".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_scheduled_video".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_unlimited_listings".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_unlimited_links".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_assistant".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "become_verified.feature_scheduled_content".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "become_verified.feature_character_limit".tr,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold"),
                    ),
                    Text(
                      "become_verified.feature_character_limit_value".tr,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "Montserrat"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "become_verified.loss_title".tr,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold"),
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              "become_verified.loss_body".tr,
              style: TextStyle(
                  color: Colors.black, fontSize: 15, fontFamily: "Montserrat"),
            ),
          ],
        ),
        SizedBox(
          height: 20,
        ),
        TurqAppButton(onTap: () {
          controller.bodySelection.value++;
        }, text: "common.continue".tr),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Widget build3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "become_verified.step_social_accounts".tr,
          style: TextStyle(fontSize: 18, fontFamily: "MontserratBold"),
        ),
        const SizedBox(height: 12),
        ..._buildSocialField(controller.instagram, "Instagram",
            "assets/icons/instagramx.webp", controller.setInstagramDefault),
        ..._buildSocialField(controller.twitter, "Twitter",
            "assets/icons/twitterx.webp", controller.setTwitterDefault),
        ..._buildSocialField(controller.tiktok, "TikTok",
            "assets/icons/tiktokx.webp", controller.setTiktokDefault),
        const SizedBox(height: 25),
        Text("become_verified.step_requested_username".tr,
            style: const TextStyle(fontSize: 18, fontFamily: "MontserratBold")),
        const SizedBox(height: 12),
        _buildCustomInput(controller.nickname, "become_verified.requested_username_hint".tr,
            controller.setNicknameDefault),
        const SizedBox(height: 25),
        Text("become_verified.step_social_confirmation".tr,
            style: const TextStyle(fontSize: 18, fontFamily: "MontserratBold")),
        const SizedBox(height: 12),
        Text(
          "become_verified.social_confirmation_body".tr,
          style: TextStyle(fontSize: 15, fontFamily: "Montserrat"),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () => launchUrl(Uri.parse("https://x.com/turqapp")),
              child: Image.asset(
                "assets/icons/twitterx.webp",
                height: 40,
              ),
            ),
            GestureDetector(
              onTap: () =>
                  launchUrl(Uri.parse("https://instagram.com/turqapp")),
              child: Image.asset(
                "assets/icons/instagram.webp",
                height: 40,
              ),
            ),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse("https://tiktok.com/@turqapp")),
              child: Image.asset(
                "assets/icons/tiktokx.webp",
                height: 40,
              ),
            ),
            GestureDetector(
              onTap: () =>
                  launchUrl(Uri.parse("https://linkedin.com/in/turqapp")),
              child: Image.asset(
                "assets/icons/linkedin.webp",
                height: 40,
              ),
            ),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse("https://facebook.com/turqapp")),
              child: Image.asset(
                "assets/icons/facebook.webp",
                height: 40,
              ),
            ),
          ],
        ),
        15.ph,
        Obx(
          () => GestureDetector(
            onTap: () => controller
                .toggleConsent(!controller.hasAcceptedConsent.value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: controller.hasAcceptedConsent.value,
                  onChanged: controller.toggleConsent,
                  activeColor: Colors.black,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      "become_verified.consent".tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "MontserratMedium",
                        color: Colors.black,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (controller.selectedInt.value == 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Text("become_verified.step_barcode".tr,
                  style: const TextStyle(fontSize: 18, fontFamily: "MontserratBold")),
              const SizedBox(height: 12),
              _buildCustomInput(
                  controller.eDevletBarcodeNo, "become_verified.barcode_hint".tr),
            ],
          ),
        if (controller.canSubmitApplication.value)
          GestureDetector(
            onTap: () async {
              final ok = await controller.submitApplication();
              if (ok) {
                controller.bodySelection++;
              }
            },
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(top: 25),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "become_verified.submit".tr,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: "MontserratBold",
                  fontSize: 15,
                ),
              ),
            ),
          )
      ],
    );
  }

  Widget build4() {
    return SizedBox(
      height: Get.height * 0.72,
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
            border: Border.all(color: const Color(0x12000000)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F6F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: Colors.black,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "become_verified.received_title".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontFamily: "MontserratBold",
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "become_verified.received_body".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "become_verified.received_note".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: "Montserrat",
                ),
              ),
              const SizedBox(height: 18),
              TurqAppButton(
                text: "common.ok".tr,
                onTap: () {
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSocialField(TextEditingController ctrl, String hint,
      String? iconPath, VoidCallback onTap,
      {IconData? icon}) {
    return [
      Row(
        children: [
          iconPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(iconPath, width: 45, height: 45))
              : Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  alignment: Alignment.center,
                  child: Icon(icon ?? Icons.link, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: ctrl,
                  onTap: onTap,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(
                        color: Colors.grey, fontFamily: "Montserrat"),
                  ),
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "Montserrat"),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
    ];
  }

  Widget _buildCustomInput(TextEditingController ctrl, String hint,
      [VoidCallback? onTap, String? iconAsset]) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
              color: Colors.black, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: iconAsset != null
              ? Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(iconAsset),
                )
              : const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: ctrl,
                onTap: onTap,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                      color: Colors.grey, fontFamily: "Montserrat"),
                ),
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "Montserrat"),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _badgeTitleKey(String title) => _resolveBadgeKey(
        title: title,
        titleSuffix: '',
      );

  String _badgeDescKey(String title) => _resolveBadgeKey(
        title: title,
        titleSuffix: '_desc',
      );

  String _resolveBadgeKey({
    required String title,
    required String titleSuffix,
  }) {
    final normalized = title.trim();
    final normalizedRozet = normalizeRozetValue(normalized);
    final baseKey = switch (normalizedRozet) {
      'mavi' => 'become_verified.badge_blue',
      'kirmizi' => 'become_verified.badge_red',
      'sari' => 'become_verified.badge_yellow',
      'turkuaz' => 'become_verified.badge_turquoise',
      'gri' => 'become_verified.badge_gray',
      'siyah' => 'become_verified.badge_black',
      _ => '',
    };
    if (baseKey.isNotEmpty) {
      return '$baseKey$titleSuffix';
    }

    for (final baseKey in const <String>[
      'become_verified.badge_blue',
      'become_verified.badge_red',
      'become_verified.badge_yellow',
      'become_verified.badge_turquoise',
      'become_verified.badge_gray',
      'become_verified.badge_black',
    ]) {
      final key = '$baseKey$titleSuffix';
      if (normalized == baseKey || normalized == key) {
        return key;
      }
    }
    return title;
  }

  String _localizedBadgeTitle(String title) => _badgeTitleKey(title).tr;

  String _localizedBadgeDesc(String title) => _badgeDescKey(title).tr;

  bool _requiresAnnualRenewal(int selectedIndex) =>
      selectedIndex != 3 && selectedIndex != 4;
}
