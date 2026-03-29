part of 'post_creator.dart';

extension PostCreatorShellContentPart on PostCreator {
  Widget _buildPageContent(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenPostCreator),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context),
                  _buildPostBody(),
                  _buildToolbar(),
                ],
              ),
              Positioned.fill(
                child: UploadProgressWidget(controller: progressController),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compact = constraints.maxWidth <= 360 || textScale > 1.2;
        final publishButton = Padding(
          padding: const EdgeInsets.only(right: 5),
          child: InkWell(
            key: const ValueKey(
              IntegrationTestKeys.actionPostCreatorPublish,
            ),
            onTap: controller.isPublishing.value
                ? null
                : () async {
                    if (controller.isSavingEdit.value) return;
                    if (controller.isEditMode.value) {
                      final ok = await controller.savePostEdit();
                      if (ok) {
                        final popped =
                            await Navigator.of(context).maybePop();
                        if (!popped) {
                          if (Navigator.of(context, rootNavigator: true)
                              .canPop()) {
                            Navigator.of(context, rootNavigator: true).pop();
                          } else {
                            Get.back();
                          }
                        }
                      }
                      return;
                    }
                    controller.uploadAllPostsInBackgroundWithErrorHandling();
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                controller.isEditMode.value
                    ? (controller.isSavingEdit.value
                        ? 'post_creator.saving'.tr
                        : 'common.save'.tr)
                    : (controller.isPublishing.value
                        ? 'post_creator.uploading'.tr
                        : 'post_creator.publish'.tr),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
        );
        final title = Text(
          controller.isEditMode.value
              ? 'post_creator.title_edit'.tr
              : 'post_creator.title_new'.tr,
          textAlign: compact ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: "MontserratBold",
          ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBackButton(
                          onTap: () => Get.back(),
                          icon: Icons.arrow_back,
                        ),
                        const SizedBox(width: 12),
                        Flexible(child: publishButton),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: title,
                    ),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppBackButton(
                          onTap: () => Get.back(),
                          icon: Icons.arrow_back,
                        ),
                        publishButton,
                      ],
                    ),
                    title,
                  ],
                ),
        );
      },
    );
  }
}
