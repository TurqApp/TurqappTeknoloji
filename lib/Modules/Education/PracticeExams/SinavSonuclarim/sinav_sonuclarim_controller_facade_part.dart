part of 'sinav_sonuclarim_controller.dart';

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
