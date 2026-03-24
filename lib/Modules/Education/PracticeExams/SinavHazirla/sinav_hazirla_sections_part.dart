part of 'sinav_hazirla.dart';

extension SinavHazirlaSectionsPart on _SinavHazirlaState {
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
}
