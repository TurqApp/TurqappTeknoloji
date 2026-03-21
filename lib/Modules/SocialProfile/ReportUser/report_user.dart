import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';

import '../../../Core/strings.dart';
import 'report_user_controller.dart';

class ReportUser extends StatefulWidget {
  final String userID;
  final String postID;
  final String commentID;
  const ReportUser(
      {super.key,
      required this.userID,
      required this.postID,
      required this.commentID});

  @override
  State<ReportUser> createState() => _ReportUserState();
}

class _ReportUserState extends State<ReportUser> {
  late final ReportUserController controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'report_user_${widget.userID}_${widget.postID}_${widget.commentID}_${identityHashCode(this)}';
    controller = Get.put(
      ReportUserController(
        userID: widget.userID,
        postID: widget.postID,
        commentID: widget.commentID,
      ),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<ReportUserController>(tag: _controllerTag) &&
        identical(
          Get.find<ReportUserController>(tag: _controllerTag),
          controller,
        )) {
      Get.delete<ReportUserController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(children: [
              if (controller.step.value == 0.50)
                BackButtons(text: 'common.report'.tr)
              else
                Row(
                  children: [
                    AppBackButton(
                      onTap: () {
                        controller.step.value = 0.5;
                      },
                      icon: CupertinoIcons.arrow_left,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppPageTitle(
                        'common.report'.tr,
                        fontSize: 25,
                      ),
                    ),
                  ],
                )
            ]),
            Obx(() {
              return LinearProgressIndicator(
                color: Colors.black,
                minHeight: 1,
                value: controller.step.value,
                backgroundColor: Colors.grey.withAlpha(20),
              );
            }),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(() {
                  return controller.step.value == 0.5 ? step1() : step2();
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Text(
                'report.reported_user'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 55,
                      height: 55,
                      child: controller.avatarUrl.value != ""
                          ? CachedNetworkImage(
                              imageUrl: controller.avatarUrl.value,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: CupertinoActivityIndicator(
                                  color: Colors.black)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.nickname.value,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          controller.fullName.value,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'report.what_issue'.tr,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        SizedBox(height: 12),
        const SizedBox(height: 15),
        for (var item in reportSelections)
          Padding(
            padding: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
            child: Material(
              color: Colors.transparent, // Ripple efektinin düzgün çıkması için
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  controller.selectedKey.value = item.key;
                  controller.selectedTitle.value = item.title;
                  controller.selectedDesc.value = item.description;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: controller.selectedTitle.value == item.title
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              if (controller.selectedTitle.value == item.title)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.description,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.selectedTitle.value == item.title
                                ? Colors.black
                                : Colors.white,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(15)),
                            border: Border.all(
                              color:
                                  controller.selectedTitle.value == item.title
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                          ),
                          child: controller.selectedTitle.value == item.title
                              ? const Icon(
                                  CupertinoIcons.checkmark,
                                  color: Colors.white,
                                  size: 12,
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 25),
          child: TurqAppButton(
            bgColor: Colors.black,
            onTap: () {
              if (controller.selectedKey.value.isEmpty) {
                return;
              }
              controller.step.value = 1.0;
            },
            text: 'common.continue'.tr,
          ),
        )
      ],
    );
  }

  Widget step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'report.thanks_title'.tr,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontFamily: "MontserratBold"),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'report.thanks_body'.tr,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                'report.how_it_works_title'.tr,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold"),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'report.how_it_works_body'.tr,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                'report.whats_next_title'.tr,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold"),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'report.whats_next_body'.tr,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                'report.optional_block_title'.tr,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold"),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'report.optional_block_body'.tr,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              const SizedBox(
                height: 15,
              ),
              if (!controller.blockedUser.value)
                GestureDetector(
                  onTap: () {
                    controller.block();
                  },
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.5))),
                    child: Text(
                      'report.block_user_button'.trParams({
                        'nickname': controller.nickname.value,
                      }),
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium"),
                    ),
                  ),
                )
              else
                Text(
                  'report.blocked_user_label'.trParams({
                    'nickname': controller.nickname.value,
                  }),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                    fontStyle: FontStyle.italic, // Metni italik yapar
                    decoration: TextDecoration.underline, // Altını çizer
                  ),
                ),
              const SizedBox(
                height: 15,
              ),
              Text(
                'report.block_user_info'.trParams({
                  'nickname': controller.nickname.value,
                }),
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              SizedBox(
                height: 12,
              ),
              Obx(() {
                return TurqAppButton(
                  onTap: () {
                    controller.report();
                  },
                  text: controller.isSubmitting.value
                      ? 'report.submitting'.tr
                      : 'report.done'.tr,
                );
              }),
              SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
