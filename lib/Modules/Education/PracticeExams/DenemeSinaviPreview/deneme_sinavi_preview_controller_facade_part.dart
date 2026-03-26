part of 'deneme_sinavi_preview_controller.dart';

DenemeSinaviPreviewController _ensureDenemeSinaviPreviewController({
  required String tag,
  required SinavModel model,
  bool permanent = false,
}) {
  final existing = _maybeFindDenemeSinaviPreviewController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    DenemeSinaviPreviewController(model: model),
    tag: tag,
    permanent: permanent,
  );
}

DenemeSinaviPreviewController? _maybeFindDenemeSinaviPreviewController({
  required String tag,
}) {
  final isRegistered =
      Get.isRegistered<DenemeSinaviPreviewController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<DenemeSinaviPreviewController>(tag: tag);
}

String _currentPracticeExamPreviewUserId() =>
    CurrentUserService.instance.effectiveUserId;

void _handleDenemeSinaviPreviewInit(
  DenemeSinaviPreviewController controller,
) {
  controller.examTime.value = controller.model.timeStamp.toInt();
  controller.fetchUserData();
  controller.basvuruKontrol();
  controller.getGecersizlikDurumu();
  controller.syncSavedState();
}

Future<void> _fetchDenemePreviewUserData(
  DenemeSinaviPreviewController controller,
) =>
    DenemeSinaviPreviewControllerRuntimePart(controller).fetchUserData();

Future<void> _getDenemePreviewInvalidState(
  DenemeSinaviPreviewController controller,
) =>
    DenemeSinaviPreviewControllerRuntimePart(controller).getGecersizlikDurumu();

Future<void> _checkDenemePreviewApplication(
  DenemeSinaviPreviewController controller,
) =>
    DenemeSinaviPreviewControllerRuntimePart(controller).basvuruKontrol();

Future<void> _refreshDenemePreviewData(
  DenemeSinaviPreviewController controller,
) =>
    DenemeSinaviPreviewControllerRuntimePart(controller).refreshData();

Future<void> _syncDenemePreviewSavedState(
  DenemeSinaviPreviewController controller,
) =>
    DenemeSinaviPreviewControllerRuntimePart(controller).syncSavedState();
