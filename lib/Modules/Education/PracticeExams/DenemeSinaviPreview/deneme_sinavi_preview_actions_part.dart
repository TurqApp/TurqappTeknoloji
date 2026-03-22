part of 'deneme_sinavi_preview.dart';

extension DenemeSinaviPreviewActionsPart on _DenemeSinaviPreviewState {
  Future<void> _handlePrimaryAction(
    DenemeSinaviPreviewController controller,
  ) async {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      await controller.addBasvuru();
      return;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      AppSnackbar(
        'practice.application_closed_title'.tr,
        'practice.application_closed_body'.tr,
      );
      return;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < controller.model.bitis) {
      if (controller.sinavaGirebilir.value) {
        if (controller.dahaOnceBasvurdu.value) {
          Get.to(
            () => DenemeSinaviYap(
              model: controller.model,
              sinaviBitir: controller.sinaviBitirAlert,
              showGecersizAlert: controller.showGecersizAlert,
              uyariAtla: false,
            ),
          );
        } else {
          AppSnackbar(
            'practice.not_applied_title'.tr,
            'practice.not_applied_body'.tr,
          );
        }
      } else {
        AppSnackbar(
          'practice.not_allowed_title'.tr,
          'practice.not_allowed_body'.tr,
        );
      }
      return;
    }
    if (controller.model.public) {
      Get.to(
        () => DenemeSinaviYap(
          model: controller.model,
          sinaviBitir: controller.sinaviBitirAlert,
          showGecersizAlert: controller.showGecersizAlert,
          uyariAtla: true,
        ),
      );
      return;
    }
    AppSnackbar(
      'practice.finished_title'.tr,
      'practice.finished_body'.tr,
    );
  }

  Color _ctaColor(DenemeSinaviPreviewController controller) {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      return Colors.teal;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      return Colors.purple;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < controller.model.bitis) {
      return Colors.black;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value > controller.model.bitis &&
        controller.model.public == false) {
      return Colors.red;
    }
    return Colors.indigo;
  }

  String _ctaLabel(DenemeSinaviPreviewController controller) {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      return controller.dahaOnceBasvurdu.value
          ? 'practice.applied_short'.tr
          : 'practice.apply_now'.tr;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      final minutes =
          ((controller.examTime.value - controller.currentTime.value) /
                  (60 * 1000))
              .floor();
      return 'practice.closed_starts_in'
          .trParams({'minutes': minutes.toString()});
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < controller.model.bitis) {
      return 'practice.started'.tr;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value > controller.model.bitis &&
        controller.model.public == false) {
      return 'practice.finished_short'.tr;
    }
    return 'practice.start_now'.tr;
  }

  Widget _pullDownMenu(DenemeSinaviPreviewController controller) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () {
            Get.to(
              () => ReportUser(
                userID: controller.model.userID,
                postID: controller.model.docID,
                commentID: '',
              ),
            );
          },
          title: 'practice.report_exam'.tr,
          icon: CupertinoIcons.exclamationmark_circle,
        ),
      ],
      buttonBuilder: (context, showMenu) => AppHeaderActionButton(
        onTap: showMenu,
        child: const Icon(
          AppIcons.ellipsisVertical,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }
}
