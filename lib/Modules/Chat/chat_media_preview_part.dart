part of 'chat.dart';

extension ChatMediaPreviewPart on ChatView {
  Widget buildImagePreview() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppBackButton(
                    onTap: controller.clearPendingMedia,
                    icon: CupertinoIcons.arrow_left,
                  ),
                ],
              ),
              Text(
                controller.pendingVideo.value != null
                    ? 'chat.video'.tr
                    : 'common.photos'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        Obx(() {
          final pendingVideo = controller.pendingVideo.value;
          if (pendingVideo != null) {
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PendingVideoPreview(file: pendingVideo),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              onPageChanged: (v) {
                controller.currentPage.value = v;
              },
              itemCount: controller.images.length,
              itemBuilder: (context, index) {
                return Image.file(controller.images[index]);
              },
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: SizedBox(
            height: 50,
            child: Obx(() {
              if (controller.pendingVideo.value != null) {
                return const SizedBox.shrink();
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.images.length,
                itemBuilder: (context, index) {
                  return Obx(
                    () => GestureDetector(
                      onTap: () {
                        controller.pageController.animateToPage(
                          index,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                        controller.currentPage.value = index;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: 4,
                          left: index == 0 ? 15 : 0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            border: Border.all(
                              color: controller.currentPage.value == index
                                  ? Colors.blueAccent
                                  : Colors.transparent,
                              width: 4,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            child: SizedBox(
                              width: 45,
                              height: 45,
                              child: Image.file(
                                controller.images[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
        buildInputRow(),
      ],
    );
  }
}
