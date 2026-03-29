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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBackButton(
                onTap: () => Get.back(),
                icon: Icons.arrow_back,
              ),
              Padding(
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
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                } else {
                                  Get.back();
                                }
                              }
                            }
                            return;
                          }
                          controller
                              .uploadAllPostsInBackgroundWithErrorHandling();
                        },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                      style: const TextStyle(
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
          Text(
            controller.isEditMode.value
                ? 'post_creator.title_edit'.tr
                : 'post_creator.title_new'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: "MontserratBold",
            ),
          ),
        ],
      ),
    );
  }
}
