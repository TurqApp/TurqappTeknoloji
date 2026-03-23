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

  Widget _buildCoverSection(BuildContext context) {
    final coverSelectButtonWidth =
        (MediaQuery.of(context).size.width * 0.52).clamp(160.0, 200.0);

    return Padding(
      padding: const EdgeInsets.all(15),
      child: GestureDetector(
        onTap: () => _pickCoverImage(context),
        child: Obx(
          () => Stack(
            alignment: Alignment.center,
            children: [
              if (controller.isLoadingImage.value)
                const Center(child: CupertinoActivityIndicator())
              else if (controller.cover.value != null)
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: Image.file(
                    controller.cover.value!,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width,
                  ),
                )
              else if (sinavModel?.cover.isNotEmpty ?? false)
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: sinavModel!.cover,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width,
                    errorWidget: (context, url, error) => Container(
                      alignment: Alignment.center,
                      height: MediaQuery.of(context).size.width - 60,
                      child: Text(
                        'tests.cover_load_failed'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  alignment: Alignment.center,
                  height: MediaQuery.of(context).size.width - 60,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Opacity(
                        opacity: 0.5,
                        child: Image.asset(
                          "assets/education/denemeGridPreview.webp",
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Container(
                          height: 35,
                          width: coverSelectButtonWidth,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.pink,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Text(
                            'tests.cover_select'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
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

  Future<void> _pickCoverImage(BuildContext context) async {
    final pickedFile = await AppImagePickerService.pickSingleImage(context);
    if (pickedFile == null) return;

    controller.isLoadingImage.value = true;
    final result = await OptimizedNSFWService.checkImage(pickedFile);
    controller.isLoadingImage.value = false;

    if (result.isNSFW) {
      controller.cover.value = null;
      AppSnackbar(
        "tests.create_upload_failed".tr,
        "tests.create_upload_failed".tr,
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      return;
    }

    controller.cover.value = pickedFile;
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'tests.details'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Obx(
                () => TextField(
                  controller: controller.sinavIsmi.value,
                  maxLines: 1,
                  keyboardType: TextInputType.text,
                  inputFormatters: [LengthLimitingTextInputFormatter(17)],
                  decoration: InputDecoration(
                    hintText: 'tests.name_hint'.tr,
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
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Obx(
                () => TextField(
                  controller: controller.aciklama.value,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  inputFormatters: [LengthLimitingTextInputFormatter(300)],
                  decoration: InputDecoration(
                    hintText: 'common.description'.tr,
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
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => controller.public.value = !controller.public.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'tests.post_exam_status'.trParams({
                          'status': controller.public.value
                              ? 'tests.status.open'.tr
                              : 'tests.status.closed'.tr,
                        }),
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: "MontserratBold",
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 25,
                        alignment: controller.public.value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                        ),
                        child: Container(
                          width: 25,
                          decoration: BoxDecoration(
                            color: controller.public.value
                                ? Colors.indigo
                                : Colors.grey,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(50),
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
        ),
      ],
    );
  }

  Widget _buildTypesSection() {
    final renkler = [
      Colors.black,
      Colors.green[500]!,
      Colors.purple[500]!,
      Colors.red[500]!,
      Colors.orange[500]!,
      Colors.teal[500]!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'tests.types'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sinavTurleriList.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () =>
                    controller.updateSinavTuru(sinavTurleriList[index]),
                child: Padding(
                  padding: EdgeInsets.only(
                    right: 12,
                    left: index == 0 ? 15 : 0,
                  ),
                  child: Obx(
                    () => Container(
                      height: 60,
                      width: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: controller.sinavTuru.value ==
                                sinavTurleriList[index]
                            ? renkler[index % renkler.length]
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(50),
                        ),
                      ),
                      child: Text(
                        sinavTurleriList[index],
                        style: TextStyle(
                          color: controller.sinavTuru.value ==
                                  sinavTurleriList[index]
                              ? Colors.white
                              : Colors.black,
                          fontSize: 15,
                          fontFamily: controller.sinavTuru.value ==
                                  sinavTurleriList[index]
                              ? "MontserratBold"
                              : "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Obx(
          () => controller.sinavTuru.value == _sinavHazirlaKpssType
              ? Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: kpssOgretimTipleri.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: GestureDetector(
                                onTap: () => controller.updateKpssLisans(
                                  kpssOgretimTipleri[index],
                                ),
                                child: Obx(
                                  () => Container(
                                    height: 45,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: controller
                                                  .kpssSecilenLisans.value ==
                                              kpssOgretimTipleri[index]
                                          ? Colors.indigo
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(50),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: Text(
                                        kpssOgretimTipleri[index],
                                        style: TextStyle(
                                          color: controller.kpssSecilenLisans
                                                      .value ==
                                                  kpssOgretimTipleri[index]
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
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
