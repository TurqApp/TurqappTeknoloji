import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Models/social_media_model.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_branding.dart';

import 'social_media_links_controller.dart';

class AddSocialMediaBottomSheet extends StatelessWidget {
  final controller = Get.put(SocialMediaController());

  AddSocialMediaBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'social_links.add_title'.tr,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),

          // Sosyal medya ikonları yatay scroll
          SizedBox(
            height: 54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.sosyal.length,
              itemBuilder: (context, index) {
                final item = controller.sosyal[index];
                return Obx(
                  () => GestureDetector(
                    onTap: () {
                      controller.selected.value = item;
                      controller.textController.text =
                          socialMediaDisplayTitleForKey(item);
                      controller.urlController.text = item == kSocialMediaWhatsApp
                          ? "https://wa.me/+90"
                          : item != kSocialMediaTurqApp
                              ? "https://${normalizeLowercase(item)}.com/"
                              : "";
                    },
                    child: Container(
                      margin:
                          EdgeInsets.only(right: 10, left: index == 0 ? 15 : 0),
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: controller.selected.value == item
                              ? Colors.blueAccent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset("assets/icons/${item}_s.webp"),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    children: [
                      Obx(() {
                        return GestureDetector(
                          onTap: () {
                            controller.pickImage(context);
                          },
                          child: controller.selected.value != ""
                              ? GestureDetector(
                                  onTap: () {
                                    controller.selected.value = "";
                                    controller.imageFile.value = null;
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color:
                                            Colors.grey.withValues(alpha: 0.4),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(50),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(50),
                                      ),
                                      child: SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: controller.selected.value != ""
                                            ? Image.asset(
                                                "assets/icons/${controller.selected.value}_s.webp",
                                                fit: BoxFit.cover,
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.add,
                                                  color: Colors.black,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () {
                                    controller.pickImage(context);
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(50),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 70,
                                          height: 70,
                                          child: Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(50),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              size: 30,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        if (controller.imageFile.value != null)
                                          SizedBox(
                                            width: 70,
                                            height: 70,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(75),
                                              ),
                                              child: Image.file(
                                                controller.imageFile.value!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                        );
                      }),
                      SizedBox(height: 4),
                      Text(
                        socialMediaDisplayTitleForKey(
                            controller.selected.value),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 40,
                          child: TextField(
                            controller: controller.textController,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(20),
                            ],
                            decoration: InputDecoration(
                              hintText: 'social_links.label_title'.tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratBold",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),

                        // inside your Column where the URL TextField lives:

                        Obx(() {
                          final isTurq =
                              controller.selected.value == kSocialMediaTurqApp;
                          return SizedBox(
                            height: 40,
                            child: TextField(
                              controller: controller.urlController,
                              keyboardType: isTurq
                                  ? TextInputType.text
                                  : TextInputType.url,
                              decoration: InputDecoration(
                                hintText: isTurq
                                    ? 'social_links.username_hint'.tr
                                    : "https://",
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
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          Obx(() {
            return controller.enableSave.value
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TurqAppButton(
                          onTap: () async {
                            controller.isUploading.value = true;

                            try {
                              final docID = DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString();
                              String logoValue = "";
                              if (controller.selected.value.isNotEmpty) {
                                logoValue = socialMediaEmbeddedLogoAsset(
                                  controller.selected.value,
                                );
                              } else if (controller.imageFile.value != null) {
                                logoValue = await controller.uploadFileImage(
                                  controller.imageFile.value!,
                                  docID,
                                );
                              }

                              await controller.saveLink(
                                SocialMediaModel(
                                  docID: docID,
                                  title: controller.textController.text.trim(),
                                  url: controller.urlController.text.trim(),
                                  sira: controller.list.length + 1,
                                  logo: logoValue,
                                ),
                              );

                              await controller.getData();
                              controller.resetFields();
                              Get.back();
                            } catch (e) {
                              final msg = normalizeLowercase(
                                        e.toString(),
                                      ).contains('permission-denied')
                                  ? 'social_links.save_permission_error'.tr
                                  : 'social_links.save_failed'.tr;
                              AppSnackbar('common.error'.tr, msg);
                            } finally {
                              controller.isUploading.value = false;
                            }
                          },
                        ),
                        if (controller.isUploading.value)
                          Positioned.fill(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                  )
                : SizedBox.shrink();
          }),

          SizedBox(height: 15),
        ],
      ),
    );
  }
}
