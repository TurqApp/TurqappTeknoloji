part of 'sinav_hazirla.dart';

extension SinavHazirlaBodyPart on SinavHazirla {
  Widget buildContent(BuildContext context) {
    final controller = Get.put(SinavHazirlaController(sinavModel: sinavModel));
    final soruSayisiFieldWidth =
        (MediaQuery.of(context).size.width * 0.26).clamp(82.0, 100.0);
    final coverSelectButtonWidth =
        (MediaQuery.of(context).size.width * 0.52).clamp(160.0, 200.0);

    Widget buildSoruSayisiFields(List<String> dersler) {
      return Column(
        children: List.generate(
          dersler.length,
          (i) => Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dersler[i],
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    SizedBox(
                      width: soruSayisiFieldWidth,
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
                            hintText: "Soru Sayısı",
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(text: "Sınav Bilgileri"),
                Expanded(
                  child: RefreshIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                    onRefresh: controller.resetForm,
                    child: ListView(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(15),
                              child: GestureDetector(
                                onTap: () async {
                                  final pickedFile = await AppImagePickerService
                                      .pickSingleImage(context);
                                  if (pickedFile != null) {
                                    controller.isLoadingImage.value = true;
                                    final file = pickedFile;
                                    final r =
                                        await OptimizedNSFWService.checkImage(
                                            file);
                                    controller.isLoadingImage.value = false;
                                    if (r.isNSFW) {
                                      controller.cover.value = null;
                                      AppSnackbar(
                                        "Yükleme Başarısız!",
                                        "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
                                        backgroundColor:
                                            Colors.red.withValues(alpha: 0.7),
                                      );
                                    } else {
                                      controller.cover.value = file;
                                    }
                                  }
                                },
                                child: Obx(
                                  () => Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (controller.isLoadingImage.value)
                                        Center(
                                          child: CupertinoActivityIndicator(),
                                        )
                                      else if (controller.cover.value != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                          child: Image.file(
                                            controller.cover.value!,
                                            fit: BoxFit.cover,
                                            width: MediaQuery.of(
                                              context,
                                            ).size.width,
                                            height: MediaQuery.of(
                                              context,
                                            ).size.width,
                                          ),
                                        )
                                      else if (sinavModel?.cover.isNotEmpty ??
                                          false)
                                        ClipRRect(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: sinavModel!.cover,
                                            fit: BoxFit.cover,
                                            width: MediaQuery.of(
                                              context,
                                            ).size.width,
                                            height: MediaQuery.of(
                                              context,
                                            ).size.width,
                                            errorWidget: (
                                              context,
                                              url,
                                              error,
                                            ) =>
                                                Container(
                                              alignment: Alignment.center,
                                              height: MediaQuery.of(
                                                    context,
                                                  ).size.width -
                                                  60,
                                              child: Text(
                                                "Kapak fotoğrafı yüklenemedi. Lütfen tekrar deneyin.",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 15,
                                                  fontFamily:
                                                      "MontserratMedium",
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          alignment: Alignment.center,
                                          height: MediaQuery.of(
                                                context,
                                              ).size.width -
                                              60,
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
                                                padding: EdgeInsets.only(
                                                  bottom: 15,
                                                ),
                                                child: Container(
                                                  height: 35,
                                                  width: coverSelectButtonWidth,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: Colors.pink,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(20),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Kapak Fotoğrafı Seç",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          "MontserratBold",
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
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                "Sınav Detayları",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  child: Obx(
                                    () => TextField(
                                      controller: controller.sinavIsmi.value,
                                      maxLines: 1,
                                      keyboardType: TextInputType.text,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(17),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: "Sınav İsmi",
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
                                        height: 1.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  child: Obx(
                                    () => TextField(
                                      controller: controller.aciklama.value,
                                      maxLines: null,
                                      keyboardType: TextInputType.text,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(300),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: "Açıklama Metni",
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
                                        height: 1.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => controller.public.value =
                                  !controller.public.value,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  height: 45,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: Obx(
                                      () => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Sınav Sonrası ${controller.public.value ? "Açık" : "Kapalı"}",
                                            style: TextStyle(
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
                                              color: Colors.grey.withValues(
                                                alpha: 0.3,
                                              ),
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(50),
                                              ),
                                            ),
                                            child: Container(
                                              width: 25,
                                              decoration: BoxDecoration(
                                                color: controller.public.value
                                                    ? Colors.indigo
                                                    : Colors.grey,
                                                borderRadius: BorderRadius.all(
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
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                "Sınav Türleri",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: sinavTurleriList.length,
                                itemBuilder: (context, index) {
                                  List<Color> renkler = [
                                    Colors.black,
                                    Colors.green[500]!,
                                    Colors.purple[500]!,
                                    Colors.red[500]!,
                                    Colors.orange[500]!,
                                    Colors.teal[500]!,
                                  ];
                                  return GestureDetector(
                                    onTap: () => controller.updateSinavTuru(
                                      sinavTurleriList[index],
                                    ),
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
                                                ? renkler[
                                                    index % renkler.length]
                                                : Colors.grey.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(50),
                                            ),
                                          ),
                                          child: Text(
                                            sinavTurleriList[index],
                                            style: TextStyle(
                                              color: controller
                                                          .sinavTuru.value ==
                                                      sinavTurleriList[index]
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 15,
                                              fontFamily: controller
                                                          .sinavTuru.value ==
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
                              () => controller.sinavTuru.value == "KPSS"
                                  ? Column(
                                      children: [
                                        SizedBox(height: 10),
                                        Padding(
                                          padding: EdgeInsets.only(left: 15),
                                          child: SizedBox(
                                            height: 50,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  kpssOgretimTipleri.length,
                                              itemBuilder: (context, index) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    right: 20,
                                                  ),
                                                  child: GestureDetector(
                                                    onTap: () => controller
                                                        .updateKpssLisans(
                                                      kpssOgretimTipleri[index],
                                                    ),
                                                    child: Obx(
                                                      () => Container(
                                                        height: 45,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: controller
                                                                      .kpssSecilenLisans
                                                                      .value ==
                                                                  kpssOgretimTipleri[
                                                                      index]
                                                              ? Colors.indigo
                                                              : Colors.grey
                                                                  .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                          borderRadius:
                                                              BorderRadius.all(
                                                            Radius.circular(
                                                              50,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal: 15,
                                                          ),
                                                          child: Text(
                                                            kpssOgretimTipleri[
                                                                index],
                                                            style: TextStyle(
                                                              color: controller
                                                                          .kpssSecilenLisans
                                                                          .value ==
                                                                      kpssOgretimTipleri[
                                                                          index]
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                              fontSize: 15,
                                                              fontFamily:
                                                                  "MontserratMedium",
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
                                  : SizedBox.shrink(),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                "Soru Sayıları",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Obx(
                              () => controller.currentDersler.isEmpty
                                  ? Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        "Ders bilgileri yüklenemedi. Lütfen sınav türünü kontrol edin veya tekrar deneyin.",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : buildSoruSayisiFields(
                                      controller.currentDersler,
                                    ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                "Sınav Tarihi ve Süresi",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                            10.ph,
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: GestureDetector(
                                onTap: () => controller.showCalendar.value =
                                    !controller.showCalendar.value,
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: Obx(
                                      () => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Sınav Tarihi",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontFamily: 'MontserratBold',
                                            ),
                                          ),
                                          Text(
                                            DateFormat('dd.MM.yyyy').format(
                                              controller.startDate.value,
                                            ),
                                            style: TextStyle(
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
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: GestureDetector(
                                onTap: () => controller.selectTime(context),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: Obx(
                                      () => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Sınav Saati",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontFamily: 'MontserratBold',
                                            ),
                                          ),
                                          Text(
                                            controller.selectedTime.value
                                                .format(context),
                                            style: TextStyle(
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
                            SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: GestureDetector(
                                onTap: () => controller.showSureler.value =
                                    !controller.showSureler.value,
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: Obx(
                                      () => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Sınav Süresi",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontFamily: 'MontserratBold',
                                            ),
                                          ),
                                          Text(
                                            "${controller.sure.value} dk",
                                            style: TextStyle(
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
                            SizedBox(height: 10),
                            Obx(
                              () =>
                                  (controller.sinavIsmi.value.text.isNotEmpty &&
                                          controller
                                              .aciklama.value.text.isNotEmpty &&
                                          (controller.cover.value != null ||
                                              (sinavModel != null &&
                                                  sinavModel!
                                                      .cover.isNotEmpty)))
                                      ? Padding(
                                          padding: EdgeInsets.all(15),
                                          child: GestureDetector(
                                            onTap: controller.isSaving.value
                                                ? null
                                                : () => controller.setData(
                                                      context,
                                                    ),
                                            child: Container(
                                              height: 50,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: controller.isSaving.value
                                                    ? Colors.grey
                                                    : Colors.indigo,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Devam Et",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "MontserratBold",
                                                      ),
                                                    ),
                                                    Icon(
                                                      controller.isSaving.value
                                                          ? Icons
                                                              .hourglass_empty
                                                          : Icons
                                                              .arrow_right_alt,
                                                      color: Colors.white,
                                                      size: 30,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Obx(
              () => controller.isSaving.value
                  ? Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoActivityIndicator(
                            radius: 20,
                            color: Colors.white,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Sınav Oluşturuluyor...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
            ),
            Obx(
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
                          padding: EdgeInsets.all(15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
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
                  : SizedBox.shrink(),
            ),
            Obx(
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
                          decoration: BoxDecoration(
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
                            padding: EdgeInsets.only(
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
                                      "Sınav Süresi Seç",
                                      style: TextStyle(
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
                                        padding: EdgeInsets.only(bottom: 15),
                                        child: GestureDetector(
                                          onTap: () {
                                            controller.sure.value =
                                                sinavSureleri2[index];
                                            controller.showSureler.value =
                                                false;
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Obx(
                                                () => Text(
                                                  sinavSureleri2[index]
                                                      .toString(),
                                                  style: TextStyle(
                                                    color:
                                                        controller.sure.value ==
                                                                sinavSureleri2[
                                                                    index]
                                                            ? Colors.indigo
                                                            : Colors.black,
                                                    fontSize: 20,
                                                    fontFamily: controller
                                                                .sure.value ==
                                                            sinavSureleri2[
                                                                index]
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
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
