import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'sinav_hazirla_content_part.dart';
part 'sinav_hazirla_sections_part.dart';
part 'sinav_hazirla_cover_part.dart';
part 'sinav_hazirla_types_part.dart';
part 'sinav_hazirla_setup_part.dart';

const _sinavHazirlaKpssType = 'KPSS';

class SinavHazirla extends StatefulWidget {
  final SinavModel? sinavModel;

  const SinavHazirla({super.key, this.sinavModel});

  @override
  State<SinavHazirla> createState() => _SinavHazirlaState();
}

class _SinavHazirlaState extends State<SinavHazirla> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final SinavHazirlaController controller;

  SinavModel? get sinavModel => widget.sinavModel;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'practice_exam_prepare_${widget.sinavModel?.docID ?? 'new'}_${identityHashCode(this)}';
    final existing = SinavHazirlaController.maybeFind(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ??
        SinavHazirlaController.ensure(
          tag: _controllerTag,
          sinavModel: sinavModel,
        );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          SinavHazirlaController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<SinavHazirlaController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildSinavHazirlaPage(context);

  Widget _buildSinavHazirlaPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(text: 'tests.create_title'.tr),
                Expanded(child: _buildSinavHazirlaForm(context)),
              ],
            ),
            _buildSavingOverlay(),
            _buildCalendarOverlay(),
            _buildDurationOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Obx(
      () => controller.isSaving.value
          ? Container(
              color: Colors.black.withValues(alpha: 0.5),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(
                    radius: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'tests.creating'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildCalendarOverlay() {
    return Obx(
      () => controller.showCalendar.value
          ? Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () => controller.showCalendar.value = false,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: controller.startDate.value,
                      onDateTimeChanged: (DateTime newDate) {
                        controller.startDate.value = newDate;
                      },
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDurationOverlay(BuildContext context) {
    return Obx(
      () => controller.showSureler.value
          ? Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GestureDetector(
                  onTap: () => controller.showSureler.value = false,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(24),
                      topLeft: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 15,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'tests.duration_select'.tr,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ],
                        ),
                        15.ph,
                        Expanded(
                          child: ListView.builder(
                            itemCount: sinavSureleri2.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: GestureDetector(
                                  onTap: () {
                                    controller.sure.value =
                                        sinavSureleri2[index];
                                    controller.showSureler.value = false;
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Obx(
                                        () => Text(
                                          sinavSureleri2[index].toString(),
                                          style: TextStyle(
                                            color: controller.sure.value ==
                                                    sinavSureleri2[index]
                                                ? Colors.indigo
                                                : Colors.black,
                                            fontSize: 20,
                                            fontFamily: controller.sure.value ==
                                                    sinavSureleri2[index]
                                                ? "MontserratBold"
                                                : "MontserratMedium",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
