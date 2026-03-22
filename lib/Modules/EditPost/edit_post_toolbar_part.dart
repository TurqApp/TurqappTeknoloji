part of 'edit_post.dart';

extension _EditPostToolbarPart on _EditPostState {
  Widget toolbar() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (controller.videoUrl.value == "")
                      PullDownButton(
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            onTap: () {
                              controller.pickImageCamera(
                                source: ImageSource.camera,
                              );
                            },
                            title: 'profile_photo.camera'.tr,
                            icon: CupertinoIcons.camera,
                          ),
                          PullDownMenuItem(
                            onTap: controller.pickImageGallery,
                            title: 'profile_photo.gallery'.tr,
                            icon: CupertinoIcons.photo,
                          ),
                        ],
                        buttonBuilder: (context, showMenu) => CupertinoButton(
                          onPressed: showMenu,
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.photo_on_rectangle,
                            color: Colors.black,
                            size: 25,
                          ),
                        ),
                      ),
                    if (controller.videoUrl.value == "" &&
                        controller.rxVideoController.value == null)
                      PullDownButton(
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            onTap: () {
                              controller.pickVideo(source: ImageSource.camera);
                            },
                            title: 'profile_photo.camera'.tr,
                            icon: CupertinoIcons.camera,
                          ),
                          PullDownMenuItem(
                            onTap: () {
                              controller.pickVideo(source: ImageSource.gallery);
                            },
                            title: 'profile_photo.gallery'.tr,
                            icon: CupertinoIcons.photo,
                          ),
                        ],
                        buttonBuilder: (context, showMenu) => CupertinoButton(
                          onPressed: showMenu,
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.play_circle,
                            color: Colors.black,
                            size: 25,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: controller.goToLocationMap,
                      icon: const Icon(
                        CupertinoIcons.map_pin_ellipse,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: controller.showCommentOptions,
                      icon: const Icon(
                        CupertinoIcons.ellipses_bubble,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
