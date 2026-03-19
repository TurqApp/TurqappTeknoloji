part of 'create_scholarship_view.dart';

extension CreateScholarshipMediaPart on CreateScholarshipView {
  Widget buildGorsel(
    BuildContext context,
    CreateScholarshipController controller,
  ) {
    final containerDecoration = BoxDecoration(
      color: Colors.grey.withAlpha(20),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: GestureDetector(
            onTap: () => controller.currentSection.value = 3,
            child: Row(
              children: [
                Icon(CupertinoIcons.arrow_left, color: Colors.black),
                SizedBox(width: 12),
                Text(
                  'scholarship.extra_info'.tr,
                  style: TextStyles.headerTextStyle,
                ),
              ],
            ),
          ),
        ),
        Text(
          "scholarship.visual_info".tr,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        16.ph,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "scholarship.logo_label".tr,
                    style: TextStyles.textFieldTitle,
                  ),
                  4.ph,
                  GestureDetector(
                    onTap: () async {
                      final pickedFile =
                          await AppImagePickerService.pickSingleImage(context);
                      if (pickedFile != null) {
                        // Copy the picked file to a persistent location
                        final tempDir = await getTemporaryDirectory();
                        final newPath =
                            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                        final newFile = await pickedFile.copy(newPath);

                        if (!await newFile.exists()) {
                          AppSnackbar(
                            'common.error'.tr,
                            'scholarship.file_copy_failed'.tr,
                          );
                          return;
                        }

                        final r =
                            await OptimizedNSFWService.checkImage(newFile);
                        if (r.isNSFW) {
                          controller.logoPath.value = '';
                          controller.logo.value = '';
                          AppSnackbar("edit_profile.upload_failed_title".tr,
                              "edit_profile.upload_failed_body".tr,
                              backgroundColor:
                                  Colors.red.withValues(alpha: 0.7));
                        } else {
                          controller.logoPath.value = newFile.path;
                          controller.logo.value = newFile.path;
                        }
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        decoration: containerDecoration,
                        child: Obx(
                          () => controller.logo.value.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("scholarship.logo_pick".tr),
                                    SizedBox(height: 8),
                                    Icon(
                                      CupertinoIcons.photo_on_rectangle,
                                      size: 28,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      child: controller.logo.value
                                              .startsWith('http')
                                          ? CachedNetworkImage(
                                              imageUrl: controller.logo.value,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorWidget: (
                                                context,
                                                url,
                                                error,
                                              ) =>
                                                  const Icon(Icons.error),
                                            )
                                          : Image.file(
                                              File(controller.logo.value),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          controller.logoPath.value = '';
                                          controller.logo.value = '';
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.6),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
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
                ],
              ),
            ),
            8.pw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "scholarship.custom_design_optional".tr,
                    style: TextStyles.textFieldTitle,
                  ),
                  4.ph,
                  GestureDetector(
                    onTap: () async {
                      final pickedFile =
                          await AppImagePickerService.pickSingleImage(context);
                      if (pickedFile != null) {
                        // Copy the picked file to a persistent location
                        final tempDir = await getTemporaryDirectory();
                        final newPath =
                            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                        final newFile = await pickedFile.copy(newPath);

                        if (!await newFile.exists()) {
                          AppSnackbar(
                            'common.error'.tr,
                            'scholarship.file_copy_failed'.tr,
                          );
                          return;
                        }

                        final r =
                            await OptimizedNSFWService.checkImage(newFile);
                        if (r.isNSFW) {
                          controller.customImagePath.value = '';
                          AppSnackbar("edit_profile.upload_failed_title".tr,
                              "edit_profile.upload_failed_body".tr,
                              backgroundColor:
                                  Colors.red.withValues(alpha: 0.7));
                        } else {
                          controller.customImagePath.value = newFile.path;
                        }
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        width: double.infinity,
                        decoration: containerDecoration,
                        child: Obx(
                          () => controller.customImagePath.value.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("scholarship.custom_image_pick".tr),
                                    SizedBox(height: 8),
                                    Icon(
                                      CupertinoIcons.photo,
                                      size: 28,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      child: controller.customImagePath.value
                                              .startsWith('http')
                                          ? CachedNetworkImage(
                                              imageUrl: controller
                                                  .customImagePath.value,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorWidget: (
                                                context,
                                                url,
                                                error,
                                              ) =>
                                                  const Icon(Icons.error),
                                            )
                                          : Image.file(
                                              File(controller
                                                  .customImagePath.value),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          controller.customImagePath.value = '';
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.6),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
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
                ],
              ),
            ),
          ],
        ),
        16.ph,
        Text("scholarship.template_select".tr,
            style: TextStyles.textFieldTitle),
        4.ph,
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 4 / 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: List.generate(12, (index) {
            return GestureDetector(
              onTap: () {
                controller.selectedTemplateIndex.value = index;
              },
              child: Obx(
                () => Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: controller.selectedTemplateIndex.value == index
                          ? Colors.yellow
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/bursSablonlar/${index + 1}.webp',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        preview(context, controller),
      ],
    );
  }

  Widget preview(BuildContext context, CreateScholarshipController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              controller.currentSection.value = 3;
            },
            child: Container(
              height: 40,
              width: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('common.back'.tr, style: TextStyles.medium15Black),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (controller.logo.value.isEmpty ||
                  controller.selectedTemplateIndex.value == -1) {
                AppSnackbar(
                  'common.error'.tr,
                  'common.fill_all_fields'.tr,
                  backgroundColor: Colors.red.withValues(alpha: 0.7),
                );
                return;
              }
              controller.goToPreview();
            },
            child: Container(
              height: 40,
              width: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('scholarship.preview_title'.tr,
                  style: TextStyles.medium15white),
            ),
          ),
        ],
      ),
    );
  }
}
