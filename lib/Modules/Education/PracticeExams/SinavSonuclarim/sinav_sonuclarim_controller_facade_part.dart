part of 'sinav_sonuclarim_controller_library.dart';

SinavSonuclarimController ensureSinavSonuclarimController({
  bool permanent = false,
}) {
  final existing = maybeFindSinavSonuclarimController();
  if (existing != null) return existing;
  return Get.put(SinavSonuclarimController(), permanent: permanent);
}

SinavSonuclarimController? maybeFindSinavSonuclarimController() {
  final isRegistered = Get.isRegistered<SinavSonuclarimController>();
  if (!isRegistered) return null;
  return Get.find<SinavSonuclarimController>();
}

void _handleSinavSonuclarimControllerInit(
  SinavSonuclarimController controller,
) {
  controller.scrolControlcu();
  unawaited(_SinavSonuclarimControllerRuntimeX(controller).bootstrapData());
}

void _handleSinavSonuclarimControllerClose(
  SinavSonuclarimController controller,
) {
  controller.scrollController.dispose();
}

extension SinavSonuclarimControllerFacadePart on SinavSonuclarimController {
  void scrolControlcu() =>
      _SinavSonuclarimControllerRuntimeX(this).setupScrollController();

  Future<void> findAndGetSinavlar({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _SinavSonuclarimControllerRuntimeX(this).findAndGetSinavlar(
        silent: silent,
        forceRefresh: forceRefresh,
      );
}
