part of 'sinav_hazirla.dart';

extension SinavHazirlaShellPart on _SinavHazirlaState {
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
