import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test_controller.dart';

class CreateTest extends StatelessWidget {
  final TestsModel? model;

  const CreateTest({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateTestController(model));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(
                  text: controller.model != null
                      ? "Testi Düzenle"
                      : "Test Oluştur",
                ),
                Expanded(
                  child: Obx(
                    () => controller.isLoading.value
                        ? const Center(
                            child: CupertinoActivityIndicator(
                              radius: 20,
                              color: Colors.black,
                            ),
                          )
                        : controller.appStore.isEmpty ||
                                controller.googlePlay.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.black,
                                      size: 40,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Veri bulunamadı.\nUygulama bağlantıları veya test soruları yüklenemedi.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "Montserrat",
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : testHazirla(context, controller),
                  ),
                ),
              ],
            ),
            Obx(
              () => controller.showBransh.value
                  ? Stack(
                      children: [
                        GestureDetector(
                          onTap: () => controller.showBransh.value = false,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.width,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(24),
                                  topLeft: Radius.circular(24),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Branş Seç",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: bransDersleri.length,
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () {
                                              controller.selectedDers.clear();
                                              controller.selectedDers.add(
                                                bransDersleri[index],
                                              );
                                              controller.showBransh.value =
                                                  false;
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 15,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      bransDersleri[index],
                                                      style: TextStyle(
                                                        color: controller
                                                                .selectedDers
                                                                .contains(
                                                          bransDersleri[index],
                                                        )
                                                            ? Colors.indigo
                                                            : Colors.black,
                                                        fontSize: 18,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 25,
                                                    height: 25,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                        Radius.circular(
                                                          40,
                                                        ),
                                                      ),
                                                      border: Border.all(
                                                        color: Colors.grey
                                                            .withValues(alpha: 0.5),
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        2.5,
                                                      ),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: controller
                                                                  .selectedDers
                                                                  .contains(
                                                            bransDersleri[
                                                                index],
                                                          )
                                                              ? Colors.indigo
                                                              : Colors.white,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .all(
                                                            Radius.circular(
                                                              40,
                                                            ),
                                                          ),
                                                        ),
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
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            Obx(
              () => controller.showDiller.value
                  ? Stack(
                      children: [
                        GestureDetector(
                          onTap: () => controller.showDiller.value = false,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.width,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(24),
                                  topLeft: Radius.circular(24),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Dil Seç",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: yabanciDiller.length,
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () {
                                              controller.selectedDil.value =
                                                  yabanciDiller[index];
                                              controller.showDiller.value =
                                                  false;
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 15,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      yabanciDiller[index],
                                                      style: TextStyle(
                                                        color: yabanciDiller[
                                                                    index] ==
                                                                controller
                                                                    .selectedDil
                                                                    .value
                                                            ? Colors.indigo
                                                            : Colors.black,
                                                        fontSize: 18,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 25,
                                                    height: 25,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                        Radius.circular(
                                                          40,
                                                        ),
                                                      ),
                                                      border: Border.all(
                                                        color: Colors.grey
                                                            .withValues(alpha: 0.5),
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        2.5,
                                                      ),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: yabanciDiller[
                                                                      index] ==
                                                                  controller
                                                                      .selectedDil
                                                                      .value
                                                              ? Colors.indigo
                                                              : Colors.white,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .all(
                                                            Radius.circular(
                                                              40,
                                                            ),
                                                          ),
                                                        ),
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
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget testHazirla(BuildContext context, CreateTestController controller) {
    return ListView(
      children: [
        Column(
          children: [
            GestureDetector(
              onTap: () async {
                final pickedFile =
                    await AppImagePickerService.pickSingleImage(context);
                if (pickedFile != null) {
                  final file = pickedFile;
                  final r = await OptimizedNSFWService.checkImage(file);
                  if (r.isNSFW) {
                    controller.imageFile.value = null;
                    AppSnackbar(
                      "Yükleme Başarısız!",
                      "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
                      backgroundColor: Colors.red.withValues(alpha: 0.7),
                    );
                  } else {
                    controller.imageFile.value = file;
                  }
                }
              },
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Obx(
                  () => controller.imageFile.value == null
                      ? controller.foundImage.value.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                              child: Image.network(
                                controller.foundImage.value,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              height: MediaQuery.of(context).size.width - 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Opacity(
                                      opacity: 0.5,
                                      child: Image.asset(
                                        "assets/education/testgridpreview.webp",
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final pickedFile =
                                            await AppImagePickerService
                                                .pickSingleImage(context);
                                        if (pickedFile != null) {
                                          final file = pickedFile;
                                          final r = await OptimizedNSFWService.checkImage(file);
                                          if (r.isNSFW) {
                                            controller.imageFile.value = null;
                                            AppSnackbar(
                                                "Yükleme Başarısız!",
                                                "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
                                                backgroundColor: Colors.red
                                                    .withValues(alpha: 0.7));
                                          } else {
                                            controller.imageFile.value = file;
                                          }
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.only(bottom: 20),
                                        child: SizedBox(
                                          height: 35,
                                          width: 200,
                                          child: Material(
                                            color: Colors.pink,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(20),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "Kapak Fotoğrafı Seç",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                      : ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                          child: Image.file(
                            controller.imageFile.value!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                alignment: Alignment.topLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: controller.aciklama,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.text,
                    inputFormatters: [LengthLimitingTextInputFormatter(35)],
                    decoration: const InputDecoration(
                      hintText: "9. Sınıf Üslü İfadeler Köklü İfadeler",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: "MontserratMedium",
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Obx(
                            () => Text(
                              "Herkese ${controller.paylasilabilir.value ? "Açık" : "Kapalı"}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.paylasilabilir.value =
                              !controller.paylasilabilir.value,
                          child: Obx(
                            () => Container(
                              width: 40,
                              height: 25,
                              alignment: controller.paylasilabilir.value
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.3),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              child: Container(
                                width: 25,
                                decoration: BoxDecoration(
                                  color: controller.paylasilabilir.value
                                      ? Colors.indigo
                                      : Colors.grey,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Text(
                        controller.paylasilabilir.value
                            ? "Dijital etik kurallarına uygun olarak, telifli testler paylaşılmamalıdır.\nLütfen herkesin çözebileceği, telif hakkı içermeyen testler kullanın ve yayınlayın."
                            : "Bu test yalnızca kendi öğrencilerinizle paylaşılabilir. Yayınladığınız teste, yalnızca size verilen ID değerini giren öğrenciler erişebilir ve çözebilir.",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                    Obx(
                      () => !controller.paylasilabilir.value
                          ? Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Test ID: ${controller.testID.value}",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: "${controller.testID.value}",
                                        ),
                                      );
                                      controller.kopyalandi.value = true;
                                    },
                                    child: Text(
                                      controller.kopyalandi.value
                                          ? "Kopyalandı"
                                          : "Kopyala",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.grey.withValues(alpha: 0.5)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: const [
                  Text(
                    "Test Türü",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 85,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: dersler.length,
                itemBuilder: (context, index) {
                  if (index >= dersRenkleri.length ||
                      index >= derslerIconsOutlined.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsets.only(
                      right: 7,
                      left: index == 0 ? 20 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        controller.testTuru.value = dersler[index];
                        controller.selectedDers.clear();
                      },
                      child: SizedBox(
                        width: 70,
                        child: Column(
                          children: [
                            Obx(
                              () => Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: dersRenkleri[index],
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(40),
                                  ),
                                  border: Border.all(
                                    color: controller.testTuru.value ==
                                            dersler[index]
                                        ? Colors.black
                                        : Colors.black.withValues(alpha: 0.0001),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  derslerIconsOutlined[index],
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Obx(
                              () => Text(
                                dersler[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: controller.testTuru.value ==
                                          dersler[index]
                                      ? Colors.pink
                                      : Colors.black,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Obx(
              () => controller.testTuru.value == "Ortaokul" ||
                      controller.testTuru.value == "Lise"
                  ? buildOrtaOkulLise(context, controller)
                  : controller.testTuru.value == "Hazırlık"
                      ? buildHazirlik(context, controller)
                      : controller.testTuru.value == "Dil"
                          ? buildDil(context, controller)
                          : controller.testTuru.value == "Branş"
                              ? buildBransh(context, controller)
                              : const SizedBox.shrink(),
            ),
            Obx(
              () => controller.showSilButon.value
                  ? Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: controller.deleteTest,
                              child: Container(
                                height: 45,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Testi Sil",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.saveTest(context),
                              child: Container(
                                height: 45,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Kaydet",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : (controller.selectedDers.isNotEmpty &&
                          controller.aciklama.text.isNotEmpty &&
                          !controller.showSilButon.value &&
                          (controller.imageFile.value != null ||
                              controller.model != null))
                      ? GestureDetector(
                          onTap: () => controller.prepareTest(context),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              height: 45,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.indigo,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Testi Hazırla",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildOrtaOkulLise(
    BuildContext context,
    CreateTestController controller,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: const [
              Text(
                "Dersler",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.getFilteredDersler().length,
            itemBuilder: (context, index) {
              String ders = controller.getFilteredDersler()[index];
              if (index >= tumderslerColors.length ||
                  index >= tumDerslerIconlar.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.only(right: 7, left: index == 0 ? 20 : 0),
                child: GestureDetector(
                  onTap: () {
                    if (controller.selectedDers.contains(ders)) {
                      controller.selectedDers.remove(ders);
                    } else {
                      controller.selectedDers.add(ders);
                    }
                  },
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      children: [
                        Obx(
                          () => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: dersRenkleri[index],
                              borderRadius: const BorderRadius.all(
                                Radius.circular(40),
                              ),
                              border: Border.all(
                                color: controller.selectedDers.contains(ders)
                                    ? Colors.black
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              controller.getIconForDers(ders),
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => Text(
                            ders,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: controller.selectedDers.contains(ders)
                                  ? Colors.pink
                                  : Colors.black,
                              fontFamily: controller.selectedDers.contains(ders)
                                  ? "MontserratBold"
                                  : "MontserratMedium",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildHazirlik(BuildContext context, CreateTestController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: const [
              Text(
                "Sınavlara Hazırlık",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sinavTurleriList.length,
            itemBuilder: (context, index) {
              final item = sinavTurleriList[index];
              return Padding(
                padding: EdgeInsets.only(right: 7, left: index == 0 ? 20 : 0),
                child: GestureDetector(
                  onTap: () {
                    controller.selectedDers.clear();
                    controller.selectedDers.add(item);
                  },
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      children: [
                        Obx(
                          () => Opacity(
                            opacity: 1.0,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: dersRenkleri[index],
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(40),
                                ),
                                border: Border.all(
                                  color: controller.selectedDers.contains(item)
                                      ? Colors.black
                                      : Colors.black.withValues(alpha: 0.0001),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                derslerIconsOutlined[index],
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => Text(
                            item,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: controller.selectedDers.contains(item)
                                  ? Colors.pink
                                  : Colors.black,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildDil(BuildContext context, CreateTestController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: const [
              Text(
                "Yabancı Dil",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (var item in hazirlikDersler.take(2))
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      controller.selectedDers.clear();
                      controller.selectedDers.add(item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Obx(
                        () => Container(
                          height: 39,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.selectedDers.contains(item)
                                ? Colors.black
                                : Colors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            border: Border.all(color: Colors.black, width: 0.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: controller.selectedDers.contains(item)
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
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (var item in hazirlikDersler.sublist(2, 4))
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      controller.selectedDers.clear();
                      controller.selectedDers.add(item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Obx(
                        () => Container(
                          height: 39,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.selectedDers.contains(item)
                                ? Colors.black
                                : Colors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            border: Border.all(color: Colors.black, width: 0.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: controller.selectedDers.contains(item)
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
                  ),
                ),
            ],
          ),
        ),
        Obx(
          () => controller.selectedDers.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: const [
                      Text(
                        "Dil Seç",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Obx(
          () => controller.selectedDers.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.showDiller.value = true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 45,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.selectedDil.value.isNotEmpty
                                  ? controller.selectedDil.value
                                  : "Dil Seç",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                            const Icon(Icons.arrow_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget buildBransh(BuildContext context, CreateTestController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: const [
              Text(
                "Branş",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => controller.showBransh.value = true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(
              () => Container(
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.selectedDers.isNotEmpty
                            ? controller.selectedDers.first
                            : "Branş Seç",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const Icon(Icons.arrow_right, color: Colors.grey),
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
}
