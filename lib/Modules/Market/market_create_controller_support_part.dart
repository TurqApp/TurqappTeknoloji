part of 'market_create_controller.dart';

extension MarketCreateControllerSupportPart on MarketCreateController {
  bool get isEditing => initialItem != null;

  int get totalImageCount => existingImageUrls.length + selectedImages.length;

  String get pageTitle => isEditing
      ? 'pasaj.market.create.edit_title'.tr
      : 'pasaj.market.create.add_title'.tr;

  String get draftActionLabel => isEditing
      ? 'pasaj.market.create.update_draft'.tr
      : 'pasaj.market.status.draft'.tr;

  String get publishActionLabel =>
      isEditing ? 'common.update'.tr : 'common.publish'.tr;

  String get selectedCategoryPathText =>
      selectedLeaf.value?.pathTextWithoutTop ?? '';
}
