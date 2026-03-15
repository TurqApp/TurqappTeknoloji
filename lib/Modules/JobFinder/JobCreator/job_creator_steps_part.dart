part of 'job_creator.dart';

extension JobCreatorStepsPart on JobCreator {
  Widget step1() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Obx(() {
                  final preview = controller.croppedImage.value;

                  if (preview != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      child: SizedBox(
                        width: (Get.width * 0.31).clamp(96.0, 120.0),
                        height: (Get.width * 0.31).clamp(96.0, 120.0),
                        child: Image.memory(
                          preview,
                          fit: BoxFit.cover,
                          key: ValueKey("preview"), // force rebuild
                        ),
                      ),
                    );
                  } else if (controller.existingJob?.logo != null &&
                      controller.existingJob!.logo.isNotEmpty) {
                    return ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      child: SizedBox(
                        width: (Get.width * 0.31).clamp(96.0, 120.0),
                        height: (Get.width * 0.31).clamp(96.0, 120.0),
                        child: CachedNetworkImage(
                          imageUrl: controller.existingJob!.logo,
                          fit: BoxFit.cover,
                          key: ValueKey("existingLogo"), // force rebuild
                        ),
                      ),
                    );
                  } else {
                    return ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      child: SizedBox(
                        width: (Get.width * 0.31).clamp(96.0, 120.0),
                        height: (Get.width * 0.31).clamp(96.0, 120.0),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(50),
                          ),
                          child: Icon(
                            CupertinoIcons.building_2_fill,
                            color: Colors.grey,
                            size: 45,
                          ),
                        ),
                      ),
                    );
                  }
                }),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    children: [
                      // Galeriden Seç
                      GestureDetector(
                        onTap: () async {
                          final ctx = Get.context;
                          if (ctx == null) return;
                          final pickedFile =
                              await AppImagePickerService.pickSingleImage(
                            ctx,
                          );
                          if (pickedFile != null) {
                            final file = pickedFile;
                            final r =
                                await OptimizedNSFWService.checkImage(file);
                            if (r.isNSFW) {
                              controller.croppedImage.value = null;
                              AppSnackbar(
                                "Yükleme Başarısız!",
                                "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
                                backgroundColor:
                                    Colors.red.withValues(alpha: 0.7),
                              );
                            } else {
                              controller.croppedImage.value =
                                  file.readAsBytesSync();
                            }
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: Text(
                              "Galeriden Seç",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 12,
                      ),

                      // Kameradan Çek
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 85,
                          );
                          if (pickedFile != null) {
                            final file = File(pickedFile.path);
                            final r =
                                await OptimizedNSFWService.checkImage(file);
                            if (r.isNSFW) {
                              controller.croppedImage.value = null;
                              AppSnackbar(
                                "Yükleme Başarısız!",
                                "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
                                backgroundColor:
                                    Colors.red.withValues(alpha: 0.7),
                              );
                            } else {
                              controller.croppedImage.value =
                                  file.readAsBytesSync();
                            }
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(50),
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: Text(
                              "Kameradan Çek",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            15.ph,
            Container(
              constraints: BoxConstraints(
                minHeight: 50,
                maxHeight: 100,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: TextField(
                controller: controller.brand,
                maxLines: null, // Otomatik satır artışı
                keyboardType: TextInputType.text,
                textInputAction:
                    TextInputAction.done, // Enter ile yeni satır engellenir
                onSubmitted: (_) {}, // Enter'a tepki verme
                inputFormatters: [
                  LengthLimitingTextInputFormatter(150),
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-zÇçĞğİıÖöŞşÜü0-9\s]')),
                ],
                decoration: InputDecoration(
                  hintText: "Firma Adı",
                  hintStyle: TextStyle(
                    color: Colors.black,
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
            ),
            15.ph,
            Container(
              height: (Get.height * 0.2).clamp(120.0, 150.0),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: TextField(
                controller: controller.about,
                maxLines: null,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {},
                inputFormatters: [
                  LengthLimitingTextInputFormatter(150),
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-zÇçĞğİıÖöŞşÜü0-9\s]')),
                ],
                decoration: InputDecoration(
                  hintText: "Firmanız hakkında kısa bilgi",
                  hintStyle: TextStyle(
                    color: Colors.black,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget step2() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                // Şehir Seç
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      controller.showSehirSelect();
                    },
                    child: Obx(() => Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            child: Text(
                              controller.sehir.value == ""
                                  ? "Şehir Seç"
                                  : controller.sehir.value,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        )),
                  ),
                ),

                15.pw,

                // İlçe Seç
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      controller.showIlceSelect();
                    },
                    child: Obx(() => Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            child: Text(
                              controller.ilce.value == ""
                                  ? "İlçe Seç"
                                  : controller.ilce.value,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        )),
                  ),
                )
              ],
            ),

            15.ph,

            // Konum Butonu
            Obx(() => TextButton(
                  onPressed: () {
                    controller.getKonumVeAdres();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.lat.value != 0
                            ? CupertinoIcons.location_fill
                            : CupertinoIcons.location,
                        color: Colors.pinkAccent,
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          controller.adres.value != ""
                              ? controller.adres.value
                              : "Şu andaki konumu kullan",
                          style: TextStyle(
                            color: Colors.pinkAccent,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      )
                    ],
                  ),
                )),

            15.ph,

            // Harita
            Expanded(
              child: Obx(() {
                if (controller.lat.value != 0) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        child: SizedBox(
                          width: double.infinity,
                          child: AbsorbPointer(
                            child: GoogleMap(
                              onMapCreated: controller.onMapCreated,
                              initialCameraPosition: CameraPosition(
                                target: LatLng(controller.lat.value.toDouble(),
                                    controller.long.value.toDouble()),
                                zoom: 15,
                              ),
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              scrollGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                              mapToolbarEnabled: false,
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.location_solid,
                        color: Colors.red,
                        size: 45,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.to(() => LocationFinderView(
                                    submitButtonTitle: 'Burayı Seç',
                                    backAdres: (val) {
                                      controller.adres.value = val;
                                    },
                                    backLatLong: (latlong) async {
                                      controller.lat.value = latlong.latitude;
                                      controller.long.value = latlong.longitude;

                                      // 🔁 Şehir ve ilçe bilgisini al
                                      try {
                                        List<Placemark> placemarks =
                                            await placemarkFromCoordinates(
                                          latlong.latitude,
                                          latlong.longitude,
                                        );

                                        if (placemarks.isNotEmpty) {
                                          final place = placemarks.first;
                                          final sehir =
                                              place.administrativeArea ?? "";
                                          String ilce =
                                              place.subAdministrativeArea ?? "";

                                          // İlçe içinde il adı geçiyorsa çıkar
                                          if (ilce
                                              .toLowerCase()
                                              .contains(sehir.toLowerCase())) {
                                            ilce = ilce
                                                .replaceAll(sehir, "")
                                                .trim();

                                            // Sadece "Merkez" kalsın
                                            if (ilce.isEmpty) {
                                              ilce = "Merkez";
                                            }
                                          }

                                          controller.sehir.value = sehir;
                                          controller.ilce.value = ilce;
                                        }
                                      } catch (_) {}
                                    },
                                  ));
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50)),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  child: Text(
                                    "Haritadan Belirle",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  );
                } else {
                  return SizedBox.shrink();
                }
              }),
            ),

            SizedBox(
              height: 15,
            ),

            Obx(() {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${controller.lat.value.toStringAsFixed(6)}, ${controller.long.value.toStringAsFixed(6)}",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  )
                ],
              );
            }),

            SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget step3(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: ListView(
          children: [
            Column(
              children: [
                // İlan Başlığı
                Container(
                  constraints: BoxConstraints(
                    minHeight: 50,
                    maxHeight: 100,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: TextField(
                    controller: controller.ilanBasligi,
                    maxLines: null,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(100),
                    ],
                    decoration: InputDecoration(
                      hintText: "İlan Başlığı (ör. Kıdemli Yazılımcı)",
                      hintStyle: TextStyle(
                        color: Colors.black,
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
                ),
                15.ph,
                GestureDetector(
                  onTap: () {
                    controller.selectCalismaTuru();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Çalışma Türü",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium"),
                              ),
                              Icon(
                                CupertinoIcons.chevron_down,
                                color: Colors.black,
                                size: 20,
                              )
                            ],
                          ),
                          if (controller.selectedCalismaTuruList.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                controller.selectedCalismaTuruList.join(", "),
                                style: TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium"),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
                15.ph,
                GestureDetector(
                  onTap: () {
                    controller.showMeslekSelector();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Meslek",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium"),
                              ),
                              Icon(
                                CupertinoIcons.chevron_down,
                                color: Colors.black,
                                size: 20,
                              )
                            ],
                          ),
                          if (controller.meslek.value != "")
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                controller.meslek.value,
                                style: TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium"),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
                15.ph,
                Container(
                  height: (Get.height * 0.2).clamp(120.0, 150.0),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: TextField(
                    controller: controller.isTanimi,
                    maxLines: null, // İçerik satır sınırı yok ama alan sabit
                    keyboardType: TextInputType.multiline,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(2000),
                    ],
                    decoration: InputDecoration(
                      hintText: "İş Tanımı",
                      hintStyle: TextStyle(
                        color: Colors.black,
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
                ),
                15.ph,
                GestureDetector(
                  onTap: () {
                    controller.selectYanHaklar(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Yan Haklar",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium"),
                              ),
                              Icon(
                                CupertinoIcons.chevron_down,
                                color: Colors.black,
                                size: 20,
                              )
                            ],
                          ),
                          if (controller.selectedYanHaklar.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                controller.selectedYanHaklar.join(", "),
                                style: TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium"),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
                15.ph,
                // Deneyim Seviyesi
                GestureDetector(
                  onTap: () {
                    controller.selectDeneyimSeviyesi();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Deneyim Seviyesi",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium"),
                              ),
                              Icon(
                                CupertinoIcons.chevron_down,
                                color: Colors.black,
                                size: 20,
                              )
                            ],
                          ),
                          if (controller.deneyimSeviyesi.value != "")
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                controller.deneyimSeviyesi.value,
                                style: TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium"),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
                15.ph,
                // Pozisyon Sayısı
                Container(
                  constraints: BoxConstraints(
                    minHeight: 50,
                    maxHeight: 100,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: TextField(
                    controller: controller.pozisyonSayisi,
                    maxLines: 1,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(3),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: "Pozisyon Sayısı",
                      hintStyle: TextStyle(
                        color: Colors.black,
                        fontFamily: "MontserratMedium",
                      ),
                      border: InputBorder.none,
                      suffixText: "kişi",
                      suffixStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
                15.ph,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Maaş Aralığı",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium"),
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    Obx(() => Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.black),
                            color: controller.maasOpen.value
                                ? Colors.black
                                : Colors.transparent,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.all(3), // max 3px tıklama alanı
                            constraints:
                                BoxConstraints(), // tıklama alanını sınırla
                            iconSize: 20,
                            onPressed: () {
                              controller.maasOpen.value =
                                  !controller.maasOpen.value;
                            },
                            icon: Icon(
                              CupertinoIcons.checkmark,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ))
                  ],
                ),
                15.ph,
                if (controller.maasOpen.value)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          constraints: BoxConstraints(
                            minHeight: 50,
                            maxHeight: 100,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: TextField(
                            controller: controller.maas1,
                            maxLines: null, // Otomatik satır artışı
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction
                                .done, // Enter ile yeni satır engellenir
                            onSubmitted: (_) {}, // Enter'a tepki verme
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(150),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: "Ör. 18500",
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
                        ),
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Text(
                        "-",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Container(
                          constraints: BoxConstraints(
                            minHeight: 50,
                            maxHeight: 100,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: TextField(
                            controller: controller.maas2,
                            maxLines: null, // Otomatik satır artışı
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {},
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(150),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: "Ör. 23400",
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
                        ),
                      )
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
