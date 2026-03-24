part of 'sinav_hazirla.dart';

extension SinavHazirlaContentPart on _SinavHazirlaState {
  Widget _buildSinavHazirlaForm(BuildContext context) {
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: controller.resetForm,
      child: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoverSection(context),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.grey.shade300),
              ),
              _buildDetailsSection(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.grey.shade300),
              ),
              _buildTypesSection(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.grey.shade300),
              ),
              _buildQuestionCountsSection(context),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.grey.shade300),
              ),
              _buildDateDurationSection(context),
              _buildContinueButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCountsSection(BuildContext context) {
    final soruSayisiFieldWidth =
        (MediaQuery.of(context).size.width * 0.26).clamp(82.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'tests.question_counts'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => controller.currentDersler.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Text(
                    'tests.questions_data_failed'.tr,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : _buildSoruSayisiFields(soruSayisiFieldWidth),
        ),
      ],
    );
  }

  Widget _buildSoruSayisiFields(double width) {
    return Column(
      children: List.generate(
        controller.currentDersler.length,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.currentDersler[i],
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: Obx(
                      () => TextField(
                        controller: controller.soruSayisiTextFields[i],
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(3),
                          MaxValueTextInputFormatter(180),
                        ],
                        decoration: InputDecoration(
                          hintText: 'tests.question_count'.tr,
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontFamily: "MontserratMedium",
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                          height: 1.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateDurationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'tests.date_duration'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        10.ph,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: GestureDetector(
            onTap: () =>
                controller.showCalendar.value = !controller.showCalendar.value,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'tests.date'.tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy')
                            .format(controller.startDate.value),
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        10.ph,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: GestureDetector(
            onTap: () => controller.selectTime(context),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'tests.time'.tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                      Text(
                        controller.selectedTime.value.format(context),
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: GestureDetector(
            onTap: () =>
                controller.showSureler.value = !controller.showSureler.value,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'tests.duration'.tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                      Text(
                        "${controller.sure.value} dk",
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Obx(
      () => (controller.sinavIsmi.value.text.isNotEmpty &&
              controller.aciklama.value.text.isNotEmpty &&
              (controller.cover.value != null ||
                  (sinavModel != null && sinavModel!.cover.isNotEmpty)))
          ? Padding(
              padding: const EdgeInsets.all(15),
              child: GestureDetector(
                onTap: controller.isSaving.value
                    ? null
                    : () => controller.setData(context),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        controller.isSaving.value ? Colors.grey : Colors.indigo,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'common.continue'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        Icon(
                          controller.isSaving.value
                              ? Icons.hourglass_empty
                              : Icons.arrow_right_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
