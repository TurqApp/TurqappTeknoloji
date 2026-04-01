part of 'url_post_maker_controller.dart';

extension UrlPostMakerControllerUiPart on UrlPostMakerController {
  Future<void> goToLocationMap() async {
    Get.to(
      () => LocationFinderView(
        submitButtonTitle: 'Bu adresi kullan',
        backAdres: (v) {
          adres.value = v;
        },
        backLatLong: (_) {},
      ),
    );
  }

  Future<void> showCommentOptions() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                  const SizedBox(width: 12),
                  Text(
                    'comments.title'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  yorum.value = true;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Herkes yorum yapabilir.',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: yorum.value
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  yorum.value = false;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'post.comments_disabled_none'.tr,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: !yorum.value
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }),
      ),
    );
  }
}
