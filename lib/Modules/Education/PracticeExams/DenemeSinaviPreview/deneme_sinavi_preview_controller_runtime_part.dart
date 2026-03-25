part of 'deneme_sinavi_preview_controller.dart';

class DenemeSinaviPreviewControllerRuntimePart {
  const DenemeSinaviPreviewControllerRuntimePart(this.controller);

  final DenemeSinaviPreviewController controller;

  Future<void> fetchUserData() async {
    try {
      final data = await controller._userSummaryResolver.resolve(
            controller.model.userID,
            preferCache: true,
          ) ??
          controller._userSummaryResolver.resolveFromMaps(
            controller.model.userID,
          );
      controller.displayName.value = data.preferredName;
      controller.nickname.value = data.nickname.trim();
      controller.avatarUrl.value = data.avatarUrl;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'practice.user_load_failed'.tr);
    } finally {
      controller.isLoading.value = false;
      controller.isInitialized.value = true;
    }
  }

  Future<void> getGecersizlikDurumu() async {
    try {
      final data = await controller._practiceExamRepository.fetchRawById(
        controller.model.docID,
        preferCache: true,
      );

      if (data == null || !data.containsKey('gecersizSayilanlar')) {
        controller.sinavaGirebilir.value = true;
        return;
      }

      final gecersizSayilanlar = List<String>.from(
        data['gecersizSayilanlar'] ?? [],
      );
      controller.sinavaGirebilir.value = !gecersizSayilanlar.contains(
        controller._currentUserId,
      );
    } catch (_) {
      AppSnackbar('common.error'.tr, 'practice.invalidity_load_failed'.tr);
      controller.sinavaGirebilir.value = true;
    }
  }

  Future<void> basvuruKontrol() async {
    try {
      controller.basvuranSayisi.value =
          await controller._practiceExamRepository.fetchParticipantCount(
        controller.model.docID,
        preferCache: true,
      );
      controller.dahaOnceBasvurdu.value =
          await controller._practiceExamRepository.hasApplication(
        controller.model.docID,
        controller._currentUserId,
      );
    } catch (_) {
      AppSnackbar('common.error'.tr, 'practice.application_check_failed'.tr);
    }
  }

  Future<void> refreshData() async {
    controller.currentTime.value = DateTime.now().millisecondsSinceEpoch;
    await controller.fetchUserData();
    await controller.basvuruKontrol();
    await controller.syncSavedState();
  }

  Future<void> syncSavedState() async {
    final savedController = SavedPracticeExamsController.ensure();
    if (savedController.savedExamIds.isEmpty &&
        !savedController.isLoading.value) {
      await savedController.loadSavedExams();
    }
    controller.isSaved.value = savedController.savedExamIds.contains(
      controller.model.docID,
    );
  }
}
