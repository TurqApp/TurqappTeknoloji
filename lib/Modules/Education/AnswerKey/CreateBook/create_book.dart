import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateBook/create_book_controller.dart';

class CevapAnahtariHazirlikModel {
  String baslik;
  List<String> dogruCevaplar;
  int sira;

  CevapAnahtariHazirlikModel({
    required this.baslik,
    required this.dogruCevaplar,
    required this.sira,
  });
}

class CreateBook extends StatelessWidget {
  final Function? onBack;
  final BookletModel? existingBook;

  const CreateBook({required this.onBack, this.existingBook, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      CreateBookController(onBack, existingBook: existingBook),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(text: "Kitap Oluştur"),
                Obx(
                  () => controller.selection.value == 0
                      ? _build1(context, controller)
                      : _build2(context, controller),
                ),
                Obx(
                  () => controller.isFormValid()
                      ? GestureDetector(
                          onTap: () => controller.selection.value == 0
                              ? controller.nextStep()
                              : controller.setData(context),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 15,
                              right: 15,
                              bottom: 20,
                            ),
                            child: Container(
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                controller.selection.value == 0
                                    ? "Devam Et"
                                    : controller.isEditMode
                                        ? "Güncelle"
                                        : "Yayınla!",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            Obx(
              () => controller.showIndicator.value
                  ? Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 20),
                          Text(
                            "Yükleniyor Lütfen Bekle..",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontFamily: "MontserratBold",
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
    );
  }

  Widget _build1(BuildContext context, CreateBookController controller) {
    return Expanded(
      child: Container(
        color: Colors.white,
        child: ListView(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                Obx(
                  () => controller.imageFile.value != null
                      ? GestureDetector(
                          onTap: () async {
                            final pickedFile =
                                await AppImagePickerService.pickSingleImage(
                              context,
                            );
                            if (pickedFile != null) {
                              final file = pickedFile;
                              final r =
                                  await OptimizedNSFWService.checkImage(file);
                              if (r.isNSFW) {
                                controller.imageFile.value = null;
                                AppSnackbar("Yükleme Başarısız!",
                                    "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
                                    backgroundColor:
                                        Colors.red.withValues(alpha: 0.7));
                              } else {
                                controller.imageFile.value = file;
                              }
                            }
                          },
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            child: SizedBox(
                              width: 170,
                              height: 220,
                              child: Image.file(
                                controller.imageFile.value!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () async {
                            final pickedFile =
                                await AppImagePickerService.pickSingleImage(
                              context,
                            );
                            if (pickedFile != null) {
                              final file = pickedFile;
                              final r =
                                  await OptimizedNSFWService.checkImage(file);
                              if (r.isNSFW) {
                                controller.imageFile.value = null;
                                AppSnackbar("Yükleme Başarısız!",
                                    "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
                                    backgroundColor:
                                        Colors.red.withValues(alpha: 0.7));
                              } else {
                                controller.imageFile.value = file;
                              }
                            }
                          },
                          child: Container(
                            height: 220,
                            width: 170,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(18),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_outlined,
                                  color: Colors.black,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  "Kapak Fotoğrafı\nSeç",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 85,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: dersler1.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: 25,
                          left: index == 0 ? 20 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              controller.selectSinavTuru(dersler1[index]),
                          child: Obx(
                            () => Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: tumderslerColors[index],
                                    border: Border.all(
                                      color: controller.sinavTuru.value ==
                                              dersler1[index]
                                          ? Colors.black
                                          : Colors.white.withValues(
                                              alpha: 0.000001,
                                            ),
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    dersler1icons[index],
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dersler1[index],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontFamily: controller.sinavTuru.value ==
                                            dersler1[index]
                                        ? "MontserratBold"
                                        : "MontserratMedium",
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
                const SizedBox(height: 15),
                Container(
                  height: 50,
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: controller.baslikController,
                      decoration: const InputDecoration(
                        hintText: "Başlık (Ör: Türkçe Soru Bankası)",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: "MontserratMedium",
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 50,
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: controller.yayinEviController,
                      decoration: const InputDecoration(
                        hintText: "Yayın Evi",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: "MontserratMedium",
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 50,
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: controller.basimTarihiController,
                      decoration: const InputDecoration(
                        hintText: "Basım Yılı",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: "MontserratMedium",
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratMedium",
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(4),
                        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*$')),
                        FilteringTextInputFormatter.deny(RegExp(r'^[^2].*')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _build2(BuildContext context, CreateBookController controller) {
    return Expanded(
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Obx(
          () => ListView.builder(
            itemCount: controller.list.length + 1,
            itemBuilder: (context, index) {
              if (index == controller.list.length) {
                return Column(
                  children: [
                    if (controller.list.isNotEmpty)
                      GestureDetector(
                        onTap: () => controller.removeLastItem(),
                        child: Container(
                          color: Colors.red.withValues(alpha: 0.1),
                          alignment: Alignment.center,
                          height: 50,
                          child: const Text(
                            "Sil",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () => controller.addItem(),
                      child: Container(
                        color: Colors.green.withValues(alpha: 0.1),
                        alignment: Alignment.center,
                        height: 50,
                        child: const Text(
                          "Ekle",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final item = controller.list[index];
              return GestureDetector(
                onTap: () => controller.navigateToCevapAnahtari(context, item),
                child: Container(
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.baslik,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "${item.dogruCevaplar.length} Soru Hazırlandı",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.indigo,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CreateBookAnswerKey extends StatelessWidget {
  final CevapAnahtariHazirlikModel model;
  final Function onBack;

  const CreateBookAnswerKey({
    required this.model,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateBookAnswerKeyController(model, onBack));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 70,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.black),
                          SizedBox(width: 12),
                          Text(
                            "Cevap Anahtarı Ekle",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 50,
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: controller.baslikController,
                              decoration: const InputDecoration(
                                hintText: "Başlık (Ör: Türkçe Soru Bankası)",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: "MontserratMedium",
                                ),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 50,
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: controller.inputController,
                          decoration: const InputDecoration(
                            hintText: "Cevap Anahtar Listesi",
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: "MontserratMedium",
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.kaydetCevaplar,
                      child: Obx(
                        () => controller.inputController.text.isNotEmpty
                            ? Container(
                                height: 50,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.indigo,
                                ),
                                child: const Text(
                                  "Önizle",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Obx(
                      () => ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.cevaplar.length,
                        itemBuilder: (context, index) {
                          return Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? Colors.pink.withValues(alpha: 0.1)
                                  : Colors.pink.withValues(alpha: 0.2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${index + 1}.",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                  for (var item in ["A", "B", "C", "D", "E"])
                                    Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            item == controller.cevaplar[index]
                                                ? Colors.green
                                                : Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          color:
                                              item == controller.cevaplar[index]
                                                  ? Colors.white
                                                  : Colors.black,
                                          fontSize: 20,
                                          fontFamily: "MontserratBold",
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
            Obx(
              () => controller.baslikController.text.isNotEmpty &&
                      controller.onIzlendi.value
                  ? GestureDetector(
                      onTap: () => controller.saveAndBack(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(
                              Radius.circular(50),
                            ),
                          ),
                          child: const Text(
                            "Tamam",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
