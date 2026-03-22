import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv.dart';

import 'finding_job_apply_controller.dart';

class FindingJobApply extends StatefulWidget {
  const FindingJobApply({super.key});

  @override
  State<FindingJobApply> createState() => _FindingJobApplyState();
}

class _FindingJobApplyState extends State<FindingJobApply> {
  late final String _controllerTag;
  late final FindingJobApplyController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'finding_job_apply_${identityHashCode(this)}';
    _ownsController =
        FindingJobApplyController.maybeFind(tag: _controllerTag) == null;
    controller = FindingJobApplyController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          FindingJobApplyController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<FindingJobApplyController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Row(
                    children: [
                      BackButtons(text: "pasaj.job_finder.finding_platform".tr)
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "pasaj.job_finder.finding_how".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: "MontserratMedium"),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Text(
                        "pasaj.job_finder.finding_body".tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: "Montserrat"),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Obx(() {
                        return controller.cvVar.value
                            ? GestureDetector(
                                onTap: () {
                                  controller.toggleFindingJob();
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                      border: Border.all(
                                          color: Colors.grey.shade300)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "pasaj.job_finder.looking_for_job"
                                                .tr,
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium"),
                                          ),
                                        ),
                                        TurqAppToggle(
                                            isOn: controller.isFinding.value)
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  Get.to(() => Cv());
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                      border: Border.all(
                                          color: Colors.grey.shade300)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "pasaj.job_finder.create_cv".tr,
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium"),
                                          ),
                                        ),
                                        Icon(
                                          CupertinoIcons.chevron_right,
                                          size: 20,
                                          color: Colors.blueAccent,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                      })
                    ],
                  ),
                )
              ],
            ),
            Opacity(
              opacity: 0.5,
              child: Transform.translate(
                  offset: Offset(40, 10),
                  child: Image.asset(
                    "assets/images/cv.webp",
                    height: Get.height / 4,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
