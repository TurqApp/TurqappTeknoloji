part of 'sinav_sonuclari_preview_controller.dart';

extension SinavSonuclariPreviewControllerActionsPart
    on SinavSonuclariPreviewController {
  void _toggleCategoryImpl(String ders) {
    expandedCategories[ders] = !expandedCategories[ders]!;
  }
}
