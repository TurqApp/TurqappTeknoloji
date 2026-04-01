part of 'edit_post_controller.dart';

void _handleEditPostControllerInit(EditPostController controller) {
  controller.text.text = controller.model.metin;
  controller.yorum.value = controller.model.yorum;
  controller.adres.value = controller.model.konum;
  controller.text.addListener(() {
    controller.model.metin = controller.text.text;
  });

  if (controller.model.video.isNotEmpty) {
    controller.waitingVideo.value = true;
    final netCtrl = HLSVideoAdapter(
      url: controller.model.playbackUrl,
      autoPlay: false,
      loop: true,
    );
    netCtrl.setLooping(true);
    netCtrl.addListener(() {
      controller.isPlaying.value = netCtrl.value.isPlaying;
    });
    controller.rxVideoController.value = netCtrl;
    controller.videoUrl.value = controller.model.playbackUrl;
    controller.thumbnail.value = controller.model.thumbnail;
    controller.waitingVideo.value = false;
  }

  controller.imageUrls.assignAll(controller.model.img);
}

void _handleEditPostControllerClose(EditPostController controller) {
  controller.rxVideoController.value?.dispose();
  controller.text.dispose();
}
