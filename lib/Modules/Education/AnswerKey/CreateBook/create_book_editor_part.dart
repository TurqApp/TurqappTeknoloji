part of 'create_book.dart';

extension _CreateBookEditorPart on _CreateBookState {
  Future<void> _pickCoverImage(BuildContext context) async {
    final pickedFile = await AppImagePickerService.pickSingleImage(context);
    if (pickedFile == null) return;

    final file = pickedFile;
    final result = await OptimizedNSFWService.checkImage(file);
    if (result.isNSFW) {
      controller.imageFile.value = null;
      AppSnackbar(
        "tests.create_upload_failed".tr,
        "tests.create_upload_failed".tr,
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      return;
    }

    controller.imageFile.value = file;
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
                          onTap: () => _pickCoverImage(context),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            child: SizedBox(
                              width: _coverWidth(context),
                              height: _coverHeight(context),
                              child: Image.file(
                                controller.imageFile.value!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () => _pickCoverImage(context),
                          child: Container(
                            height: _coverHeight(context),
                            width: _coverWidth(context),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(18),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.photo_outlined,
                                  color: Colors.black,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'answer_key.cover_select_short'.tr,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
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
                                  _answerKeyExamLabel(dersler1[index]),
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
                      decoration: InputDecoration(
                        hintText: "answer_key.book_title_hint".tr,
                        hintStyle: const TextStyle(
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
                      decoration: InputDecoration(
                        hintText: "answer_key.publisher_hint".tr,
                        hintStyle: const TextStyle(
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
                      decoration: InputDecoration(
                        hintText: "answer_key.publish_year_hint".tr,
                        hintStyle: const TextStyle(
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
                          child: Text(
                            "common.delete".tr,
                            style: const TextStyle(
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
                        child: Text(
                          "common.add".tr,
                          style: const TextStyle(
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
                                "answer_key.questions_prepared".trParams({
                                  "count": item.dogruCevaplar.length.toString(),
                                }),
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
