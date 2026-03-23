part of 'add_social_media_bottom_sheet.dart';

extension AddSocialMediaBottomSheetActionsPart on AddSocialMediaBottomSheet {
  void _applyPresetSelection(String item) {
    controller.selected.value = item;
    controller.textController.text = socialMediaDisplayTitleForKey(item);
    controller.urlController.text = _defaultUrlForItem(item);
  }

  String _defaultUrlForItem(String item) {
    if (item == kSocialMediaWhatsApp) {
      return 'https://wa.me/+90';
    }
    if (item != kSocialMediaTurqApp) {
      return 'https://${normalizeLowercase(item)}.com/';
    }
    return '';
  }

  void _clearPresetSelection() {
    controller.selected.value = '';
    controller.imageFile.value = null;
  }

  Future<void> _saveLink() async {
    controller.isUploading.value = true;

    try {
      final docID = DateTime.now().millisecondsSinceEpoch.toString();
      var logoValue = '';
      if (controller.selected.value.isNotEmpty) {
        logoValue = socialMediaEmbeddedLogoAsset(
          controller.selected.value,
        );
      } else if (controller.imageFile.value != null) {
        logoValue = await controller.uploadFileImage(
          controller.imageFile.value!,
          docID,
        );
      }

      await controller.saveLink(
        SocialMediaModel(
          docID: docID,
          title: controller.textController.text.trim(),
          url: controller.urlController.text.trim(),
          sira: controller.list.length + 1,
          logo: logoValue,
        ),
      );

      await controller.getData();
      controller.resetFields();
      Get.back();
    } catch (e) {
      final msg = normalizeLowercase(
        e.toString(),
      ).contains('permission-denied')
          ? 'social_links.save_permission_error'.tr
          : 'social_links.save_failed'.tr;
      AppSnackbar('common.error'.tr, msg);
    } finally {
      controller.isUploading.value = false;
    }
  }
}
